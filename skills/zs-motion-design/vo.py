#!/usr/bin/env python3
"""Voice-over for a clip: synthesizes timed lines and places them on one 48 kHz mono WAV.
Usage: python3 vo.py lines.json out/vo.wav
lines.json: {"duration": 15, "provider": "kokoro", "voice": "af_heart", "speed": 1.0,
             "lines": [{"t": 0.4, "text": "..."}, {"t": 2.6, "text": "...", "voice": "am_michael"}]}
Providers:
  kokoro      local, Apache 2.0 weights. pip install kokoro-onnx soundfile, plus a system espeak-ng (brew install espeak-ng);
              model files in ./models or KOKORO_MODEL / KOKORO_VOICES (kokoro-v1.0.onnx, voices-v1.0.bin from the kokoro-onnx releases).
  elevenlabs  key from ELEVENLABS_API_KEY or ~/.config/zsoftly/elevenlabs.key (mode 600); voice is a voice id
              (python3 vo.py --voices lists them); model eleven_multilingual_v2 unless ELEVENLABS_MODEL is set; MP3 decoded by ffmpeg.
A line that would overrun the next line's start is reported, not cut. Normalise afterwards with ffmpeg loudnorm.
Word timings: the ElevenLabs path uses the with-timestamps endpoint and writes <out>.words.json, one entry per spoken word
with absolute start and end seconds, so on-screen beats can be placed on the exact word. Takes are cached under
VO_CACHE (default out/vo-cache) keyed by provider, voice, model, seed, speed, settings and text, so retiming costs no credits.
Optional spec keys: "voice_settings" (merged over the ElevenLabs defaults), "cache": false to bypass the cache.
"""
import hashlib, base64
import json, os, sys, wave, struct, math

SR = 48000

def resample(samples, sr_in):
    if sr_in == SR: return list(samples)
    ratio = sr_in / SR; n = int(len(samples) / ratio); out = []
    for i in range(n):
        x = i * ratio; j = int(x); f = x - j
        a = samples[j]; b = samples[j + 1] if j + 1 < len(samples) else a
        out.append(a + (b - a) * f)
    return out

def espeak_config():
    """Prefer a system espeak-ng (brew install espeak-ng) because the wheel-bundled library looks for its data at a
    build-machine path. ESPEAK_LIB and ESPEAK_DATA override; ESPEAK_DATA is the directory that contains espeak-ng-data."""
    from kokoro_onnx.config import EspeakConfig
    lib = os.environ.get("ESPEAK_LIB"); data = os.environ.get("ESPEAK_DATA")
    if not lib:
        for cand, share in (("/opt/homebrew/lib/libespeak-ng.dylib", "/opt/homebrew/share"), ("/usr/local/lib/libespeak-ng.dylib", "/usr/local/share"), ("/usr/lib/x86_64-linux-gnu/libespeak-ng.so.1", "/usr/share"), ("/usr/lib/aarch64-linux-gnu/libespeak-ng.so.1", "/usr/share")):
            if os.path.exists(cand): lib, data = cand, data or share; break
    if not lib:
        try:
            import espeakng_loader
            lib = espeakng_loader.get_library_path(); data = data or os.path.dirname(espeakng_loader.get_data_path())
        except ImportError:
            sys.exit("[FAIL] no espeak-ng library found; brew install espeak-ng or set ESPEAK_LIB and ESPEAK_DATA")
    return EspeakConfig(lib_path=lib, data_path=data)

def synth_kokoro(text, voice, speed):
    from kokoro_onnx import Kokoro
    here = os.path.dirname(os.path.abspath(__file__))
    model = os.environ.get("KOKORO_MODEL") or next((p for p in (os.path.join(os.getcwd(), "models", "kokoro-v1.0.onnx"), os.path.join(here, "kokoro-v1.0.onnx")) if os.path.exists(p)), None)
    voices = os.environ.get("KOKORO_VOICES") or next((p for p in (os.path.join(os.getcwd(), "models", "voices-v1.0.bin"), os.path.join(here, "voices-v1.0.bin")) if os.path.exists(p)), None)
    if not model or not voices:
        sys.exit("[FAIL] Kokoro model files not found. Set KOKORO_MODEL and KOKORO_VOICES or place them in ./models")
    k = Kokoro(model, voices, espeak_config=espeak_config())
    samples, sr = k.create(text, voice=voice, speed=speed, lang="en-us")
    return resample([float(x) for x in samples], sr)

def eleven_key():
    """ELEVENLABS_API_KEY in the environment, else the first line of ~/.config/zsoftly/elevenlabs.key (mode 600)."""
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        path = os.path.expanduser(os.environ.get("ELEVENLABS_API_KEY_FILE", "~/.config/zsoftly/elevenlabs.key"))
        if os.path.exists(path):
            if os.stat(path).st_mode & 0o077:
                sys.exit(f"[FAIL] {path} is group or world readable; run chmod 600 {path}")
            with open(path) as f:
                key = f.read().strip().splitlines()[0].strip()
    if not key:
        sys.exit("[FAIL] no ElevenLabs key: export ELEVENLABS_API_KEY or write it to ~/.config/zsoftly/elevenlabs.key")
    return key

def eleven_voices():
    """Print the account's voices (name, id, category). Never prints the key."""
    import urllib.request
    req = urllib.request.Request("https://api.elevenlabs.io/v1/voices", headers={"xi-api-key": eleven_key()})
    data = json.loads(urllib.request.urlopen(req, timeout=60).read())
    for v in data.get("voices", []):
        print(f"{v.get('name','?'):30} {v.get('voice_id','')}  {v.get('category','')}")

def decode_with_ffmpeg(blob, suffix):
    """Decode any audio container to 48 kHz mono float samples via ffmpeg."""
    import subprocess, tempfile
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as f:
        f.write(blob); path = f.name
    try:
        out = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "s16le", "-ac", "1", "-ar", str(SR), "-"], capture_output=True, check=True).stdout
    except FileNotFoundError:
        sys.exit("[FAIL] ffmpeg not found on PATH")
    except subprocess.CalledProcessError as e:
        sys.exit(f"[FAIL] ffmpeg decode failed\n{e.stderr.decode(errors='replace')[-1500:]}")
    finally:
        os.unlink(path)
    return [struct.unpack_from("<h", out, i)[0] / 32768.0 for i in range(0, len(out) - 1, 2)]

ELEVEN_DEFAULT_SETTINGS = {"stability": 0.5, "similarity_boost": 0.8, "style": 0.0, "use_speaker_boost": True}

def words_from_alignment(al):
    """Group ElevenLabs character alignment into words with start and end seconds (relative to the take)."""
    chars, starts, ends = al.get("characters", []), al.get("character_start_times_seconds", []), al.get("character_end_times_seconds", [])
    words, cur, s0, e0 = [], "", None, None
    for ch, s, e in zip(chars, starts, ends):
        if ch.isspace():
            if cur: words.append({"w": cur, "s": s0, "e": e0}); cur, s0 = "", None
            continue
        if s0 is None: s0 = s
        cur += ch; e0 = e
    if cur: words.append({"w": cur, "s": s0, "e": e0})
    return words

def synth_elevenlabs(text, voice, speed, settings=None):
    import urllib.request
    model = os.environ.get("ELEVENLABS_MODEL", "eleven_multilingual_v2")
    seed = int(os.environ.get("ELEVENLABS_SEED", "7"))  # fixed seed so a re-render gives the same take
    vs = dict(ELEVEN_DEFAULT_SETTINGS); vs.update(settings or {}); vs["speed"] = speed
    body = json.dumps({"text": text, "model_id": model, "seed": seed, "voice_settings": vs}).encode()
    req = urllib.request.Request(f"https://api.elevenlabs.io/v1/text-to-speech/{voice}/with-timestamps?output_format=mp3_44100_128", data=body,
                                 headers={"xi-api-key": eleven_key(), "Content-Type": "application/json"})
    try:
        data = json.loads(urllib.request.urlopen(req, timeout=120).read())
    except urllib.error.HTTPError as e:
        sys.exit(f"[FAIL] ElevenLabs HTTP {e.code}: {e.read()[:300].decode(errors='replace')}")
    samples = decode_with_ffmpeg(base64.b64decode(data["audio_base64"]), ".mp3")
    return samples, words_from_alignment(data.get("alignment") or {})

def cached(spec, prov, text, voice, speed, settings, synth):
    """Return (samples, words), from VO_CACHE when the same take was made before."""
    if spec.get("cache", True) is False:
        r = synth(text, voice, speed, settings) if prov == "elevenlabs" else (synth(text, voice, speed), None)
        return r
    cache_dir = os.environ.get("VO_CACHE", os.path.join("out", "vo-cache")); os.makedirs(cache_dir, exist_ok=True)
    key = hashlib.sha1(json.dumps([prov, voice, os.environ.get("ELEVENLABS_MODEL", ""), os.environ.get("ELEVENLABS_SEED", "7"), speed, settings or {}, text], sort_keys=True).encode()).hexdigest()
    wav_path, meta_path = os.path.join(cache_dir, key + ".wav"), os.path.join(cache_dir, key + ".json")
    if os.path.exists(wav_path) and os.path.exists(meta_path):
        with wave.open(wav_path, "rb") as w:
            raw = w.readframes(w.getnframes())
        samples = [struct.unpack_from("<h", raw, i)[0] / 32768.0 for i in range(0, len(raw) - 1, 2)]
        with open(meta_path) as f:
            return samples, json.load(f).get("words")
    if prov == "elevenlabs":
        samples, words = synth(text, voice, speed, settings)
    else:
        samples, words = synth(text, voice, speed), None
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in samples))
    with open(meta_path, "w") as f:
        json.dump({"text": text, "voice": voice, "speed": speed, "words": words}, f)
    return samples, words

def main(spec_path, out_path):
    with open(spec_path) as f:
        spec = json.load(f)
    dur = float(spec["duration"]); prov = spec.get("provider", "kokoro")
    synth = {"kokoro": synth_kokoro, "elevenlabs": synth_elevenlabs}[prov]
    timeline = [0.0] * int(dur * SR)
    lines = sorted(spec["lines"], key=lambda l: l["t"])
    all_words = []
    for i, line in enumerate(lines):
        voice = line.get("voice", spec.get("voice", "af_heart")); speed = float(line.get("speed", spec.get("speed", 1.0)))
        settings = dict(spec.get("voice_settings", {})); settings.update(line.get("voice_settings", {}))
        s, words = cached(spec, prov, line["text"], voice, speed, settings, synth)
        start = int(line["t"] * SR); end_t = line["t"] + len(s) / SR
        nxt = lines[i + 1]["t"] if i + 1 < len(lines) else dur
        flag = "  [WARN] overruns next line" if end_t > nxt + 0.05 else ""
        print(f"[OK] line {i + 1} at {line['t']:.2f}s, {len(s) / SR:.2f}s, ends {end_t:.2f}s{flag}")
        for w in words or []:
            all_words.append({"line": i + 1, "w": w["w"], "s": round(line["t"] + w["s"], 3), "e": round(line["t"] + w["e"], 3)})
        for j, v in enumerate(s):
            if start + j < len(timeline): timeline[start + j] += v
    if all_words:
        wp = os.path.splitext(out_path)[0] + ".words.json"
        with open(wp, "w") as f:
            json.dump(all_words, f, indent=0)
        print(f"[OK] word timings in {wp}")
    peak = max(1e-9, max(abs(v) for v in timeline))
    gain = min(1.0, 0.95 / peak)
    with wave.open(out_path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * gain)) * 32767)) for v in timeline))
    print(f"[OK] {out_path} {dur}s, {len(lines)} lines, provider {prov}")

if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == "--voices":
        eleven_voices(); sys.exit(0)
    if len(sys.argv) != 3: print(__doc__); sys.exit(2)
    main(sys.argv[1], sys.argv[2])
