#!/usr/bin/env python3
"""Mix a voice-over and a sound-design track under it, normalise in two passes, and mux onto the silent render.
Usage: python3 mix.py out/vo.wav out/sfx.wav out/final-silent.mp4 out/final.mp4 [--lufs -16] [--sfx-gain 1.0]
Steps: amix (no auto-normalise) -> loudnorm pass 1 (measure) -> loudnorm pass 2 (linear) -> aac 192k muxed with -shortest.
Prints the measured integrated loudness of the voice, the sound design and the final mix so the bed level can be checked.
The filter string is built here, not in the shell, because zsh word-splits it.
"""
import json, subprocess, sys

def run(args, capture=False):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"[FAIL] {' '.join(args[:3])}...\n{r.stderr[-1500:]}")
    return r.stderr if capture else None

def measure(path):
    err = run(["ffmpeg", "-hide_banner", "-nostats", "-i", path, "-af", "loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json", "-f", "null", "-"], capture=True)
    return json.loads(err[err.rindex("{"):err.rindex("}") + 1])

def flag_value(argv, flag, default):
    if flag not in argv: return default
    i = argv.index(flag)
    try: return float(argv[i + 1])
    except (IndexError, ValueError): sys.exit(f"[FAIL] {flag} needs a numeric value\n{__doc__.splitlines()[1]}")

def main(argv):
    if len(argv) < 4: print(__doc__); sys.exit(2)
    vo, sfx, video, out = argv[:4]
    lufs = -16.0; sfx_gain = 1.0
    lufs = flag_value(argv, "--lufs", lufs)
    sfx_gain = flag_value(argv, "--sfx-gain", sfx_gain)
    mix = out.rsplit(".", 1)[0] + ".mix.wav"
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", vo, "-i", sfx, "-filter_complex",
         f"[1:a]volume={sfx_gain}[s];[0:a][s]amix=inputs=2:duration=first:normalize=0[m]", "-map", "[m]", "-ar", "48000", mix])
    m = measure(mix)
    pass2 = (f"loudnorm=I={lufs}:TP=-1.5:LRA=11:measured_I={m['input_i']}:measured_TP={m['input_tp']}:measured_LRA={m['input_lra']}"
             f":measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true:print_format=summary")
    norm = out.rsplit(".", 1)[0] + ".norm.wav"
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", mix, "-af", pass2, "-ar", "48000", norm])
    run(["ffmpeg", "-y", "-loglevel", "error", "-i", video, "-i", norm, "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", out])
    for label, path in (("voice", vo), ("sound design", sfx), ("final mix", norm)):
        r = measure(path)
        print(f"[OK] {label:13} integrated {float(r['input_i']):6.1f} LUFS, true peak {float(r['input_tp']):5.1f} dBTP")
    print(f"[OK] {out}")

if __name__ == "__main__":
    main(sys.argv[1:])
