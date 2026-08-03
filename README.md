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
发送设备把文件编码为持续变化的二维码并显示在屏幕上，接收设备用摄像头连续扫描，
在本地还原并保存文件。

它不需要账号、配对、服务器或文件网络传输；只需要一块屏幕和一枚摄像头。v1.4.0
已发布，当前仍为实验性版本，以下内容描述当前确定的 v1.4 范围。

### v1.4 功能

- 支持任意文件，单文件上限为 **64 MB**。
- 默认使用快速模式，理论有效速度约 **33 KB/s**；在“设置”中可以改为“兼容/可靠”模式，理论有效速度约 **4.7 KB/s**。
- 发送主界面不提供模式选择，也不显示 FPS；模式只在设置中作为之后新建发送的默认值配置。
- 快速模式使用 LT fountain 流，配合连续二维码传输，可应对漏扫、乱序、重复帧和中途加入。
- 每帧 CRC32 与载荷/文件完整性校验会在接收端执行；校验未通过的文件不会被当作完成文件保存。
- 发送和接收都支持暂停、继续和重新开始。
- 接收完成后自动保存到本机并显示保存位置；可以打开、分享、另存一份，桌面端还可以在文件管理器中定位文件。
- 最近传输历史保存在本机，可再次打开已保存的接收文件；清除历史不会删除文件本身。

实际速度会受摄像头、屏幕、对焦、环境光和设备稳定性影响。二维码传输是单向的，
发送端会持续循环，直到用户结束发送；接收端不需要联网回传缺失帧。

### 语言与界面

App 内置九种语言：简体中文、繁體中文、English、日本語、한국어、Español、
Français、Deutsch、Português。首次启动会自动检测系统语言，也可以在“设置”中手动切换。

v1.4 包含新的 OneSend 图标，以及“设置”和“关于”页面。“关于”页面提供 GitHub
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

v1.4 文档不宣称新的视觉算法，也不宣称已经实现音频传输；核心仍是持续二维码的纯视觉文件传输。

### 下载

- [GitHub Releases / latest](https://github.com/makerjackie/onesend/releases/latest)：桌面版与 Android 构建产物。
- [iOS TestFlight 公测](https://testflight.apple.com/join/n2t1KrCp)：iOS 测试版。

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

完整第三方声明见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。

## English

OneSend (扫传) is an experimental, purely visual file-transfer tool for phones and
computers. The sending device encodes a file as continuously changing QR codes on its
screen. The receiving device uses its camera to scan the stream, reconstructs the file,
and saves it locally.

It needs no account, pairing, server, or network file transfer—only a screen and a camera.
Version 1.4.0 is released and experimental; the details below describe the v1.4 scope.

### v1.4 features

- Any file up to **64 MB** per file.
- Fast mode is the default, with about **33 KB/s theoretical useful throughput**. The
  Settings page can switch the default for new transfers to Compatible/Reliable mode, at
  about **4.7 KB/s theoretical useful throughput**.
- The main sending screen does not offer a mode selector or show FPS. The mode is configured
  only as the default for new sends in Settings.
- Fast mode uses an LT fountain stream and continuous QR frames, tolerating missed,
  reordered, duplicate frames and joining part-way through a stream.
- Per-frame CRC32 and payload/file integrity checks run on the receiver; a file is not
  treated as complete or saved until verification succeeds.
- Both sending and receiving can be paused, resumed, or restarted.
- After reception, the file is saved automatically and its location is shown. Users can
  open, share, save a copy elsewhere, and, on desktop, reveal the file in the file manager.
- Recent transfer history is stored locally and can reopen a saved received file. Clearing
  history does not delete the file itself.

Actual throughput depends on the camera, display, focus, lighting, and device stability.
The QR stream is one-way: the sender loops until the user ends the send, and the receiver
does not need a network channel to request missing frames.

### Languages and interface

The app includes nine languages: Simplified Chinese, Traditional Chinese, English, Japanese,
Korean, Spanish, French, German, and Portuguese. It detects the system language on first
launch, and users can switch manually in Settings.

Version 1.4 includes a new OneSend icon and Settings/About pages. About links to GitHub and
identifies the MIT license, MakerJackie, and 01MVP.

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

The v1.4 documentation does not claim a new visual algorithm or implemented audio transfer;
the core remains purely visual file transfer over continuous QR codes.

### Downloads

- [GitHub Releases / latest](https://github.com/makerjackie/onesend/releases/latest): desktop and Android builds.
- [iOS TestFlight public beta](https://testflight.apple.com/join/n2t1KrCp): iOS testing.

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

See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the complete third-party notices.
