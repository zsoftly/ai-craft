---
name: zs-motion-design
description: Build a motion graphics clip as a deterministic program rendered by headless Chrome, not as a hand-edited video. Use when a post, launch, or product moment needs a 10 to 30 second animated piece in 9:16, 1:1 or 16:9, and the result must be reproducible from the repository.
disable-model-invocation: true
---

# Motion design studio

A film here is a pure function of time. The model writes `window.seek(t)` that paints frame `t` on a canvas, Playwright screenshots every frame, and ffmpeg encodes them. Nothing is animated by the browser clock, so frame 300 renders the same twice and any second can be re-rendered alone.

Run this skill from the folder that will hold the clip. It installs nothing globally.

## Setup, once per machine

Node 22 or newer, ffmpeg, and a Chromium for Playwright:

```bash
npm init -y && npm i -D playwright && npx playwright install chromium
```

Copy `render.mjs`, `springs.mjs`, `contact.sh`, `vo.py`, `sfx.py` and `mix.py` from this skill's directory into the clip folder. Copy the render contract below into the folder's `CLAUDE.md` so every session in that folder inherits it.

## Render contract

Put this in the clip folder's `CLAUDE.md` before writing any prompt:

- Every film is a pure function of time. `window.seek(t)` paints frame `t`. No CSS transitions, no `setTimeout`, no `requestAnimationFrame`, no `Math.random` in render mode. Seeded noise only, `mulberry32`.
- One `index.html`, one Canvas 2D context, one `seek(t)`. Render with `node render.mjs`, which encodes H.264 `yuv420p` at CRF 16.
- Defaults: 1080 by 1920 at 60 fps for 15 seconds, 4 subframes per frame averaged with `tmix` for motion blur. Set `--w 1920 --h 1080` for 16:9, `--w 1080 --h 1080` for square.
- Look rules. Banned: a centred title on a gradient, everything fading in, labels in the corners, frame borders, glow on UI chrome, generic particle bursts, bouncy easing. One display face, one UI face, one accent colour. Something new on screen every 2 to 4 seconds. Tiny overshoot on UI, none on type.
- Motion: closed-form damped springs from `springs.mjs`, default `k=170, d=26`. One spring per change through `track()`, never a restarted spring. Loops wrap time with `loopT` and the last frame equals the first.
- Brand assets are cropped and animated, never redrawn from imagination.
- Review loop: render a contact sheet of one frame per beat, score it, fix the three worst problems, repeat until every score is 8 or higher, then run the full render.

## Brief before code

Ask for the inputs, then show the state list on the beat grid before writing a line of code. A brief carries:

1. Logline, one sentence. What the viewer should believe at the end.
2. Format, duration, fps, and where it will be posted.
3. References. One frame or clip of a look you want. Extract a frame every 0.5 s with `ffmpeg -i ref.mp4 -vf fps=2 ref/%03d.png` and write `style_guide.md`: hex palette, type, shot lengths, transitions, camera moves, grain, how text enters and leaves. Take the grammar of the reference, never its content, logos or characters.
4. Beat sheet at 120 BPM, 8 bars for 15 s. A hook in the first 2 seconds, a visual payoff every 3 to 5 seconds, something on every beat. Text enters after a morph starts and leaves before the next one.
5. Brand assets by path, with the rule that real UI is cropped, not redrawn.

For a product moment, prefer the one-shape UI morph: one container changes size, radius and fill between states, a cursor drives each change, warm neutral canvas, one accent.

## Build

1. Write `index.html` with `seek(t)` and the state list as data at the top of the file, one object per beat.
2. Run `node render.mjs --out out/draft.mp4 --fps 30 --sub 1` for a fast draft, then `bash contact.sh out/draft.mp4` and read `out/contact.png`.
3. Score the sheet 1 to 10 on: hook in the first 2 s, readability at phone size, motion quality, variety, composition, brand accuracy. Log the scores and the three biggest problems with timestamps in `docs/review_log.md`. Fix them. At least three rounds per shot.
4. Phone test: `ffmpeg -i out/draft.mp4 -vf scale=360:-1 out/phone.mp4` and watch it small. Loop test: `ffmpeg -stream_loop 1 -i out/draft.mp4 out/loop_check.mp4` and look for a seam.
5. Determinism: `node render.mjs --frame 300 --out out/a.png` twice and compare hashes. A mismatch means a clock or random call slipped in.
6. Full render: `node render.mjs --out out/final.mp4`, then a poster with `ffmpeg -ss 2 -i out/final.mp4 -frames:v 1 out/poster.png`.

Hunt list on every review: text overlapping during a swap, a slide where a spring was wanted, a corner label, a centred-on-gradient shot, blurry scaled text, a dead beat, a stutter at the loop seam.

## Sound

Prefer a voice-over to effects. A human-sounding voice carries the message; cartoon pops, whooshes and chimes do not, and an owner will reject them. `vo.py` in this skill takes `lines.json`, one line per visual beat with its start time, synthesizes each line and places it on a 48 kHz timeline, then reports any line that overruns the next. `sfx.py` renders the sound design from `cues.json`. `mix.py` puts the two together under the voice, normalises in two passes and muxes onto the silent render:

```bash
python3 vo.py lines.json out/vo.wav          # writes out/vo.words.json too (ElevenLabs)
python3 sfx.py cues.json out/sfx.wav
python3 mix.py out/vo.wav out/sfx.wav out/final-silent.mp4 out/final.mp4 --lufs -16
```

Providers, picked in `lines.json`:

- `kokoro`: local, free, Apache 2.0 weights, no account. `brew install espeak-ng`, then `pip install kokoro-onnx soundfile` in a venv, and download `kokoro-v1.0.onnx` and `voices-v1.0.bin` from the kokoro-onnx releases into `./models`. English only, about 50 preset voices; `af_heart` and `am_michael` are safe first picks. Render two voices and let the owner choose.
- `elevenlabs`: the current quality leader in every comparison read on 2026-10-11, paid. The key comes from `ELEVENLABS_API_KEY` or the file `~/.config/zsoftly/elevenlabs.key` (mode 600), never from chat or a command line. `python3 vo.py --voices` lists the account's voices with their ids; a cloned voice of the owner works the same as a stock one. The voice field is the voice id. Output is requested as MP3, which every plan tier allows, and decoded by ffmpeg. The with-timestamps endpoint is used, so `out/vo.words.json` holds the start and end of every spoken word: place the on-screen beats on those times, not on guesses. Takes are cached under `out/vo-cache` by text, voice, speed, seed and settings, so retiming a line costs no credits; only new wording does.

Write the lines for the ear: one sentence per line so the gaps between sentences are yours to set, numbers spelled the way they are said, 2.5 words per second at most, and the first line inside the first second. Keep `stability` around 0.6 for a calm explaining tone. Target -16 LUFS for speech. Feeds autoplay muted, so the picture must carry the message without the sound.

Sound design under a product voice-over is the room the product lives in, not a cartoon. `cues.json` takes a `bed` and `hits`:

- `serverroom` bed: fan rumble, airflow, a faint blade-pass hum that breathes, a little high air. Gain 0.02 to 0.03 keeps it barely there, 30 dB or more under the voice (0.12 was rejected by an owner as an annoying server room); `mix.py` prints the voice, design and mix loudness so this can be checked, and a 0.5 s window with no speech should measure 15 dB or more below the mix.
- `click` on a chip, step or handle; `air` (a 0.9 s breath of the room) on a scene change. Both sit on the exact word they answer to.
- The synthetic kinds (`tick`, `pop`, `whoosh`, `chime`, `thump`, `pad`) stay for beat-grid clips with no voice. Never add music the brand did not license. Never invent noises for silent parts (RAM, SSD); use the room instead.

## Deliverables

`out/final.mp4`, `out/loop_check.mp4`, `out/poster.png`, `out/contact.png`, `docs/review_log.md`, `lines.json`, and the source `index.html` so anyone can re-render. Export every format from the one timeline by changing `--w` and `--h`, not by editing the film.

## Effort

Set the session to high effort for a new film and medium for a fix. A chat window cannot render or check its own output, so this runs in Claude Code with a shell.

## Sources

Workflow adapted from the X article "How to build motion design studio with Opus 5.5" by Movez, mirrored at movez.substack.com, read 2026-10-10. The render contract, spring defaults and the critique loop follow that guide. Beat timings and the banned-look list are its rules restated.
