#!/usr/bin/env python3
"""Dependency-free sound design for a clip, written as 48 kHz 16-bit mono WAV. Deterministic: seeded noise, no randomness.
Usage: python3 sfx.py cues.json out/sfx.wav
cues.json:
  {"duration": 31,
   "bed":  {"kind": "serverroom", "gain": 0.1},            optional continuous ambience under the whole clip
   "hits": [{"t": 4.45, "kind": "click", "gain": 0.35}, ...]}
Natural kinds (for product clips with a voice-over):
  serverroom  bed: low fan rumble, broadband airflow, a faint blade-pass hum that breathes slowly, a little high air.
              RMS 0.1 at gain 1; use gain 0.02 to 0.03 so it is barely there, 30 dB or more under a peak-normalised voice. Louder reads as an annoying server room.
  click       a soft trackpad-style press and release, for selecting a chip, a step or a handle.
  air         a 0.9 s airflow swell, the room breathing once, for a scene change. Not a cartoon whoosh.
Synthetic kinds kept for beat-grid clips: tick (every beat if "ticks": true, with "bpm"), pop, thump, whoosh, chime, and a
"pad" list of frequencies. Mix under the voice afterwards and normalise the mix with ffmpeg loudnorm (two passes).
"""
import json, math, struct, sys, wave

SR = 48000

# ---- deterministic noise and filters (pure Python, buffers not per-sample callbacks) ----
def noise(n, seed):
    """Uniform white noise in [-1, 1] from a 32-bit LCG."""
    x = seed & 0xFFFFFFFF
    out = [0.0] * n
    for i in range(n):
        x = (1664525 * x + 1013904223) & 0xFFFFFFFF
        out[i] = x / 2147483648.0 - 1.0
    return out

def lowpass(buf, fc):
    a = 1.0 - math.exp(-2.0 * math.pi * fc / SR); y = 0.0; out = [0.0] * len(buf)
    for i, v in enumerate(buf):
        y += a * (v - y); out[i] = y
    return out

def highpass(buf, fc):
    lp = lowpass(buf, fc)
    return [v - l for v, l in zip(buf, lp)]

def bandpass(buf, fc, q):
    """Biquad band-pass (constant skirt gain)."""
    w0 = 2.0 * math.pi * fc / SR; alpha = math.sin(w0) / (2.0 * q)
    b0 = q * alpha; b1 = 0.0; b2 = -q * alpha
    a0 = 1.0 + alpha; a1 = -2.0 * math.cos(w0); a2 = 1.0 - alpha
    b0 /= a0; b1 /= a0; b2 /= a0; a1 /= a0; a2 /= a0
    x1 = x2 = y1 = y2 = 0.0; out = [0.0] * len(buf)
    for i, x0 in enumerate(buf):
        y0 = b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        out[i] = y0; x2, x1, y2, y1 = x1, x0, y1, y0
    return out

def rms(buf):
    return math.sqrt(sum(v * v for v in buf) / max(1, len(buf))) or 1e-9

def unit(buf):
    r = rms(buf); return [v / r for v in buf]

def peak_norm(buf, p=0.9):
    m = max(1e-9, max(abs(v) for v in buf)); return [v * p / m for v in buf]

def env(t, a, d):  # attack then exponential decay, t relative to onset
    if t < 0: return 0.0
    if t < a: return t / a
    return math.exp(-(t - a) / d)

# ---- beds ----
def bed_serverroom(dur, seed=7):
    n = int(dur * SR); white = noise(n, seed)
    rumble = unit(lowpass(lowpass(white, 160), 160))           # case and floor rumble
    body = unit(lowpass(white, 900))                           # broadband airflow
    hum = unit(bandpass(white, 170, 14))                       # fan blade-pass tone
    hum2 = unit(bandpass(white, 340, 18))                      # its second harmonic, lighter
    air = unit(bandpass(white, 2600, 0.8))                     # a little high air
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        breathe = 1.0 + 0.22 * math.sin(2 * math.pi * 0.13 * t) + 0.08 * math.sin(2 * math.pi * 0.31 * t + 1.0)
        out[i] = 1.0 * rumble[i] + 0.35 * body[i] + (0.12 * hum[i] + 0.05 * hum2[i]) * breathe + 0.04 * air[i]
    r = rms(out)
    return [v * 0.1 / r for v in out]

BEDS = {"serverroom": bed_serverroom}

# ---- one-shot buffers ----
def one_shot(kind, seed=11):
    if kind == "click":
        n = int(0.14 * SR); white = noise(n, seed)
        press = lowpass(white, 3600); rel = lowpass(white, 2800)
        out = [0.0] * n
        for i in range(n):
            t = i / SR
            s = press[i] * env(t, 0.0004, 0.0035) + 0.55 * rel[i] * env(t - 0.075, 0.0003, 0.0025)
            s += 0.25 * math.sin(2 * math.pi * 950 * t) * env(t, 0.001, 0.004)
            out[i] = s
        return peak_norm(out, 0.9)
    if kind == "air":
        n = int(0.9 * SR); white = noise(n, seed + 1)
        band = bandpass(white, 700, 0.6)
        out = [0.0] * n
        for i in range(n):
            t = i / SR
            w = 0.5 - 0.5 * math.cos(2 * math.pi * min(1.0, t / 0.9))      # one slow breath
            out[i] = band[i] * (w ** 1.6)
        return peak_norm(out, 0.9)
    # synthetic kinds, sampled from the old closed-form voices
    n = int(1.2 * SR)
    return [voice(kind, i / SR) for i in range(n)]

def voice(kind, t):
    if t < 0 or t > 1.2: return 0.0
    if kind == "tick":
        return 0.25 * env(t, 0.001, 0.015) * math.sin(2 * math.pi * 1800 * t)
    if kind == "pop":
        f = 420 * math.exp(-t * 18) + 140
        return 0.9 * env(t, 0.002, 0.06) * math.sin(2 * math.pi * f * t)
    if kind == "thump":
        f = 150 * math.exp(-t * 12) + 48
        return 1.0 * env(t, 0.003, 0.14) * math.sin(2 * math.pi * f * t)
    if kind == "whoosh":
        s = 0.0
        for i, base in enumerate((900, 1130, 1420, 1790)):
            s += math.sin(2 * math.pi * (base + 1600 * t) * t + i)
        return 0.28 * env(t, 0.12, 0.18) * s / 4
    if kind == "chime":
        s = sum(math.sin(2 * math.pi * f * t) * w for f, w in ((880, 1.0), (1320, 0.5), (1760, 0.3)))
        return 0.55 * env(t, 0.004, 0.45) * s / 1.8
    return 0.0

def main(cue_path, out_path):
    cues = json.load(open(cue_path))
    dur = float(cues["duration"]); bpm = float(cues.get("bpm", 120)); beat = 60.0 / bpm
    hits = list(cues.get("hits", []))
    if cues.get("ticks"):
        n = 0
        while n * beat < dur:
            hits.append({"t": n * beat, "kind": "tick", "gain": 1.0 if n % 4 == 0 else 0.6}); n += 1
    frames = int(dur * SR)
    mix = [0.0] * frames
    bed = cues.get("bed")
    if bed:
        if bed["kind"] not in BEDS: sys.exit(f"[FAIL] unknown bed kind {bed['kind']}")
        g = float(bed.get("gain", 1.0))
        for i, v in enumerate(BEDS[bed["kind"]](dur)): mix[i] += v * g
    buffers = {}
    for h in hits:
        if h["kind"] not in buffers: buffers[h["kind"]] = one_shot(h["kind"])
        start = int(h["t"] * SR); g = float(h.get("gain", 1.0))
        for j, v in enumerate(buffers[h["kind"]]):
            if start + j < frames: mix[start + j] += v * g
    pad = cues.get("pad", [])
    if pad:
        for i in range(frames):
            t = i / SR
            g = min(1.0, t / 1.0, (dur - t) / 1.0) * 0.12
            mix[i] += g * sum(math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2 * t + 0.5) for f in pad) / (1.3 * len(pad))
    with wave.open(out_path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767)) for s in mix))
    print(f"[OK] {out_path} {dur}s bed={bed['kind'] if bed else 'none'} {len(hits)} hits")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__); sys.exit(2)
    main(sys.argv[1], sys.argv[2])
