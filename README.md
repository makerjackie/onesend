# OneSend · 一传

OneSend 是一个极简、离线优先的跨设备文件传输工具。发送端把文件编码成
持续变化的二维码，接收端只用摄像头连续扫描并在本地还原文件。

不需要局域网、服务器、账号或设备配对。只需要一块屏幕和一枚摄像头。

> Offline-first file transfer over animated QR codes, built with Flutter.

[下载最新版](https://github.com/makerjackie/onesend/releases/latest) ·
[产品网站](https://onesend.01mvp.com) ·
[隐私说明](PRIVACY.md)

## 功能

- Android、iOS、macOS、Windows、Linux 共用一套 Flutter 工程
- 连续二维码播放和摄像头扫描，支持中途加入、漏扫、乱序和重复帧
- “可靠”与“快速”两档传输配置
- 发送与接收都可暂停、继续和重新开始，恢复时保留当前内存进度
- 逐帧 CRC32、完整载荷 CRC32、文件原文/压缩数据双重 CRC32
- 文本等可压缩内容自动 gzip；已压缩媒体不会重复压缩
- 接收文件保存在本机，可直接打开、系统分享，并从最近记录再次打开
- 兼容 OneSend 1.0 / decimen 风格的协议 v1 接收流
- 无账号、无分析 SDK、无广告、无云端上传

## 两档配置

| 配置 | 二维码 | 速度 | 适合场景 |
| --- | --- | --- | --- |
| 可靠（默认） | 中等级纠错，720 B/帧 | 约 8 fps | 手持扫描、普通屏幕、轻微反光或抖动 |
| 快速 | 低等级纠错，1320 B/帧 | 约 15 fps | 两台设备固定、屏幕明亮且摄像头对焦稳定 |

两档都采用“4 个原始块 + 1 个修复块”的交织流。原始块会循环播放，修复块
使用确定性的 LT fountain code，因此接收端不必从第一帧开始，也不需要网络
回传缺失序号。

实际速度受摄像头帧率、快门、屏幕刷新率、二维码显示尺寸、环境光和对焦影响。
光传更适合文档、照片、短视频和小型压缩包；单文件上限为 64 MB。

## 使用方式

1. 在发送设备点击“发送文件”，选择可靠或快速模式，再选择文件。
2. 在另一台设备点击“扫描接收”并授权摄像头。
3. 让二维码完整进入扫描框，保持稳定，直到接收端显示“接收完成”。
4. 打开、分享文件，或继续接收下一份文件。

发送端无法通过纯光学单向通道知道接收端是否完成，因此二维码会持续循环，
直到用户点击“结束传输”。接收端暂停后会保留已经解出的块，继续扫描即可恢复。

## 协议与可靠性

OneSend 协议 v2 使用原始二进制 QR payload：

- 28 字节 little-endian 帧头：版本、模式、32 位会话、序号、块参数、总长度和载荷 CRC32
- 每帧尾部附加 CRC32，受损帧在进入 fountain decoder 前即被丢弃
- 系统原始块和 LT 修复块交织；会话一旦锁定，其他二维码不会重置当前进度
- 文件 envelope 保存经过清理的文件名、MIME、压缩标志、原始与存储长度及 CRC32
- 接收端限制块大小、块数量和总载荷，避免异常二维码触发无界内存分配

测试覆盖协议 v1/v2、压缩与损坏拒绝、迟到接入、随机丢帧、位翻转、重复、乱序、
会话隔离、两档 QR 容量，以及 Flutter UI。GitHub Release 只有在静态分析和完整测试
通过后才会构建，并附带 `SHA256SUMS.txt`。macOS 的最终 ZIP/DMG 使用 Developer ID、
hardened runtime 与 Apple Notary Service，并在发布前执行 Gatekeeper 验证。

## 安全与隐私边界

OneSend 不通过网络发送文件，也不收集相机画面或文件内容。它不是加密工具：能看到
完整二维码流的人或摄像头也可能重建文件。传输敏感资料时，请控制屏幕与摄像头的
物理可见范围，或先使用你信任的加密压缩工具。

## 开发

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos
```

推送版本 tag 会触发 Android、macOS、Windows、Linux 构建并创建 GitHub Release：

```bash
git tag v1.1.0
git push origin v1.1.0
```

iOS 签名、TestFlight 和 Beta App Review 流程见
[`docs/ios-release.md`](docs/ios-release.md)。

## 开源与致谢

OneSend 使用 [MIT License](LICENSE)。协议 v1 与 LT 基础工作参考了 MIT 授权的
[`decimen-optical-transfer`](https://github.com/bashalarmistalt/decimen-optical-transfer)。
设计 v2 时也评估了
[`deedy/qr-data-transfer`](https://github.com/deedy/qr-data-transfer) 的公开架构；
由于该仓库当时未声明许可证，OneSend 没有复制其代码或资源。

完整第三方声明见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。
