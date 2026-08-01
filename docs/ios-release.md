# iOS / TestFlight release checklist

OneSend uses the bundle identifier `com.makerjackie.onesend`.

## One-time Apple setup

1. Register the App ID in Apple Developer with the identifier above.
2. Create the App Store Connect app named `OneSend`.
3. Add the privacy policy URL, using the repository's `PRIVACY.md` page after the GitHub repository is public.
4. Add the camera usage description already present in `ios/Runner/Info.plist`.
5. Confirm the App Store Connect team has a distribution certificate and that Xcode automatic signing can create a provisioning profile.

## Local archive and upload

```bash
flutter pub get
flutter build ipa \
  --release \
  --build-name 1.1.1 \
  --build-number 3 \
  --export-method app-store
```

Upload the generated IPA from `build/ios/ipa/` with Transporter or App Store Connect. The archive must use the registered bundle identifier and an App Store distribution profile.

## TestFlight external beta

Public beta link: <https://testflight.apple.com/join/n2t1KrCp>

The public link can be created while Beta App Review is pending. Testers can
join after Apple approves at least one build in the external group.

1. Wait for the build to finish processing in App Store Connect.
2. Create an external tester group, for example `Early Access`.
3. Add the build to that group.
4. Fill in `What to Test` and the Beta App Review contact details.
5. Submit the external beta build for review and wait for the status to become available to external testers.

The review notes should explain that the app transfers a file by showing animated QR codes on one device and scanning them with the camera on another. No login or network connection is required.
