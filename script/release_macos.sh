#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

version_record="$(awk '/^version: / {print $2; exit}' pubspec.yaml)"
version="${version_record%%+*}"
build_number="${version_record##*+}"
output_dir="${ONESEND_RELEASE_OUTPUT_DIR:-$repo_root/dist/v$version}"
app_path="$repo_root/build/macos/Build/Products/Release/OneSend.app"
zip_path="$output_dir/onesend-macos-universal.zip"
dmg_path="$output_dir/onesend-macos-universal.dmg"
team_id="${ONESEND_APPLE_TEAM_ID:-PCJ84YD7HQ}"
asc_config="${ONESEND_ASC_CONFIG:-$repo_root/.release-credentials/onesend/apple/app-store-connect/asc-config.json}"

if [[ -e "$output_dir" ]] && find "$output_dir" -mindepth 1 -print -quit | grep -q .; then
  echo "Release output is not empty: $output_dir" >&2
  exit 2
fi
mkdir -p "$output_dir"

if [[ "${ONESEND_ALLOW_DIRTY:-0}" != "1" ]] && [[ -n "$(git status --porcelain)" ]]; then
  echo "Refusing to release from a dirty worktree. Commit the exact release first." >&2
  exit 3
fi

flutter clean
flutter pub get
flutter analyze --no-pub
flutter test
flutter build macos --release --dart-define=ONESEND_NATIVE_QR_SELF_TEST=true
"$app_path/Contents/MacOS/OneSend"
flutter build macos --release

actual_version="$(plutil -extract CFBundleShortVersionString raw -o - "$app_path/Contents/Info.plist")"
actual_build="$(plutil -extract CFBundleVersion raw -o - "$app_path/Contents/Info.plist")"
if [[ "$actual_version" != "$version" || "$actual_build" != "$build_number" ]]; then
  echo "Built app version $actual_version ($actual_build) does not match $version ($build_number)." >&2
  exit 4
fi

"$repo_root/script/sign_macos_app.sh" "$app_path"

ditto -c -k --sequesterRsrc --keepParent "$app_path" "$zip_path"

credential_args=()
if [[ -n "${APPLE_NOTARY_PROFILE:-}" ]]; then
  credential_args=(--keychain-profile "$APPLE_NOTARY_PROFILE")
elif [[ -n "${APPLE_API_KEY:-}" && -n "${APPLE_API_KEY_PATH:-}" ]]; then
  credential_args=(--key "$APPLE_API_KEY_PATH" --key-id "$APPLE_API_KEY")
  [[ -n "${APPLE_API_ISSUER:-}" ]] && credential_args+=(--issuer "$APPLE_API_ISSUER")
elif [[ -f "$asc_config" ]]; then
  key_id="$(jq -r '.key_id // empty' "$asc_config")"
  issuer_id="$(jq -r '.issuer_id // empty' "$asc_config")"
  key_path="$(jq -r '.private_key_path // empty' "$asc_config")"
  if [[ -z "$key_id" || -z "$issuer_id" || ! -f "$key_path" ]]; then
    echo "ASC config does not contain usable notarization credentials." >&2
    exit 5
  fi
  credential_args=(--key "$key_path" --key-id "$key_id" --issuer "$issuer_id")
else
  echo "Set APPLE_NOTARY_PROFILE, API-key variables, or ONESEND_ASC_CONFIG." >&2
  exit 5
fi

submit_and_require_acceptance() {
  local artifact="$1"
  local evidence="$2"
  xcrun notarytool submit "$artifact" \
    --wait \
    --timeout 60m \
    --output-format json \
    "${credential_args[@]}" | tee "$evidence"
  local status_value
  status_value="$(plutil -extract status raw -o - "$evidence" 2>/dev/null || true)"
  if [[ "$status_value" != "Accepted" ]]; then
    echo "Apple notarization did not accept $artifact." >&2
    exit 6
  fi
}

submit_and_require_acceptance "$zip_path" "$output_dir/notary-zip.json"
xcrun stapler staple "$app_path"
xcrun stapler validate "$app_path"

# Recreate the transport ZIP after stapling the ticket into the source app.
ditto -c -k --sequesterRsrc --keepParent "$app_path" "$zip_path"

dmg_staging="$(mktemp -d "${TMPDIR:-/tmp}/onesend-dmg.XXXXXX")"
zip_verify_dir="$(mktemp -d "${TMPDIR:-/tmp}/onesend-zip-verify.XXXXXX")"
cleanup() { rm -rf "$dmg_staging" "$zip_verify_dir"; }
trap cleanup EXIT
ditto "$app_path" "$dmg_staging/OneSend.app"
ln -s /Applications "$dmg_staging/Applications"
hdiutil create \
  -volname "OneSend $version" \
  -srcfolder "$dmg_staging" \
  -ov \
  -format UDZO \
  "$dmg_path"

identity_line="$(security find-identity -p codesigning -v 2>/dev/null | grep 'Developer ID Application:' | grep -F "$team_id" || true)"
if [[ "$(grep -c . <<<"$identity_line" || true)" -ne 1 ]]; then
  echo "Unable to select one Developer ID identity for $team_id." >&2
  exit 7
fi
identity_hash="$(awk '{print $2}' <<<"$identity_line")"
codesign --force --timestamp --sign "$identity_hash" "$dmg_path"
codesign --verify --strict --verbose=2 "$dmg_path"

submit_and_require_acceptance "$dmg_path" "$output_dir/notary-dmg.json"
xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"

codesign --verify --deep --strict --all-architectures --verbose=2 "$app_path"
spctl --assess --type execute --verbose=4 "$app_path"
codesign --verify --strict --verbose=2 "$dmg_path"
hdiutil verify "$dmg_path" >/dev/null

ditto -x -k "$zip_path" "$zip_verify_dir"
zip_app="$zip_verify_dir/OneSend.app"
if [[ ! -d "$zip_app" ]]; then
  echo "Final ZIP does not contain OneSend.app." >&2
  exit 8
fi
codesign --verify --deep --strict --all-architectures --verbose=2 "$zip_app"
xcrun stapler validate "$zip_app"
spctl --assess --type execute --verbose=4 "$zip_app"

(
  cd "$output_dir"
  shasum -a 256 onesend-macos-universal.zip onesend-macos-universal.dmg > SHA256SUMS-macos.txt
)

echo "macOS $version ($build_number) release is signed, notarized, stapled, and verified:"
echo "  $zip_path"
echo "  $dmg_path"
