# OneSend optical test video

`onesend-optical-test.mp4` is the **shared built-in sample** used for quick
end-to-end optical transfer tests across:

- the Flutter app send flow (`一键发送内置测试视频`)
- the website web-transfer sender (`测试视频`)

Both surfaces load the same bytes so users get one consistent demo clip.

## Current fixture

- Source: user-provided WeChat sample
  (`…/msg/video/2026-08/901777534adb47f2ab88e4cd1f7e8c68.mp4`)
- H.264 + AAC, about 5 seconds, 426×240, ~122 KB
- SHA-256: `5dfda9d9a8474807525aba5381bac1fce1cf4ef3b94f2b4247ca5a23dbd4fad0`
- Exact probe output is recorded in `ffprobe.txt`

## Loader

- App: `lib/services/sample_file_service.dart` → `assets/demo/onesend-optical-test.mp4`
- Website: `website/public/onesend-optical-test.mp4`

## Replacing

```bash
cp /path/to/sample.mp4 assets/demo/onesend-optical-test.mp4
cp assets/demo/onesend-optical-test.mp4 website/public/onesend-optical-test.mp4
ffprobe -v error -show_format -show_streams assets/demo/onesend-optical-test.mp4 \
  > assets/demo/ffprobe.txt
# then rebuild the macOS/iOS app so the asset is rebundled
```

Do **not** use `tool/generate_demo_video.sh` for production demos unless you
explicitly want a synthetic fallback.
