#!/usr/bin/env bash
# Contact sheet for review: two frames per second, 6 columns. Usage: bash contact.sh out/draft.mp4 [out/contact.png]
set -euo pipefail
in="${1:?video path}"; out="${2:-out/contact.png}"
command -v ffmpeg >/dev/null || { echo "[FAIL] ffmpeg not found" >&2; exit 1; }
mkdir -p "$(dirname "$out")"
ffmpeg -y -loglevel error -i "$in" -vf "fps=2,scale=270:-1,tile=6x5" -frames:v 1 "$out"
echo "[OK] $out"
