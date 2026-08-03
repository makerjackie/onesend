# OneSend 1.4.0 Release Notes / 发布说明

**Status / 状态:** Released / 已发布 · 2026-08-03

## 中文

OneSend（扫传）1.4.0 是面向手机和电脑的实验性纯视觉文件传输版本。发送设备把
文件显示为持续变化的二维码，接收设备用摄像头连续扫描并在本地还原；文件传输不
需要网络、账号、服务器或设备配对。

### 这次版本包含

- 任意文件，单文件上限 64 MB。
- 默认快速模式，理论有效速度约 33 KB/s；“设置”中可切换到约 4.7 KB/s 的兼容/可靠模式。
- 发送主界面不让用户选择模式，也不显示 FPS；模式选择只存在于设置中的默认值。
- 快速 LT fountain 流、逐帧 CRC32 和文件完整性校验。
- 发送与接收暂停、继续和重新开始。
- 接收完成后自动保存并显示位置；支持打开、分享、另存，桌面端支持在文件管理器中定位。
- 本地传输历史，以及从历史记录再次打开已保存文件的操作。
- 九种 App 内语言：简体中文、繁體中文、英语、日语、韩语、西班牙语、法语、德语和葡萄牙语。
  首次启动自动检测系统语言，也可在设置中手动切换。
- 新 OneSend 图标、设置/关于页面，以及 GitHub、MIT、MakerJackie、01MVP 信息。

### 内置测试片

项目内置原创的 10 秒、28,552 bytes、H.264/AAC 测试片，用来重复验证文件传输。它不是
Rickroll，也不是商业 MV；素材由项目生成，没有下载的影片或歌曲，可以随 MIT 项目再分发。
其中的 AAC 音轨只是测试文件的一部分，不代表已经实现独立的音频传输。

### 权限与联网

- 移动端只申请 CAMERA，不声明或请求互联网、局域网、蓝牙、麦克风、照片或定位权限。
  启动时绝不构造或运行 HTTP updater。
- 桌面端的自动更新会联网，但只访问官方签名更新源和签名安装包。文件传输本身永远不联网。

### 下载

- [GitHub Releases / latest](https://github.com/makerjackie/onesend/releases/latest)
- [iOS TestFlight 公测](https://testflight.apple.com/join/n2t1KrCp)

v1.4.0 不宣称新的视觉算法，也不宣称音频传输已经实现；它保持持续二维码的纯视觉文件
传输定位。

## English

OneSend (扫传) 1.4.0 is an experimental purely visual file-transfer release for phones and
computers. The sender displays a file as continuously changing QR codes; the receiver scans
the stream with a camera and reconstructs the file locally. File transfer needs no network,
account, server, or device pairing.

### Included in this release

- Any file up to 64 MB per file.
- Fast mode by default at about 33 KB/s theoretical useful throughput; Settings can switch
  the default to Compatible/Reliable mode at about 4.7 KB/s.
- The main sending screen does not let users choose a mode and does not show FPS; mode choice
  exists only as a default in Settings.
- A Fast LT fountain stream, per-frame CRC32, and file-integrity verification.
- Pause, resume, and restart for sending and receiving.
- Automatic saving with the saved location shown after reception; open, share, and save-as,
  plus desktop file-manager reveal.
- Local transfer history, including the ability to reopen saved received files from history.
- Nine in-app languages: Simplified Chinese, Traditional Chinese, English, Japanese, Korean,
  Spanish, French, German, and Portuguese. The app detects the system language on first launch
  and also supports manual switching in Settings.
- A new OneSend icon, Settings/About pages, and GitHub, MIT, MakerJackie, and 01MVP information.

### Included test clip

The project includes an original 10-second, 28,552-byte H.264/AAC test clip for repeatable
file-transfer verification. It is not Rickroll or a commercial music video; it is generated
project material with no downloaded footage or song and may be redistributed with the MIT
project. Its AAC track is simply part of the test file and does not represent an implemented
standalone audio-transfer feature.

### Permissions and network

- Mobile builds request only CAMERA and do not declare or request Internet, local-network,
  Bluetooth, microphone, photo-library, or location permissions. Startup never constructs or
  runs an HTTP updater.
- Desktop automatic updates use the network only for the official signed update source and
  signed packages. File transfer itself never uses the network.

### Downloads

- [GitHub Releases / latest](https://github.com/makerjackie/onesend/releases/latest)
- [iOS TestFlight public beta](https://testflight.apple.com/join/n2t1KrCp)

Version 1.4.0 does not claim a new visual algorithm or implemented audio transfer; it retains
the purely visual continuous-QR file-transfer position. Released 2026-08-03.

## Verification / 验证

Run the repository's existing commands from the root:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

For the release checklist, see [`docs/ios-release.md`](ios-release.md) and
[`docs/desktop-updates.md`](desktop-updates.md). The full privacy boundary is in
[`PRIVACY.md`](../PRIVACY.md).
