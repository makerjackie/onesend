# Desktop updates and release checklist

OneSend desktop update metadata is served from
`https://onesend.01mvp.com/updates/`. The application embeds only the public
Ed25519 key. The private key stays outside git under the ignored release
credentials directory and must never be copied into an application artifact.

## Platform behavior

- **macOS:** Sparkle 2.9.5 reads `appcast.xml`, verifies the signed feed and the
  ZIP's Ed25519 signature, then installs through its sandbox Installer XPC
  service. OneSend retains App Sandbox, outgoing-network, camera, user-selected
  file, Downloads, and the two Sparkle Mach service entitlements.
- **Windows:** WinSparkle 0.9.4 reads the Windows x64 item from the same appcast,
  verifies the installer signature, and runs the stable-ID per-user Inno Setup
  installer. Its updater-only argument relaunches OneSend after replacement. The
  CI job installs the result twice into one directory, then exercises that
  updater/relaunch path.
- **Linux:** OneSend verifies the Ed25519 signature around `latest.json`, then
  verifies the selected asset's HTTPS host/path, byte length, and SHA-256 before
  opening the archive. Interrupted or invalid `.part` files are removed.

All three platforms check at most once every 24 hours by default. The user can
turn automatic checks off and can always run a manual check from the home menu.
The updater never receives file-transfer contents or camera frames.

## Native QR codec self-test

The native QR self-test must run inside the standard macOS app so Flutter's
native ZXing/FFI bridge is linked by the normal Runner target. Do not use
`tool/qr_codec_self_test.dart` as a Flutter `--target` or invoke the native
ZXing library directly with `dart run`. The tool file is only a convenience
wrapper around the standard app path.

From the repository root, the explicit release-check sequence is:

```bash
flutter build macos --release \
  --dart-define=ONESEND_NATIVE_QR_SELF_TEST=true
build/macos/Build/Products/Release/OneSend.app/Contents/MacOS/OneSend
flutter build macos --release
```

For a one-shot local check, `dart run tool/qr_codec_self_test.dart` delegates
to the same build and executable. The app exits with code 0 on success and 1
on a QR codec failure.

## Release order

1. Update `pubspec.yaml`, `CHANGELOG.md`, and platform metadata. Keep the same
   semantic version and build number across all artifacts.
2. Run `flutter analyze`, `flutter test`, and the standard-app QR codec
   self-test described above.
3. Merge the exact release commit, create `vX.Y.Z`, and let GitHub Actions build
   the draft Android, Windows, Linux, and validation macOS artifacts.
4. On the release Mac, run `script/release_macos.sh`. It signs Sparkle's nested
   XPC services/helpers inside-out, signs OneSend with hardened runtime and
   resolved sandbox entitlements, notarizes the ZIP, staples the app, creates
   and signs the DMG, notarizes/staples the DMG, and verifies both final files.
5. Download `onesend-windows-setup.exe` and `onesend-linux-x64.tar.gz` from the
   draft. Generate the feeds from the **final bytes**:

   ```bash
   dart run tool/generate_update_feed.dart \
     --version X.Y.Z \
     --build BUILD \
     --macos dist/vX.Y.Z/onesend-macos-universal.zip \
     --windows /path/to/onesend-windows-setup.exe \
     --linux /path/to/onesend-linux-x64.tar.gz \
     --output /tmp/onesend-update-feed \
     --sign-tool /path/to/Sparkle/bin/sign_update \
     --private-key .release-credentials/onesend/desktop-updater/ed25519-private.key \
     --note "Release note"
   ```

6. Verify both formats before deployment:

   ```bash
   /path/to/Sparkle/bin/sign_update \
     --ed-key-file .release-credentials/onesend/desktop-updater/ed25519-private.key \
     --verify /tmp/onesend-update-feed/appcast.xml
   dart run tool/verify_update_feed.dart \
     /tmp/onesend-update-feed/latest.json X.Y.Z BUILD
   ```

7. Replace the CI macOS validation ZIP with the notarized ZIP, upload the DMG,
   regenerate `SHA256SUMS.txt`, publish the GitHub Release, then deploy
   `appcast.xml` and `latest.json` to the website. Never deploy a feed before all
   referenced release URLs return the final artifact bytes.
8. Test an update from the previous public macOS and Windows versions. Confirm
   version replacement, relaunch behavior, transfer history preservation, and a
   new optical send/receive after the upgrade.

## Failure and rollback rules

- A signature, length, hash, notarization, installer, or clean-machine test
  failure blocks publication.
- Do not replace bytes behind a published signed update URL. Publish a higher
  patch version instead, even if the bad release was visible only briefly.
- Keep the previous release and feed material available until the new update has
  passed real upgrade tests on both macOS and Windows.
- Key rotation requires a bridge release whose artifact is signed by the old key
  but embeds the new public key. Retain the old private key offline until that
  bridge has had sufficient adoption.
