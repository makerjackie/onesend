# OneSend · 扫传

<p align="center">
  <img src="assets/brand/onesend-icon-1024.png" width="112" alt="OneSend optical data icon">
</p>

<p align="center">
  <a href="#中文">中文</a> · <a href="#english">English</a>
</p>

[GitHub Releases / latest](https://github.com/makerjackie/onesend/releases/latest) ·
[iOS TestFlight](https://testflight.apple.com/join/n2t1KrCp) ·
[产品网站 / Website](https://onesend.01mvp.com) ·
[隐私说明 / Privacy](PRIVACY.md)

## 中文

OneSend（扫传）是一款实验性的、纯视觉的跨设备文件传输工具，覆盖手机和电脑。
发送设备把文件编码为持续变化的视觉码并显示在屏幕上，接收设备用摄像头连续扫描，
在本地还原并保存文件。

它不需要账号、配对、服务器或文件网络传输；只需要一块屏幕和一枚摄像头。v1.5.2
（build 21）仍为实验性版本，以下内容描述当前确定的 v1.5.2 范围。

### v1.5.2 功能

- 支持任意文件，单文件上限为 **64 MB**。
- 官网与 Android、iOS、macOS、Windows、Linux 全端统一使用“文件 + 扫描框 + 光线”标识，并增加品牌资源防漂移检查。
- 官网拆分为首页、发送、接收和下载页面；390 × 844 的首页与接收页无需滚动，手机端扫码窗口和进度始终在首屏。
- Flutter 手机端采用“传输 / 文件 / 设置”底部导航，设置中提供跟随系统、日间和夜间主题。
- 修复 Android、iOS 和 Apple Vision 扫码返回字节格式不一致导致的“识别二维码但无反应”，并保留可观察诊断而不中断扫描。
- 增加 JavaScript ↔ Dart 双向协议夹具，覆盖可靠、快速和 Turbo QR 的帧头、CRC、信封与完整恢复。
- 围绕可靠 QR、快速 QR、Turbo QR 和 CIMBAR 彩色视觉码四种模式做稳定性工作；未设置时默认稳定的快速 QR，Turbo QR 与 CIMBAR 仍需显式选择并保持实验边界，可靠 QR 保留兼容/高冗余边界。
- 修复桌面端选择任意文件时 `Invalid argument: object is unsendable` 的问题。
- 默认使用快速模式，理论有效速度约 **33 KB/s**；在“设置”中可以改为“兼容/可靠”模式，理论有效速度约 **4.7 KB/s**。
- 新增 **Turbo QR（实验）**，协议估算有效吞吐约 **56 KB/s**。该数字不是摄像头实测；高密度二维码对对焦、曝光和稳定性要求更高。
- 新增 **CIMBAR 彩色视觉码（实验）**：Android / iOS App 与网站提供 Mode B 实验入口。libcimbar 上游在特定设备上的持续基准约 **106 KB/s**，这不是 OneSend 的实测保证。桌面原生 App 仍使用 QR；桌面可通过网站体验 CIMBAR。
- 快速 QR 仍是未设置时的新建传输默认；Turbo QR 与 CIMBAR 只在显式选择后启用，可靠 QR 用于兼容性和更高冗余。
- 快速模式使用 LT fountain 流，配合连续二维码传输，可应对漏扫、乱序、重复帧和中途加入。
- 每帧 CRC32 与载荷/文件完整性校验会在接收端执行；校验未通过的文件不会被当作完成文件保存。
- 发送和接收都支持暂停、继续和重新开始。
- QR 接收会把已验证文件真实写入本地磁盘；如果写入失败，可直接重试而无需重新扫描。保存成功后显示保存位置，并提供打开、分享和另存为。
- 最近传输历史保存在本机，可再次打开已保存的接收文件；清除历史不会删除文件本身。

实际速度会受摄像头、屏幕、对焦、环境光和设备稳定性影响。视觉传输是单向的，
发送端会持续循环，直到用户结束发送；接收端不需要联网回传缺失帧。

### 语言与界面

App 内置九种语言：简体中文、繁體中文、English、日本語、한국어、Español、
Français、Deutsch、Português。首次启动会自动检测系统语言，也可以在“设置”中手动切换。

官网与各端共享官方“文件 + 扫描框 + 光线”标识和品牌资源；“关于”页面提供 GitHub
入口，并标明 MIT 许可、MakerJackie 与 01MVP。

### 内置测试素材

项目内置一段原创的 **10 秒、28,552 bytes、H.264/AAC** 测试片，用于重复测试文件传输。
它不是 Rickroll，也不是任何商业 MV；画面和音频均为项目生成的测试素材，没有下载的影片或
歌曲。AAC 音轨只是这个普通测试文件的一部分，不代表 OneSend 提供独立的音频传输模式。
该素材可以随 MIT 项目一起再分发。

### 权限与联网边界

- **移动端（Android / iOS）：** 用户可见、会申请的运行时权限只有 CAMERA，而且只在接收时需要。
  移动端不声明或请求互联网、局域网、蓝牙、麦克风、照片或定位权限；启动时绝不构造或运行
  HTTP updater。文件选择由系统文件选择器处理，接收文件保存在应用本地目录。
- **桌面端（macOS / Windows / Linux）：** 桌面自动更新可以联网，但只访问官方签名更新源
  （当前更新源为 [`onesend.01mvp.com/updates`](https://onesend.01mvp.com/updates/)）和对应的签名安装包。
  文件传输本身永远不联网，更新服务不可用也不应影响光传。

OneSend 不是加密工具：能看到完整二维码流的人或摄像头可能重建文件。传输敏感资料时，
请控制屏幕和摄像头的物理可见范围，或先使用你信任的加密工具。

v1.5.2 不宣称已达到 200 KB/s，也不把上游 106 KB/s 基准写成 OneSend 真机实测；音频传输仍未实现。

### 下载

- [GitHub Releases / latest](https://github.com/makerjackie/onesend/releases/latest)：桌面版与 Android 构建产物。
- [iOS TestFlight 链接](https://testflight.apple.com/join/n2t1KrCp)：状态以 App Store Connect 为准，本页不宣称公测或审核已完成。

### 开发

在仓库根目录运行现有命令：

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

推送版本 tag 会触发 Android、macOS、Windows、Linux 构建并创建 GitHub Release：

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

iOS 签名、TestFlight 和 Beta App Review 流程见
[`docs/ios-release.md`](docs/ios-release.md)。桌面签名更新源、macOS 公证和发布顺序见
[`docs/desktop-updates.md`](docs/desktop-updates.md)。

### 开源

OneSend 使用 [MIT License](LICENSE)。协议 v1 与 LT 基础工作参考了 MIT 授权的
[`decimen-optical-transfer`](https://github.com/bashalarmistalt/decimen-optical-transfer)。
设计 v2 时也评估了 [`deedy/qr-data-transfer`](https://github.com/deedy/qr-data-transfer)
的公开架构；由于该仓库当时未声明许可证，OneSend 没有复制其代码或资源。
实验性彩色模式分发未修改的 [`libcimbar v0.6.7c`](https://github.com/sz3/libcimbar/releases/tag/v0.6.7c)
JS/WASM 资产；这些资产继续适用 MPL-2.0，OneSend 自身代码仍为 MIT。

完整第三方声明见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。

## English

OneSend (扫传) is an experimental, purely visual file-transfer tool for phones and
computers. The sending device encodes a file as continuously changing visual codes on its
screen. The receiving device uses its camera to scan the stream, reconstructs the file,
and saves it locally.

It needs no account, pairing, server, or network file transfer—only a screen and a camera.
Version 1.5.2 (build 21) remains experimental; the details below describe the current v1.5.2 scope.

### v1.5.2 features

- Any file up to **64 MB** per file.
- The file, scanner-frame, and light-ray mark is shared across the website and Android, iOS, macOS, Windows, and Linux, with a brand-asset drift check.
- The website is split into focused home, send, receive, and download routes. The 390 × 844 home and receive views fit without page scrolling, keeping camera progress on the first screen.
- Flutter mobile uses Transfer, Files, and Settings bottom navigation, with system, light, and dark themes in Settings.
- Fixed Android, iOS, and Apple Vision scanner byte-format differences that could recognize a QR code without advancing reception; diagnostics remain visible without stopping the scanner.
- Added bidirectional JavaScript ↔ Dart protocol fixtures covering Reliable, Fast, and Turbo QR headers, CRCs, envelopes, and complete recovery.
- Stability work covers four modes—Reliable QR, Fast QR, Turbo QR, and CIMBAR color visual code. Fast QR remains the stable default when unset; Turbo QR and CIMBAR require explicit selection and remain experimental, while Reliable QR retains the compatibility/high-redundancy boundary.
- Fixed desktop selection of arbitrary files failing with `Invalid argument: object is unsendable`.
- Fast mode is the default, with about **33 KB/s theoretical useful throughput**. The
  Settings page can switch the default for new transfers to Compatible/Reliable mode, at
  about **4.7 KB/s theoretical useful throughput**.
- **Turbo QR (experimental)** has about **56 KB/s protocol-estimated useful throughput**.
  This is not a camera measurement; the denser QR profile needs better focus, exposure, and stability.
- **CIMBAR color visual code (experimental)** is available in the Android/iOS app and on
  the website. The upstream libcimbar Mode B benchmark reports about **106 KB/s** on a
  specific setup; this is not a measured OneSend guarantee. Native desktop apps retain QR,
  while desktop users can try CIMBAR on the website.
- Fast QR remains the default for new transfers when unset; Turbo QR and CIMBAR are enabled
  only by explicit selection, while Reliable QR is the compatibility/high-redundancy option.
- Fast mode uses an LT fountain stream and continuous QR frames, tolerating missed,
  reordered, duplicate frames and joining part-way through a stream.
- Per-frame CRC32 and payload/file integrity checks run on the receiver; a file is not
  treated as complete or saved until verification succeeds.
- Both sending and receiving can be paused, resumed, or restarted.
- QR reception writes the verified file to local disk. If writing fails, it can be retried
  without rescanning; after a successful save, the location is shown and users can open,
  share, or save as.
- Recent transfer history is stored locally and can reopen a saved received file. Clearing
  history does not delete the file itself.

Actual throughput depends on the camera, display, focus, lighting, and device stability.
The visual stream is one-way: the sender loops until the user ends the send, and the receiver
does not need a network channel to request missing frames.

### Languages and interface

The app includes nine languages: Simplified Chinese, Traditional Chinese, English, Japanese,
Korean, Spanish, French, German, and Portuguese. It detects the system language on first
launch, and users can switch manually in Settings.

The website and all app targets share the official file, scanner-frame, and light-ray mark.
About links to GitHub and identifies the MIT license, MakerJackie, and 01MVP.

### Included test fixture

The repository includes an original **10-second, 28,552-byte H.264/AAC** test clip for
repeatable file-transfer testing. It is not Rickroll and is not a commercial music video;
the picture and audio are project-generated test material with no downloaded footage or
song. The AAC track is simply part of this ordinary test file and does not mean OneSend
implements a separate audio-transfer mode. The fixture may be redistributed with the
MIT-licensed project.

### Permission and network boundary

- **Mobile (Android / iOS):** The only user-facing runtime permission is CAMERA, needed only
  when receiving. Mobile builds do not declare or request Internet, local-network, Bluetooth,
  microphone, photo-library, or location permissions. Startup never constructs or runs an
  HTTP updater. File selection is handled by the system file picker, and received files stay
  in the app's local directory.
- **Desktop (macOS / Windows / Linux):** Automatic updates may use the network, but only for
  the official signed update source (currently
  [`onesend.01mvp.com/updates`](https://onesend.01mvp.com/updates/)) and its signed packages.
  File transfer itself never uses the network; transfer continues to work if the updater is
  unavailable.

OneSend is not an encryption tool: anyone who can see the complete QR stream may be able to
reconstruct the file. Limit the physical visibility of the screen and camera, or encrypt
sensitive material with a tool you trust first.

Version 1.5.2 does not claim 200 KB/s or present the upstream 106 KB/s benchmark as a measured
OneSend result. Audio transfer is still not implemented.

### Downloads

- [GitHub Releases / latest](https://github.com/makerjackie/onesend/releases/latest): desktop and Android builds.
- [iOS TestFlight link](https://testflight.apple.com/join/n2t1KrCp): iOS testing; status is
  subject to App Store Connect, and this page does not claim that public beta or review is complete.

### Development

Run the existing commands from the repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

Pushing a version tag triggers Android, macOS, Windows, and Linux builds and creates a
GitHub Release:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

See [`docs/ios-release.md`](docs/ios-release.md) for iOS signing, TestFlight, and Beta App
Review. See [`docs/desktop-updates.md`](docs/desktop-updates.md) for the signed desktop update
source, macOS notarization, and release order.

### Open source

OneSend is released under the [MIT License](LICENSE). Protocol v1 and the LT foundation
reference the MIT-licensed [`decimen-optical-transfer`](https://github.com/bashalarmistalt/decimen-optical-transfer).
The public architecture of [`deedy/qr-data-transfer`](https://github.com/deedy/qr-data-transfer)
was also evaluated while designing v2; because that repository did not declare a license at
the time, OneSend copied neither its code nor its assets.
The experimental color mode distributes unmodified JS/WASM assets from
[`libcimbar v0.6.7c`](https://github.com/sz3/libcimbar/releases/tag/v0.6.7c). Those covered
assets remain under MPL-2.0; OneSend's own code remains MIT-licensed.

See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the complete third-party notices.
