# OneSend 1.5.4

## 中文

- 彩色视觉码发送改为单一稳定帧时钟，并提高网页码图清晰度，减少相机捕获过渡帧造成的有效吞吐损失。
- 彩色接收进度只保留一条且不会倒退，同时在接收过程中显示真实已解码数据速度。
- iOS 彩色接收改为完全离线加载内置 WASM 与 worker，不再启动本地 HTTP 服务或触发本地网络访问。
- 增加离线资源完整性、帧调度、进度稳定性与 iOS 18.5 / 26.5 模拟器回归测试。

## English

- Stabilized color-code sending on one frame clock and increased web code clarity to reduce effective throughput loss from transition frames.
- Made color reception use one monotonic progress bar with live decoded-data speed.
- Moved iOS color reception to fully bundled offline WASM and workers, with no local HTTP server or local-network access.
- Added offline-integrity, frame-scheduling, progress-stability, and iOS 18.5/26.5 simulator regression coverage.
