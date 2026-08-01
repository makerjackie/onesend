# OneSend · 一传

OneSend 是一个极简的跨设备文件传输工具：发送端把文件编码成持续变化的二维码，接收端用摄像头连续扫描并在本地还原文件。

它不需要局域网、服务器、账号或设备配对。只需要一块正在显示二维码的屏幕，以及另一台设备的摄像头。

> OneSend is a private, offline-first file transfer app over animated QR codes.

## 当前版本

- Flutter 全端工程：Android、iOS、macOS、Windows、Linux
- 文件选择、二维码连续播放、摄像头连续扫描
- Fountain / LT 冗余编码：允许漏扫、乱序和重复帧
- FNV-1a 完整性校验与文件元数据封装
- 发送端和接收端都支持暂停、继续、重新开始
- 接收文件保存到本地并支持系统分享
- 最近传输记录保存在本机，不上传文件内容
- 单文件上限：64 MB（接收端仍会校验协议上限）

## 使用方式

1. 在发送设备打开 OneSend，点击“发送文件”。
2. 在接收设备点击“扫描接收”，授权摄像头。
3. 让接收设备对准发送端二维码区域，保持稳定直到完成。
4. 接收完成后，文件会保存到应用的 OneSend/Received 目录，也可以直接分享。

发送端可以暂停二维码播放；接收端可以暂停扫描，恢复后会继续使用已收到的帧。两台设备不需要在同一个网络中。

## 技术实现

协议与核心思路参考 [decimen-optical-transfer](https://github.com/bashalarmistalt/decimen-optical-transfer/)，OneSend 使用 Dart/Flutter 重新实现为移动端和桌面端应用：

- 20 字节 little-endian 帧头：magic、会话、序号、块参数、总长度和哈希
- Robust Soliton Distribution + LT fountain code
- `qr` 生成支持二进制 payload 的二维码
- Android/iOS/macOS 使用 `mobile_scanner` 获取二维码原始字节
- Windows/Linux/macOS 使用 `camera_desktop` 拍照，并用 `flutter_zxing` 解码

光传适合文档、图片、短视频和小型压缩包。二维码传输带宽受屏幕、摄像头、环境光和对焦影响，大文件通常需要更长时间。

## 开发

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

桌面 Linux 构建需要 GStreamer 开发库；详见 [`camera_desktop` 的平台说明](https://pub.dev/packages/camera_desktop)。

## 发布

推送一个版本 tag 会触发 GitHub Actions 构建 Android APK、macOS ZIP、Windows ZIP 和 Linux TAR.GZ，并创建 GitHub Release：

```bash
git tag v1.0.0
git push origin v1.0.0
```

iOS 需要在 Apple Developer / App Store Connect 中配置签名后，通过 CI 或 Xcode 上传 TestFlight。仓库中的 [`docs/ios-release.md`](docs/ios-release.md) 记录了完整步骤。

## 隐私

OneSend 不包含网络传输服务，也不收集文件内容。摄像头只用于扫描二维码。完整说明见 [`PRIVACY.md`](PRIVACY.md)。

## 许可证

MIT，见 [`LICENSE`](LICENSE)。
