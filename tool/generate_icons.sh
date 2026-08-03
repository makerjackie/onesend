#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/assets/brand/onesend-transfer-mark.svg"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/onesend-icons.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

if command -v rsvg-convert >/dev/null 2>&1; then
  render_svg() {
    rsvg-convert -w "$1" -h "$1" "$SOURCE" -o "$2"
  }
elif command -v magick >/dev/null 2>&1; then
  render_svg() {
    magick -background none "$SOURCE" -resize "${1}x${1}!" "PNG24:$2"
  }
else
  echo "需要 rsvg-convert 或 ImageMagick (magick) 才能生成图标。" >&2
  exit 1
fi

resize_png() {
  local size="$1"
  local output="$2"
  magick "$TMP_DIR/master.png" -resize "${size}x${size}!" -strip "PNG24:$output"
}

mkdir -p "$ROOT_DIR/tool"
render_svg 1024 "$TMP_DIR/master.png"

# Shared brand/Linux source and website master.
resize_png 1024 "$ROOT_DIR/assets/brand/onesend-icon-1024.png"
resize_png 1024 "$ROOT_DIR/website/public/icon.png"

# Android launcher sizes (mdpi through xxxhdpi).
resize_png 48 "$ROOT_DIR/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"
resize_png 72 "$ROOT_DIR/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"
resize_png 96 "$ROOT_DIR/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
resize_png 144 "$ROOT_DIR/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
resize_png 192 "$ROOT_DIR/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

# iOS AppIcon.appiconset. Keep existing filenames and Contents.json intact.
resize_png 1024 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
resize_png 20 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"
resize_png 40 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"
resize_png 60 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"
resize_png 29 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"
resize_png 58 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"
resize_png 87 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"
resize_png 40 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"
resize_png 80 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"
resize_png 120 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"
resize_png 120 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"
resize_png 180 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"
resize_png 76 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"
resize_png 152 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"
resize_png 167 "$ROOT_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"

# macOS AppIcon.appiconset. Keep Contents.json aliases intact.
resize_png 16 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png"
resize_png 32 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png"
resize_png 64 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png"
resize_png 128 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png"
resize_png 256 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png"
resize_png 512 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"
resize_png 1024 "$ROOT_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"

# Windows ICO keeps the existing resource filename and standard icon sizes.
magick "$TMP_DIR/master.png" \
  -define icon:auto-resize=16,24,32,48,64,96,128,256 \
  "$ROOT_DIR/windows/runner/resources/app_icon.ico"

echo "Generated OneSend icons from $SOURCE"
