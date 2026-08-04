# OneSend 1.5.2（build 21）发布说明

发布时间：2026-08-04 22:12（Asia/Shanghai）

## 中文

OneSend（扫传）1.5.2 是一版以扫码可靠性、极简收发路径和跨端一致性为重点的维护更新。

- 修复手机端识别二维码后接收进度不变化的问题，兼容 Android、iOS 与 Apple Vision 的扫码字节格式。
- 官网拆分为首页、发送、接收和下载页面；手机首页与接收页固定在一个视口内。
- 手机 App 使用“传输 / 文件 / 设置”底部导航，并提供跟随系统、日间与夜间主题。
- 接收页固定显示取景框、进度、速度和主控制；完成后继续提供保存位置、打开、分享和保存副本。
- 增加 JavaScript ↔ Dart 双向协议回归，覆盖可靠、快速和 Turbo QR。
- Android、iOS、macOS、Windows、Linux 与网站统一使用新的“文件 + 扫描框 + 光线”标识。
- 用户界面显示 `1.5.2（2026-08-04 22:12）`，内部 build 21 不再暴露给用户。

OneSend 仍是实验性纯视觉传输工具。33 KB/s 与 56 KB/s 是 QR 协议估算，106 KB/s 是 libcimbar 上游参考，不是真机保证。

## English

OneSend 1.5.2 is a reliability and usability update for the minimal optical send/receive flow.

- Fixed recognized QR frames that did not advance reception by handling Android, iOS, and Apple Vision byte formats correctly.
- Split the website into focused home, send, receive, and download routes, with mobile home and receive fitting one viewport.
- Added Transfer, Files, and Settings bottom navigation plus system, light, and dark themes.
- Kept the receive camera, progress, rate, and main control together, with saved-location, open, share, and save-copy actions after completion.
- Added bidirectional JavaScript ↔ Dart interoperability regression coverage for Reliable, Fast, and Turbo QR.
- Unified the website and Android, iOS, macOS, Windows, and Linux on the new file, scanner-frame, and light-ray mark.
- The UI shows `1.5.2（2026-08-04 22:12）`; internal build 21 is not shown to users.

OneSend remains experimental. The 33 KB/s and 56 KB/s QR figures are protocol estimates, while 106 KB/s is an upstream libcimbar reference, not a measured-device guarantee.
