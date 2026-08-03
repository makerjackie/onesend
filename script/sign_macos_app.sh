#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

app_path="${1:-}"
team_id="${ONESEND_APPLE_TEAM_ID:-PCJ84YD7HQ}"
identity_selector="${ONESEND_DEVELOPER_IDENTITY:-$team_id}"

if [[ -z "$app_path" || ! -d "$app_path" || "$app_path" != *.app ]]; then
  echo "Usage: $0 <OneSend.app>" >&2
  exit 2
fi

bundle_id="$(plutil -extract CFBundleIdentifier raw -o - "$app_path/Contents/Info.plist" 2>/dev/null || true)"
if [[ "$bundle_id" != "com.makerjackie.onesend" ]]; then
  echo "Unexpected bundle identifier: $bundle_id" >&2
  exit 3
fi

identities="$(security find-identity -p codesigning -v 2>/dev/null | grep 'Developer ID Application:' || true)"
identities="$(grep -F "$identity_selector" <<<"$identities" || true)"
identity_count="$(grep -c . <<<"$identities" || true)"
if [[ "$identity_count" -ne 1 ]]; then
  echo "Expected one Developer ID identity matching '$identity_selector', found $identity_count." >&2
  exit 4
fi
identity_hash="$(awk '{print $2}' <<<"$identities")"

sparkle="$app_path/Contents/Frameworks/Sparkle.framework"
sparkle_version="$sparkle/Versions/B"
required_sparkle_paths=(
  "$sparkle_version/XPCServices/Installer.xpc"
  "$sparkle_version/XPCServices/Downloader.xpc"
  "$sparkle_version/Autoupdate"
  "$sparkle_version/Updater.app"
  "$sparkle"
)
for required_path in "${required_sparkle_paths[@]}"; do
  if [[ ! -e "$required_path" ]]; then
    echo "Missing required Sparkle component: $required_path" >&2
    exit 5
  fi
done

resolved_entitlements="$(mktemp "${TMPDIR:-/tmp}/onesend-entitlements.XXXXXX.plist")"
cleanup() { rm -f "$resolved_entitlements"; }
trap cleanup EXIT
cp macos/Runner/Release.entitlements "$resolved_entitlements"
/usr/libexec/PlistBuddy \
  -c 'Set :com.apple.security.temporary-exception.mach-lookup.global-name:0 com.makerjackie.onesend-spks' \
  -c 'Set :com.apple.security.temporary-exception.mach-lookup.global-name:1 com.makerjackie.onesend-spki' \
  "$resolved_entitlements"

sign_runtime() {
  codesign --force --timestamp --options runtime --sign "$identity_hash" "$1"
}

# Sparkle's documented inside-out signing order. Downloader may carry its own
# entitlements in custom builds, so preserve them explicitly.
sign_runtime "$sparkle_version/XPCServices/Installer.xpc"
codesign --force --timestamp --options runtime \
  --preserve-metadata=entitlements \
  --sign "$identity_hash" \
  "$sparkle_version/XPCServices/Downloader.xpc"
sign_runtime "$sparkle_version/Autoupdate"
sign_runtime "$sparkle_version/Updater.app"
sign_runtime "$sparkle"

while IFS= read -r framework; do
  [[ "$framework" == "$sparkle" ]] && continue
  sign_runtime "$framework"
done < <(find "$app_path/Contents/Frameworks" -mindepth 1 -maxdepth 1 -type d -name '*.framework' -print | sort)

while IFS= read -r library; do
  sign_runtime "$library"
done < <(find "$app_path/Contents/Frameworks" -mindepth 1 -maxdepth 1 -type f -name '*.dylib' -print | sort)

codesign --force --timestamp --options runtime \
  --entitlements "$resolved_entitlements" \
  --sign "$identity_hash" \
  "$app_path"

codesign --verify --deep --strict --all-architectures --verbose=2 "$app_path"

verify_distributable_code() {
  local code_path="$1"
  local details
  local signed_team
  details="$(codesign --display --verbose=4 "$code_path" 2>&1)"
  signed_team="$(sed -n 's/^TeamIdentifier=//p' <<<"$details")"
  if [[ "$signed_team" != "$team_id" ]]; then
    echo "Unexpected signed Team ID '$signed_team': $code_path" >&2
    exit 6
  fi
  if ! grep -Eq 'flags=.*\(runtime\)' <<<"$details"; then
    echo "Hardened runtime is missing: $code_path" >&2
    exit 6
  fi
}

for code_path in "${required_sparkle_paths[@]}"; do
  verify_distributable_code "$code_path"
done
while IFS= read -r framework; do
  verify_distributable_code "$framework"
done < <(find "$app_path/Contents/Frameworks" -mindepth 1 -maxdepth 1 -type d -name '*.framework' -print | sort)
verify_distributable_code "$app_path"

entitlements_output="$(codesign --display --entitlements :- "$app_path" 2>/dev/null)"
if grep -Fq 'com.apple.security.get-task-allow' <<<"$entitlements_output"; then
  echo "Release app unexpectedly contains get-task-allow." >&2
  exit 7
fi
if ! grep -Fq 'com.makerjackie.onesend-spks' <<<"$entitlements_output"; then
  echo "Resolved Sparkle sandbox entitlement is missing." >&2
  exit 8
fi

echo "Signed OneSend and all nested Sparkle components for Team $team_id."
