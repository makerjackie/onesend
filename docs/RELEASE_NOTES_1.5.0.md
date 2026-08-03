# OneSend 1.5.0 Release Notes / 发布说明

## 中文

OneSend（扫传）1.5.0 在保持稳定 QR Fast 默认体验的同时，加入两项可在“设置”中主动开启的实验算法。

- QR Fast：默认，协议估算有效吞吐约 33 KB/s。
- Turbo QR（实验）：协议估算约 56 KB/s；高密度码需要更好的对焦、曝光和设备稳定性。
- CIMBAR 彩色视觉码（实验）：Android/iOS App 和网站提供 Mode B。libcimbar 上游在特定设备上的持续参考约 106 KB/s；这不是 OneSend 真机实测保证。
- 可靠兼容：保留约 4.7 KB/s 的高冗余 QR 选项。

CIMBAR 文件使用 OneSend 版本化 CRC32 完整性信封。只有解码、长度和 CRC32 全部通过后才会保存；接收完成后可查看保存位置、打开、分享/转发或另存副本。移动端仍只申请摄像头权限，文件和相机画面不上传。

自动化验证包含二维码随机丢帧/损坏测试、原生 QR 编解码自检，以及真实 libcimbar WASM 编码→RGBA 帧→解码回环。WASM 回环没有经过摄像头，因此不作为物理光学速度数据。

下载：

- [GitHub Releases](https://github.com/makerjackie/onesend/releases/tag/v1.5.0)
- [iOS TestFlight](https://testflight.apple.com/join/n2t1KrCp)
- [网站 CIMBAR 实验](https://onesend.01mvp.com/cimbar)

### 开源说明

OneSend 自有代码继续使用 MIT 许可证。随应用分发、未经修改的 libcimbar v0.6.7c JS/WASM 文件继续适用 MPL-2.0；对应上游提交为 [`e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44`](https://github.com/sz3/libcimbar/tree/e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44)，完整源代码快照也随本 Release 以 `libcimbar-v0.6.7c-e5bebd0-source.tar.gz` 提供。

## English

OneSend 1.5.0 keeps stable QR Fast as the default and adds two experiments that users can explicitly enable in Settings.

- QR Fast: default, about 33 KB/s protocol-estimated useful throughput.
- Turbo QR (experimental): about 56 KB/s protocol-estimated throughput; its denser code requires better focus, exposure, and device stability.
- CIMBAR color visual code (experimental): Mode B in the Android/iOS app and on the website. The upstream libcimbar reference is about 106 KB/s on a specific setup; this is not a measured OneSend guarantee.
- Reliable compatibility: the high-redundancy QR option remains available at about 4.7 KB/s.

CIMBAR files use a versioned OneSend CRC32 integrity envelope. A file is saved only after decoding, length, and CRC32 checks succeed. After reception, users can see its saved location, open it, share/forward it, or save a copy. Mobile still requests camera permission only, and neither files nor camera frames are uploaded.

Automated validation covers randomized QR loss/corruption, the packaged native QR codec self-test, and a real libcimbar WASM encode→RGBA-frame→decode loopback. The WASM loopback does not use a camera and is not a physical optical speed result.

Downloads:

- [GitHub Releases](https://github.com/makerjackie/onesend/releases/tag/v1.5.0)
- [iOS TestFlight](https://testflight.apple.com/join/n2t1KrCp)
- [Website CIMBAR experiment](https://onesend.01mvp.com/cimbar)

### Open-source notice

OneSend's own code remains MIT-licensed. The unmodified libcimbar v0.6.7c JS/WASM files distributed with the app remain under MPL-2.0. Their immutable upstream revision is [`e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44`](https://github.com/sz3/libcimbar/tree/e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44), and this Release also includes the full `libcimbar-v0.6.7c-e5bebd0-source.tar.gz` source snapshot.
