#!/usr/bin/env bash
# Stitches the PNG frame folders written by tool/generate_screenshots.dart into
# animated WebP files in doc/.
#
#   flutter test tool/generate_screenshots.dart   # writes the frames
#   tool/pack_animations.sh                       # writes the .webp files
#
# Needs `img2webp` from libwebp (`brew install webp` / `apt install webp`).
# Animated WebP is used rather than GIF because it is far smaller at this frame
# count, and both GitHub and pub.dev render it.
set -euo pipefail

FRAMES=".dart_tool/screenshot_frames"
command -v img2webp >/dev/null || {
  echo "img2webp not found; install libwebp (brew install webp)" >&2
  exit 1
}

pack() {
  local name="$1" delay="$2" quality="$3"
  local dir="$FRAMES/$name"
  [ -d "$dir" ] || { echo "missing $dir — run the generator first" >&2; exit 1; }
  img2webp -loop 0 -d "$delay" -lossy -q "$quality" "$dir"/*.png \
    -o "doc/$name.webp" >/dev/null
  echo "doc/$name.webp: $(wc -c < "doc/$name.webp" | tr -d ' ') bytes, \
$(ls "$dir"/*.png | wc -l | tr -d ' ') frames @ ${delay}ms"
}

pack hero 60 52
pack orbs 55 80
