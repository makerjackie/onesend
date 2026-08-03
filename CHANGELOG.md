# Changelog

## 1.4.0 - 2026-08-03 / 已发布

### 中文

- 明确 OneSend / 扫传 v1.4 是面向手机和电脑的实验性纯视觉持续二维码文件传输。
- 默认新建发送使用快速模式，理论有效速度约 33 KB/s；在“设置”中可切换到约 4.7 KB/s 的兼容/可靠模式。发送主界面不提供模式选择，也不显示 FPS。
- 支持任意不超过 64 MB 的文件、快速 LT fountain 流、逐帧 CRC32 与文件完整性校验，以及发送/接收暂停、继续和重新开始。
- 接收完成后自动保存并显示位置，提供打开、分享、另存和桌面文件管理器定位；保留本地传输历史操作。
- 增加简体中文、繁體中文、英语、日语、韩语、西班牙语、法语、德语和葡萄牙语，共九种语言，支持自动检测和手动切换。
- 内置原创 10 秒、28,552 bytes 的 H.264/AAC 测试片；明确不是 Rickroll 或商业 MV，可随 MIT 项目再分发。该素材不代表实现了独立音频传输。
- 移动端仅申请 CAMERA，不声明或请求互联网、局域网、蓝牙、麦克风、照片或定位权限；启动时不构造或运行 HTTP updater。桌面自动更新只访问官方签名源，文件传输永不联网。
- 增加新图标、设置/关于页面，并展示 GitHub、MIT、MakerJackie 与 01MVP 信息。
- 本版本不宣称新的视觉算法，也不宣称音频传输已经实现。

### English

- Defined OneSend / 扫传 v1.4 as an experimental, purely visual continuous-QR file transfer experience for phones and computers.
- Fast mode is the default for new sends at about 33 KB/s theoretical useful throughput; Settings can switch to Compatible/Reliable mode at about 4.7 KB/s. The main sending screen has no mode selector and shows no FPS.
- Supports any file up to 64 MB, a Fast LT fountain stream, per-frame CRC32 and file-integrity checks, plus pause, resume, and restart for sending and receiving.
- Saves received files automatically and shows their location, with open, share, save-as, and desktop file-manager reveal actions; keeps local transfer history actions.
- Adds nine in-app languages—Simplified Chinese, Traditional Chinese, English, Japanese, Korean, Spanish, French, German, and Portuguese—with automatic detection and manual switching.
- Includes an original 10-second, 28,552-byte H.264/AAC test clip. It is explicitly not Rickroll or a commercial music video and may be redistributed with the MIT project; the fixture does not represent a separate audio-transfer feature.
- Mobile builds request only CAMERA and do not declare or request Internet, local-network, Bluetooth, microphone, photo-library, or location permissions; startup does not construct or run an HTTP updater. Desktop automatic updates use only the official signed source, while file transfer never uses the network.
- Adds a new icon, Settings/About pages, and GitHub, MIT, MakerJackie, and 01MVP information.
- This release does not claim a new visual algorithm or implemented audio transfer.

## 1.3.0 - 2026-08-03

- Added signed desktop update checks and an in-app version/update settings UI.
- Integrated sandbox-compatible Sparkle 2.9.5 on macOS and WinSparkle 0.9.4
  with a per-user Inno Setup installer on Windows.
- Added a signed Linux release manifest with strict download URL, length, and
  SHA-256 verification before an archive can be opened.
- Added a dedicated Ed25519 update key, signed appcast generation, signed-feed
  verification, and fail-closed tests for tampering and corrupted downloads.
- Added deterministic macOS nested signing, notarization, stapling, and final
  ZIP/DMG verification scripts, including every Sparkle helper and XPC service.
- Added clean-install and in-place-upgrade smoke tests for the Windows installer.
- Kept optical file transfer available if the update service is unavailable.

## 1.2.1 - 2026-08-03

- Fixed file selection failing with `Invalid argument: object is unsendable` on
  macOS and other native platforms.
- Moved send and receive file-envelope work behind explicit, sendable isolate
  messages so UI state and plugin objects cannot cross the worker boundary.
- Added isolate round-trip and real file-picker UI regression coverage for text,
  arbitrary binary data, compression, and Unicode file metadata.

## 1.2.0 - 2026-08-02

- Increased Fast mode from 1320 B at 15 fps to a fixed V30-L profile carrying
  1700 B at 24 fps, for about 32 KB/s theoretical useful throughput.
- Synchronized optical playback to display vsync and replaced per-frame QR mask
  searches with deterministic standards-compliant masks.
- Added a rateless LT schedule for Fast mode, cutting recovery overhead under
  frame loss while retaining bounded-memory scheduling for large files.
- Preserved receive compatibility with the OneSend 1.1 Fast profile.
- Processed every QR detected in a mobile camera exposure and added pacing,
  capacity, compatibility, and 30% frame-loss regression tests.

## 1.1.2 - 2026-08-02

- Updated the Chinese product name to “扫传” across the app, website, release
  metadata, and TestFlight materials.

## 1.1.1 - 2026-08-01

- Replaced the Flutter placeholder icon with the original OneSend optical-data mark on iOS, Android, macOS, Windows, and the product website.

## 1.1.0 - 2026-08-01

- Added Reliable and Fast optical transfer profiles.
- Added protocol v2 with 32-bit sessions and block counts plus per-frame CRC32.
- Interleaved systematic source frames with deterministic LT repair frames.
- Added gzip file envelopes with original and stored-data integrity checks.
- Added randomized loss, corruption, duplicate, reorder, and late-join tests.
- Replaced desktop photo polling with in-memory camera-frame decoding.
- Added bounded decompression and decoder memory limits for malformed inputs.
- Added a packaged-app native QR encode/decode self-test.
- Kept protocol v1 receive compatibility.
- Added local file opening from completion and transfer history screens.
- Added persistent Android release signing and release checksum generation.
- Added Developer ID signing, notarized universal macOS ZIP/DMG packaging, and a product site.

## 1.0.0 - 2026-08-01

- Initial OneSend release.
- Animated QR file sending and continuous camera receiving.
- Pause, resume, restart, integrity verification and local transfer history.
