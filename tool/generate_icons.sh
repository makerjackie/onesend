#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_RELATIVE="assets/brand/onesend-file-scan-mark.png"
SOURCE="$ROOT_DIR/$SOURCE_RELATIVE"
MANIFEST_RELATIVE="assets/brand/generated-assets.sha256"
MANIFEST="$ROOT_DIR/$MANIFEST_RELATIVE"
APP_ICON_BACKGROUND="#f5f6f0"
MODE="generate"

usage() {
  cat <<'EOF'
Usage: tool/generate_icons.sh [--check]

Without arguments, render all checked-in OneSend icon assets from the canonical
transparent file-scan PNG on a warm off-white app-icon plate and refresh the
committed SHA-256 manifest. With --check, verify the committed files against
that manifest without rendering any images.
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

render_icon() {
  local size="$1"
  local output="$2"

  mkdir -p "$(dirname "$output")"
  "$MAGICK_BIN" "$SOURCE" -background "$APP_ICON_BACKGROUND" \
    -resize "${size}x${size}!" -alpha remove -alpha off \
    -strip "PNG24:$output"
}

write_favicon_reference() {
  local output="$1"

  mkdir -p "$(dirname "$output")"
  printf '%s\n' \
    '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">' \
    '  <title>OneSend file scan mark</title>' \
    '  <image href="/icon.png" width="1024" height="1024" preserveAspectRatio="xMidYMid meet" />' \
    '</svg>' > "$output"
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
    render_icon "$size" "$output_root/$relative"
  done <<< "$targets"
}

build_assets() {
  local output_root="$1"
  local master="$TMP_DIR/master.png"
  local relative
  local size

  render_icon 1024 "$master"

  # Keep the 1024px root, website, iOS, macOS, and Linux assets byte-identical.
  for relative in \
    assets/brand/onesend-icon-1024.png \
    website/public/icon.png \
    ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png \
    macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png \
    linux/runner/resources/app_icon.png; do
    copy_asset "$master" "$output_root/$relative"
  done

  # Keep the SVG favicon as a deterministic reference to the PNG asset rather
  # than drawing a second, potentially divergent mark.
  write_favicon_reference "$output_root/website/public/favicon.svg"

  render_target_list "$output_root" "$ANDROID_TARGETS"
  render_target_list "$output_root" "$IOS_TARGETS"
  render_target_list "$output_root" "$MACOS_TARGETS"
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

EXPECTED_FILES=("$SOURCE_RELATIVE" "${CHECK_FILES[@]}")

HASH_COMMAND=()
if SHASUM_BIN="$(command -v shasum 2>/dev/null)"; then
  HASH_COMMAND=("$SHASUM_BIN" -a 256)
elif SHA256SUM_BIN="$(command -v sha256sum 2>/dev/null)"; then
  HASH_COMMAND=("$SHA256SUM_BIN")
else
  echo "A SHA-256 tool is required (preferably shasum, or sha256sum)." >&2
  exit 1
fi

sha256_file() {
  local file="$1"
  local digest
  local output

  if ! output="$("${HASH_COMMAND[@]}" "$file")"; then
    return 1
  fi
  digest="${output%% *}"
  if [[ ${#digest} -ne 64 || "$digest" == *[!0-9a-f]* ]]; then
    echo "Unexpected SHA-256 output for: $file" >&2
    return 1
  fi
  printf '%s\n' "$digest"
}

is_expected_file() {
  local candidate="$1"
  local expected

  for expected in "${EXPECTED_FILES[@]}"; do
    if [[ "$candidate" == "$expected" ]]; then
      return 0
    fi
  done
  return 1
}

write_manifest() {
  local digest
  local file
  local relative
  local temporary_manifest="$TMP_DIR/generated-assets.sha256"

  : > "$temporary_manifest"
  for relative in "${EXPECTED_FILES[@]}"; do
    file="$ROOT_DIR/$relative"
    if [[ ! -f "$file" ]]; then
      echo "Cannot write manifest; expected file is missing: $relative" >&2
      return 1
    fi
    if ! digest="$(sha256_file "$file")"; then
      echo "Cannot hash brand asset: $relative" >&2
      return 1
    fi
    printf '%s  %s\n' "$digest" "$relative" >> "$temporary_manifest"
  done

  cp "$temporary_manifest" "$MANIFEST"
}

check_manifest() {
  local actual_hash
  local expected
  local expected_hash
  local file
  local line
  local line_number=0
  local relative
  local seen_files=$'\n'
  local failed=0

  for expected in "${EXPECTED_FILES[@]}"; do
    if [[ ! -f "$ROOT_DIR/$expected" ]]; then
      echo "Missing expected brand asset: $expected" >&2
      failed=1
    fi
  done

  if [[ ! -f "$MANIFEST" ]]; then
    echo "Missing brand asset manifest: $MANIFEST_RELATIVE" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_number += 1))
    expected_hash="${line%%  *}"
    relative="${line#*  }"

    if [[ "$expected_hash" == "$line" || "$relative" == "$line" || \
      "$line" != "$expected_hash  $relative" || ${#expected_hash} -ne 64 || \
      "$expected_hash" == *[!0-9a-f]* || -z "$relative" ]]; then
      echo "Malformed manifest entry at $MANIFEST_RELATIVE:$line_number" >&2
      failed=1
      continue
    fi

    if ! is_expected_file "$relative"; then
      echo "Unexpected path in brand asset manifest: $relative" >&2
      failed=1
      continue
    fi

    if [[ "$seen_files" == *$'\n'"$relative"$'\n'* ]]; then
      echo "Duplicate path in brand asset manifest: $relative" >&2
      failed=1
      continue
    fi
    seen_files+="$relative"$'\n'

    file="$ROOT_DIR/$relative"
    if [[ ! -f "$file" ]]; then
      continue
    fi
    if ! actual_hash="$(sha256_file "$file")"; then
      echo "Failed to hash brand asset: $relative" >&2
      failed=1
      continue
    fi
    if [[ "$actual_hash" != "$expected_hash" ]]; then
      echo "Brand asset hash drift: $relative" >&2
      echo "  manifest: $expected_hash" >&2
      echo "  current:  $actual_hash" >&2
      failed=1
    fi
  done < "$MANIFEST"

  for expected in "${EXPECTED_FILES[@]}"; do
    if [[ "$seen_files" != *$'\n'"$expected"$'\n'* ]]; then
      echo "Missing path from brand asset manifest: $expected" >&2
      failed=1
    fi
  done

  return "$failed"
}

if [[ "$MODE" == "check" ]]; then
  check_manifest
  echo "Brand asset manifest is complete and all hashes match."
else
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

  build_assets "$ROOT_DIR"
  write_manifest
  echo "Generated OneSend icons from $SOURCE and updated $MANIFEST_RELATIVE"
fi
