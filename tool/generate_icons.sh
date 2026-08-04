#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT_DIR/assets/brand/onesend-transfer-mark.svg"
MODE="generate"

usage() {
  cat <<'EOF'
Usage: tool/generate_icons.sh [--check]

Without arguments, render all checked-in OneSend icon assets from the canonical
transfer-mark SVG. With --check, render into a temporary directory and compare
the result with the checked-in assets without changing the repository.
EOF
}

case "${1:-}" in
  "") ;;
  --check)
    MODE="check"
    shift
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if (( $# != 0 )); then
  usage >&2
  exit 2
fi

if [[ ! -f "$SOURCE" ]]; then
  echo "Missing canonical brand source: $SOURCE" >&2
  exit 1
fi

MAGICK_BIN="$(command -v magick 2>/dev/null || true)"
if [[ -z "$MAGICK_BIN" || ! -x "$MAGICK_BIN" ]]; then
  echo "ImageMagick's 'magick' command is required to generate brand assets." >&2
  exit 1
fi
if ! "$MAGICK_BIN" -version >/dev/null 2>&1; then
  echo "ImageMagick's 'magick' command is not executable: $MAGICK_BIN" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/onesend-icons.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

render_svg() {
  local size="$1"
  local output="$2"

  mkdir -p "$(dirname "$output")"
  "$MAGICK_BIN" -background none "$SOURCE" -resize "${size}x${size}!" \
    -strip "PNG24:$output"
}

copy_asset() {
  local source="$1"
  local output="$2"

  mkdir -p "$(dirname "$output")"
  cp "$source" "$output"
}

render_target_list() {
  local output_root="$1"
  local targets="$2"
  local size
  local relative

  while IFS='|' read -r size relative; do
    [[ -n "$relative" ]] || continue
    render_svg "$size" "$output_root/$relative"
  done <<< "$targets"
}

build_assets() {
  local output_root="$1"
  local master="$TMP_DIR/master.png"
  local relative
  local size

  render_svg 1024 "$master"

  # Keep the 1024px root, website, iOS, and macOS assets byte-identical.
  for relative in \
    assets/brand/onesend-icon-1024.png \
    website/public/icon.png \
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png \
    macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png; do
    copy_asset "$master" "$output_root/$relative"
  done

  # The browser favicon is the canonical SVG itself, without a second drawing.
  copy_asset "$SOURCE" "$output_root/website/public/favicon.svg"

  render_target_list "$output_root" "$ANDROID_TARGETS"
  render_target_list "$output_root" "$IOS_TARGETS"
  render_target_list "$output_root" "$MACOS_TARGETS"
  render_svg 1024 "$output_root/linux/runner/resources/app_icon.png"

  # Windows ICO contains standard shell sizes as PNG-compressed frames.
  mkdir -p "$output_root/windows/runner/resources"
  "$MAGICK_BIN" "$master" \
    -define icon:auto-resize=16,24,32,48,64,96,128,256 \
    "$output_root/windows/runner/resources/app_icon.ico"
}

ANDROID_TARGETS=$'48|android/app/src/main/res/mipmap-mdpi/ic_launcher.png\n72|android/app/src/main/res/mipmap-hdpi/ic_launcher.png\n96|android/app/src/main/res/mipmap-xhdpi/ic_launcher.png\n144|android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png\n192|android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'

IOS_TARGETS=$'20|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png\n40|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png\n60|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png\n29|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png\n58|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png\n87|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png\n40|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png\n80|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png\n120|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png\n120|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png\n180|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png\n76|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png\n152|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png\n167|ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png'

MACOS_TARGETS=$'16|macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png\n32|macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png\n64|macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png\n128|macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png\n256|macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png\n512|macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png'

CHECK_FILES=(
  website/public/favicon.svg
  assets/brand/onesend-icon-1024.png
  website/public/icon.png
  android/app/src/main/res/mipmap-mdpi/ic_launcher.png
  android/app/src/main/res/mipmap-hdpi/ic_launcher.png
  android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
  android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
  android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png
  linux/runner/resources/app_icon.png
  windows/runner/resources/app_icon.ico
)

check_outputs() {
  local expected_root="$1"
  local actual_root="$2"
  local relative
  local failed=0

  for relative in "${CHECK_FILES[@]}"; do
    if [[ ! -f "$actual_root/$relative" ]]; then
      echo "Missing brand asset: $relative" >&2
      failed=1
    elif ! cmp -s "$expected_root/$relative" "$actual_root/$relative"; then
      echo "Brand asset drift: $relative" >&2
      failed=1
    fi
  done

  return "$failed"
}

if [[ "$MODE" == "check" ]]; then
  EXPECTED_ROOT="$TMP_DIR/expected"
  build_assets "$EXPECTED_ROOT"
  check_outputs "$EXPECTED_ROOT" "$ROOT_DIR"
  echo "Brand assets are up to date and match $SOURCE"
else
  build_assets "$ROOT_DIR"
  echo "Generated OneSend icons from $SOURCE"
fi
