#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
demo_dir="$repo_root/assets/demo"
output_path="$demo_dir/onesend-optical-test.mp4"
report_path="$demo_dir/ffprobe.txt"
if [[ $# -gt 0 ]]; then
  output_path="$1"
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  printf 'ffmpeg is required.\n' >&2
  exit 1
fi
if ! command -v ffprobe >/dev/null 2>&1; then
  printf 'ffprobe is required.\n' >&2
  exit 1
fi

mkdir -p "$(dirname "$output_path")" "$demo_dir"

# Geometric primitives only: no external footage, image, or font is needed.
video_filter='color=c=black:s=320x180:r=12:d=10,drawbox=x=8:y=8:w=304:h=164:color=white:t=4,drawbox=x=28:y=46:w=72:h=88:color=white:t=fill,drawbox=x=220:y=46:w=72:h=88:color=white:t=fill,drawbox=x=mod(t*108\,208)+48:y=mod(t*60\,64)+58:w=24:h=24:color=black:t=fill,drawbox=x=mod(t*132\,208)+48:y=72:w=24:h=36:color=white:t=fill,drawbox=x=142:y=52:w=36:h=76:color=white:t=fill,drawbox=x=156:y=38:w=8:h=104:color=white:t=fill'

# A short, low-rate oscillator tone is synthesized instead of using a song.
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "$video_filter" \
  -f lavfi -i "sine=frequency=330:beep_factor=2:sample_rate=8000:duration=10" \
  -map 0:v:0 -map 1:a:0 -t 10 \
  -r 12 \
  -c:v libx264 -preset veryslow -tune animation \
  -profile:v baseline -level 1.2 -pix_fmt yuv420p \
  -b:v 110k -maxrate 110k -bufsize 220k \
  -g 24 -keyint_min 24 -sc_threshold 0 \
  -c:a aac -profile:a aac_low -b:a 16k -ac 1 -ar 8000 \
  -af 'volume=0.12,afade=t=in:st=0:d=0.08,afade=t=out:st=9.75:d=0.25' \
  -movflags +faststart \
  -metadata title='OneSend Optical Test' \
  -metadata comment='Original geometric test pattern and synthesized tone; MIT-safe project asset.' \
  "$output_path"

duration="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$output_path")"
size_bytes="$(ffprobe -v error -show_entries format=size -of default=noprint_wrappers=1:nokey=1 "$output_path")"
video_codec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$output_path")"
video_dimensions="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$output_path")"
video_rate="$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$output_path")"
audio_codec="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$output_path")"
audio_rate="$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$output_path")"
audio_channels="$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$output_path")"

if ! awk -v value="$duration" 'BEGIN { exit !(value >= 8 && value <= 12) }'; then
  printf 'Demo video duration is outside 8–12 seconds: %s\n' "$duration" >&2
  exit 1
fi
if (( size_bytes >= 500000 )); then
  printf 'Demo video is at least 500 KB: %s bytes\n' "$size_bytes" >&2
  exit 1
fi
if [[ "$video_codec" != h264 || "$video_dimensions" != 320x180 ]]; then
  printf 'Unexpected video stream: codec=%s dimensions=%s\n' \
    "$video_codec" "$video_dimensions" >&2
  exit 1
fi
if [[ "$audio_codec" != aac ]]; then
  printf 'Unexpected audio codec: %s\n' "$audio_codec" >&2
  exit 1
fi

{
  printf 'file=%s\n' "$(basename "$output_path")"
  printf 'size_bytes=%s\n' "$size_bytes"
  printf 'duration_seconds=%s\n' "$duration"
  printf 'video_codec=%s\n' "$video_codec"
  printf 'video_dimensions=%s\n' "$video_dimensions"
  printf 'video_frame_rate=%s\n' "$video_rate"
  printf 'audio_codec=%s\n' "$audio_codec"
  printf 'audio_sample_rate=%s\n' "$audio_rate"
  printf 'audio_channels=%s\n' "$audio_channels"
} > "$report_path"

printf 'Generated %s\n' "$output_path"
printf 'Recorded ffprobe details in %s\n' "$report_path"
cat "$report_path"
