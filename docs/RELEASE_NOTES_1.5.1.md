# OneSend 1.5.1 (build 20) Release Notes / 发布说明

## 中文

OneSend（扫传）1.5.1（build 20）是一版面向全端一致性、传输稳定性和接收完成流程的维护更新。它仍是实验性版本；本说明不把协议估算、上游参考基准或自动化结果表述为 OneSend 真机光学速度。

### 品牌与官网

- 官网以及 Android、iOS、macOS、Windows、Linux 全端统一使用官方黑底白色光学标识。
- 增加品牌资源防漂移检查，帮助发现官网和各端资源再次分叉。
- 简化官网结构与视觉呈现，并抽取共享品牌组件，让官网页面使用同一套品牌表达。

### 四种模式与稳定性

本版本围绕四种传输模式做稳定性工作：

- **可靠 QR**：保留兼容性和更高冗余的边界。
- **快速 QR**：在没有用户偏好时仍是稳定默认模式。
- **Turbo QR**：高密度二维码实验模式，只在用户显式选择后启用。
- **CIMBAR 彩色视觉码**：实验性的 Mode B 彩色视觉码，只在用户显式选择后启用。

快速 QR 的默认地位不会被实验模式悄悄替换；Turbo QR 和 CIMBAR 也不因安装或升级自动成为默认。模式选择仍是明确的传输配置边界。

### 接收与桌面文件选择

- 修复桌面端选择任意文件时的 `Invalid argument: object is unsendable` 错误。
- QR 接收在校验通过后真实写入本地磁盘，而不是只保留在内存状态。
- 如果保存/落盘失败，可以直接重试，不需要重新扫描整段传输。
- 保存成功后显示保存位置，并提供打开、分享和另存为操作。

### 权限、更新与发布状态

- 移动端只申请必要的 CAMERA 权限；文件传输不增加互联网、局域网、麦克风、照片、蓝牙或定位权限。
- 桌面自动更新的网络访问边界保持不变；文件传输本身不因本版本改为联网传输。
- 本说明不宣称 TestFlight 公测已开放，也不宣称 Beta App Review 或其他审核已经完成；相关状态请以 App Store Connect 为准。

## English

OneSend 1.5.1 (build 20) is a cross-platform maintenance release focused on consistent branding, transfer stability, and the post-reception save flow. It remains experimental. This document does not turn protocol estimates, upstream reference figures, or automated results into measured OneSend camera throughput.

### Brand and website

- The website and Android, iOS, macOS, Windows, and Linux targets now use the official white optical mark on a black background consistently.
- Added a brand-asset drift check to detect future divergence between website and platform assets.
- Simplified the website structure and presentation, and extracted shared brand components so its pages use one consistent brand expression.

### Four modes and stability

This release includes stability work across four transfer modes:

- **Reliable QR**: retains the compatibility and higher-redundancy boundary.
- **Fast QR**: remains the stable default when no user preference is set.
- **Turbo QR**: an experimental dense-QR mode enabled only through explicit user selection.
- **CIMBAR color visual code**: an experimental Mode B color-code mode enabled only through explicit user selection.

Fast QR is not silently replaced by an experimental mode on install or upgrade. Turbo QR and CIMBAR do not become defaults automatically; mode choice remains an explicit transfer-configuration boundary.

### Reception and desktop file selection

- Fixed desktop selection of arbitrary files failing with `Invalid argument: object is unsendable`.
- QR reception now writes the verified file to local disk instead of leaving it only in transient in-memory state.
- If saving to disk fails, the user can retry without rescanning the transfer.
- After a successful save, the app shows the saved location and provides open, share, and save-as actions.

### Permissions, updates, and release status

- Mobile builds request only the necessary CAMERA permission; file transfer adds no Internet, local-network, microphone, photo-library, Bluetooth, or location permission.
- Desktop automatic-update network boundaries are unchanged; this release does not turn file transfer into a network transfer.
- These notes do not claim that a TestFlight public beta is available or that Beta App Review or any other review is complete; check App Store Connect for the current status.
