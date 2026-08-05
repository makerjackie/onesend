# Changelog

## 1.5.4 (build 23) - 2026-08-05

### 中文

- 修复网页彩色视觉码发送端重复启动多组帧循环的问题；输出现在稳定在单一约 15 fps 时钟，避免相机捕获大量切换中的过渡帧。
- 将网页彩色码原生位图提升并固定为 1024 × 1024，同时按视口清晰缩放显示，改善手机摄像头可见的色块边缘与有效识别率。
- 修复 iOS 彩色接收依赖 `127.0.0.1` 本地 HTTP 服务的问题；WASM 与解码 worker 现在全部从应用内离线资源启动，不创建网络套接字，也不声明本地网络访问。
- 接收页只保留一条 Flutter 进度条，并按已达到的最高解码进度单调推进；不再因多个 worker 的异步报告前后变化而抖动或倒退。
- 彩色接收完成前即可按真实已解码光学字节显示有效速度，文件大小上限提示修正为 33 MiB。
- 补齐离线资源摘要、iOS 无网络路径、进度单调性、网页帧调度与高分辨率画布测试；通过 Flutter 全量测试、网页构建/测试及 iOS 18.5、26.5 模拟器回归。

### English

- Fixed duplicate color-code sender frame loops on the web. Output now follows one stable ~15 fps clock instead of exposing transition-heavy frames to the camera.
- Raised and fixed the native web color-code bitmap at 1024 × 1024 while scaling it cleanly to the viewport, improving color-cell edges and practical camera recognition yield.
- Removed the iOS color receiver's `127.0.0.1` HTTP asset server. WASM and decoder workers now start entirely from offline bundled assets, with no network socket or local-network declaration.
- Reduced reception to one Flutter-owned progress bar that advances monotonically to the furthest decoded point, preventing asynchronous worker reports from shaking or moving it backward.
- Added live effective optical-byte speed before file completion and corrected the color-mode size limit label to 33 MiB.
- Added checks for offline asset digests, the network-free iOS path, monotonic progress, web frame scheduling, and the high-resolution canvas; the full Flutter suite, website build/tests, and iOS 18.5/26.5 simulator regressions pass.

## 1.5.2 (build 21) - 2026-08-04

### 中文

- 修复移动端扫码识别到二维码但未推进接收的问题：统一 Android decoded bytes、Apple Vision decoded bytes 与旧 raw bytes 的安全适配，并让无字节/非 OneSend 帧保持可观察而不中断扫描。
- 增加 JavaScript ↔ Dart 双向协议夹具，覆盖可靠、快速与 Turbo QR 的帧头、分块长度、CRC、文件信封和完整恢复。
- 将官网拆分为首页、发送、接收和下载页面；390 × 844 的首页与接收页固定在一个视口内，摄像头、进度和速度不再需要滚动查找。
- Flutter 手机端改为“传输 / 文件 / 设置”三栏底部导航；接收页固定扫描布局，新增跟随系统、日间与夜间主题。
- 统一全端为“文件 + 扫描框 + 光线”标识；版本显示改为语义版本加发布时间，不再向用户展示内部 build number。

### English

- Fixed mobile scans that recognized a QR without advancing reception by safely adapting Android decoded bytes, Apple Vision decoded bytes, and legacy raw-byte payloads. Missing bytes and non-OneSend frames remain observable without stopping the scan.
- Added bidirectional JavaScript ↔ Dart interoperability fixtures for Reliable, Fast, and Turbo QR frame headers, block lengths, CRCs, file envelopes, and complete recovery.
- Split the website into focused home, send, receive, and download routes. The 390 × 844 home and receive views fit in one viewport with camera, progress, and rate visible without scrolling.
- Reworked Flutter mobile around Transfer, Files, and Settings bottom navigation, a fixed receive layout, and system/light/dark themes.
- Unified every target on the file, scanner-frame, and light-ray mark. User-facing versions now show semantic version plus release time, never the internal build number.

## 1.5.1 (build 20) - 2026-08-04

### 中文

- 将官网以及 Android、iOS、macOS、Windows、Linux 全端的官方标识统一为黑底白色光学标识，并增加品牌资源防漂移检查。
- 简化官网结构与视觉呈现，抽取共享品牌组件，统一官网页面的品牌使用。
- 围绕四种传输模式（可靠 QR、快速 QR、Turbo QR、CIMBAR 彩色视觉码）完成稳定性工作：未设置时仍默认稳定的快速 QR；Turbo QR 和 CIMBAR 仍需显式选择并保持实验边界；可靠 QR 保留兼容/高冗余边界。
- 修复桌面端选择任意文件时的 `Invalid argument: object is unsendable` 问题。
- 修复 QR 接收流程的真实落盘；落盘失败可直接重试而无需重新扫描，成功后提供保存位置、打开、分享和另存为操作。
- 移动端只申请必要的 CAMERA 权限；桌面自动更新的网络访问边界保持不变。
- 本版本不提供未经实测的速度承诺，也不把协议估算或上游参考基准写成 OneSend 真机实测；TestFlight 公测和审核状态以 App Store Connect 为准，本说明不宣称其已完成。

### English

- Unified the official brand mark across the website and Android, iOS, macOS, Windows, and Linux as the white optical mark on a black background, with a brand-asset drift check to keep variants aligned.
- Simplified the website structure and presentation, and extracted shared brand components for consistent use across its pages.
- Completed stability work across four transfer modes—Reliable QR, Fast QR, Turbo QR, and CIMBAR color visual code. Fast QR remains the stable default when no preference is set; Turbo QR and CIMBAR remain explicitly selected experiments; Reliable QR retains the compatibility/high-redundancy boundary.
- Fixed desktop selection of arbitrary files failing with `Invalid argument: object is unsendable`.
- Fixed QR reception so verified files are actually written to local disk. A failed write can be retried without rescanning, and successful reception exposes the saved location plus open, share, and save-as actions.
- Mobile builds request only the necessary CAMERA permission; desktop automatic-update network boundaries are unchanged.
- This release makes no unmeasured speed promise and does not present protocol estimates or upstream reference figures as measured OneSend camera results. TestFlight public-beta and review status remains subject to App Store Connect; this changelog does not claim completion.

## 1.5.0 - 2026-08-04

### 中文

- 保持稳定 QR Fast 为默认算法；新增 Turbo QR 实验档，协议估算有效吞吐约 56 KB/s，并保留可靠兼容档。
- 新增基于 libcimbar v0.6.7c Mode B 的 CIMBAR 彩色视觉码实验：Android/iOS App 与 `onesend.01mvp.com/cimbar` 可使用；上游参考基准约 106 KB/s，不作为 OneSend 真机实测保证。
- 为 CIMBAR 文件增加版本化 CRC32 完整性信封；校验失败的文件不会保存或下载。
- 补齐 CIMBAR 完成后的保存位置、打开、分享/转发和另存副本操作，并在完成、错误、重试或退出时关闭摄像头与 worker。
- 增加真实 libcimbar WASM 编码→RGBA 帧→解码的无相机回环测试，包含确定性丢帧和逐字节/SHA-256 比对；该测试不代表真实光学速度。
- 网站主页面、全局样式、图标和 Logo 保持不变，只新增实验页和次级入口。
- 移动端继续只申请 CAMERA；不声明互联网、局域网、麦克风、相册、蓝牙或定位权限。桌面自动更新的网络边界保持不变。
- 完整翻译并自动检测简体中文、繁體中文、English、日本語、한국어、Español、Français、Deutsch 和 Português。

### English

- Kept stable QR Fast as the default; added experimental Turbo QR at about 56 KB/s protocol-estimated useful throughput and retained the Reliable compatibility profile.
- Added an experimental libcimbar v0.6.7c Mode B color visual-code path for Android/iOS and `onesend.01mvp.com/cimbar`. The upstream reference is about 106 KB/s and is not presented as a measured OneSend guarantee.
- Added a versioned CRC32 integrity envelope for CIMBAR files; failed verification prevents saving or downloading.
- Added saved-location, open, share/forward, and save-a-copy actions after CIMBAR reception, and closes camera/workers on completion, error, retry, or exit.
- Added a real libcimbar WASM encode→RGBA-frame→decode loopback with deterministic frame loss and byte/SHA-256 comparison. This is camera-free and is not a physical optical speed result.
- Preserved the website home page, global styling, icon, and logo; only an experimental route and secondary entry were added.
- Mobile continues to request CAMERA only, with no Internet, local-network, microphone, photo-library, Bluetooth, or location permission. Desktop updater network boundaries are unchanged.
- Completed automatic-detection translations for Simplified Chinese, Traditional Chinese, English, Japanese, Korean, Spanish, French, German, and Portuguese.

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
