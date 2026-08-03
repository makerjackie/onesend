# OneSend Privacy Notice / OneSend 隐私说明

Last updated / 最后更新: 2026-08-03

## 中文

OneSend（扫传）通过屏幕上持续变化的二维码和另一台设备的摄像头进行纯视觉、
离线优先的文件传输。文件传输本身不经过互联网、局域网或服务器。

### 在你的设备上处理的数据

- 你选择发送的文件会在本机读取，并在本机编码为二维码帧。
- 接收端的摄像头画面只在本机用于扫描和校验二维码，不会上传相机画面。
- 接收完成并通过 CRC/完整性校验后，文件会自动保存到本机的 OneSend 接收目录，
  应用会显示保存位置，并提供打开、分享、另存和桌面端文件管理器定位操作。
- 最近传输历史（文件名、大小、方向、状态、时间和本地路径）保存在设备本地，
  用于历史页面和历史操作。清除历史只清除记录，不删除已经保存的文件。

### 移动端权限

Android / iOS 移动端只向用户申请 CAMERA，且只在接收文件时需要。移动端不声明或
请求互联网、局域网、蓝牙、麦克风、照片或定位权限。应用启动时绝不构造或运行 HTTP
updater；文件选择使用系统文件选择器，接收文件使用应用本地目录。

### 桌面端更新

macOS、Windows 和 Linux 桌面版因自动更新功能可能联网，但更新只访问官方签名更新源
（当前为 <https://onesend.01mvp.com/updates/>）及其签名安装包。更新服务不会读取或发送
待传输文件、文件历史或摄像头画面；文件传输本身永远不联网。你可以关闭自动检查，更新
服务不可用也不应阻断光传。

### 我们不收集的数据

OneSend 不包含账号系统、分析服务、广告 SDK、云端存储、远程文件上传或网络文件传输
服务。MakerJackie 不会通过 OneSend 接收你的文件内容、二维码流或摄像头画面。

### 安全边界

OneSend 不是加密工具。能看到完整二维码流的人或摄像头可能重建文件；传输敏感资料时，
请控制屏幕与摄像头的物理可见范围，或先使用你信任的加密工具。内置的 H.264/AAC 测试片
只是可随 MIT 项目再分发的原创普通文件，不是音频传输功能，也不是 Rickroll 或商业 MV。

### 联系

隐私问题请在项目的 [GitHub repository](https://github.com/makerjackie/onesend) 中提交 issue。

## English

OneSend (扫传) performs purely visual, offline-first file transfer through continuously
changing QR codes on a screen and a camera on another device. The file-transfer path itself
does not use the Internet, a local network, or a server.

### Data processed on your devices

- A file you choose to send is read locally and encoded into QR frames locally.
- The receiving camera view is processed locally to scan and verify QR frames; camera frames
  are not uploaded.
- After reception and CRC/integrity verification, the file is saved automatically in the
  local OneSend received directory. OneSend shows the saved location and provides open,
  share, save-as, and desktop file-manager reveal actions.
- Recent transfer history (file name, size, direction, status, time, and local path) is kept
  on the device for the history screen and its actions. Clearing history removes only those
  records; it does not delete saved files.

### Mobile permissions

On Android and iOS, the only user-facing permission OneSend requests is CAMERA, and it is
needed only when receiving. Mobile builds do not declare or request Internet, local-network,
Bluetooth, microphone, photo-library, or location permissions. Startup never constructs or
runs an HTTP updater. File selection uses the system file picker, and received files use the
app's local directory.

### Desktop updates

The macOS, Windows, and Linux desktop builds may use the network for automatic updates, but
only to the official signed update source (currently
<https://onesend.01mvp.com/updates/>) and its signed packages. The updater does not read or
send files being transferred, transfer history, or camera frames. File transfer itself never
uses the network. Automatic checks can be disabled, and an unavailable updater must not block
optical transfer.

### Data we do not collect

OneSend has no account system, analytics service, advertising SDK, cloud storage, remote file
upload, or network file-transfer service. MakerJackie does not receive your file contents, QR
stream, or camera frames through OneSend.

### Security boundary

OneSend is not an encryption tool. Anyone who can see the complete QR stream may be able to
reconstruct the file. Limit the physical visibility of the screen and camera, or encrypt
sensitive material with a tool you trust first. The included H.264/AAC test clip is an
original ordinary file that may be redistributed with the MIT project; it is not an audio-
transfer feature, Rickroll, or a commercial music video.

### Contact

For privacy questions, open an issue in the project's
[GitHub repository](https://github.com/makerjackie/onesend).
