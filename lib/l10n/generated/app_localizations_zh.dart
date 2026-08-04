// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'OneSend · 扫传';

  @override
  String get followSystem => '跟随系统';

  @override
  String get language => '语言';

  @override
  String get modeFast => '快速';

  @override
  String get modeReliable => '可靠';

  @override
  String get modeTurboQr => 'Turbo QR';

  @override
  String get modeCimbar => '彩色视觉码';

  @override
  String get modeQr => '二维码';

  @override
  String get compatibilityMode => '兼容';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get close => '关闭';

  @override
  String get openFile => '打开';

  @override
  String get shareFile => '分享 / 转发';

  @override
  String get saveCopy => '保存副本';

  @override
  String get revealInFolder => '在文件夹中显示';

  @override
  String get more => '更多';

  @override
  String get settings => '设置';

  @override
  String get about => '关于 OneSend';

  @override
  String get transferTab => '传输';

  @override
  String get filesTab => '文件';

  @override
  String get filesTitle => '文件';

  @override
  String get filesSubtitle => '管理传输记录和已接收文件。';

  @override
  String get theme => '主题';

  @override
  String get themeSubtitle => '跟随系统、日间或夜间';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '日间';

  @override
  String get themeDark => '夜间';

  @override
  String get themeSaveError => '无法保存主题设置，请稍后重试。';

  @override
  String get aboutSubtitle => '查看版本、隐私与开源信息。';

  @override
  String get clearHistory => '清空记录';

  @override
  String get clearHistoryQuestion => '清空传输记录？';

  @override
  String get clearHistoryDescription => '只会清除 OneSend 里的记录，不会删除已经保存的文件。';

  @override
  String get clearAction => '清空';

  @override
  String get homeHeadline => '文件，\n用光传过去。';

  @override
  String get homeSubtitle => '无需网络，无需配对。\n只要一块屏幕和一枚摄像头。';

  @override
  String get sendEyebrow => '发送';

  @override
  String get receiveEyebrow => '接收';

  @override
  String get sendFile => '发送文件';

  @override
  String get receiveFile => '接收文件';

  @override
  String get sendCardDescription => '把视觉码放到屏幕上，让另一台设备对准它。';

  @override
  String get receiveCardDescription => '打开摄像头，持续扫描变化中的视觉码。';

  @override
  String get recentTransfers => '最近传输';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 条',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter => '屏幕 ↔ 摄像头 · 文件只在两台设备之间经过光传递';

  @override
  String get emptyHistory => '还没有传输记录。选一个文件，开始第一次光传。';

  @override
  String get receivedAndVerified => '收到并校验';

  @override
  String get sendEnded => '发送已结束';

  @override
  String get sent => '发出';

  @override
  String get receivedFileActions => '接收文件操作';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 分钟前',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 小时前',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 天前',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle => '应用设置';

  @override
  String get settingsIntroBody => '传输模式请在发送页选择。';

  @override
  String get transportSection => '传输';

  @override
  String get defaultTransferAlgorithm => '默认传输算法';

  @override
  String get algorithmDescription =>
      '可选择二维码配置或实验性的 CIMBAR 彩色视觉码。二维码接收模式会由每帧自描述。';

  @override
  String theoreticalSpeed(Object speed) {
    return '理论约 $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed；稳定快速，适合固定设备和明亮屏幕。';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed；可靠兼容，纠错余量更大，但传输更慢。';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed；实验性高容量二维码配置，扫描余量更小。';
  }

  @override
  String get cimbarModeDescription =>
      '上游基准约 106 KB/s；Android 和 iOS 上可用的实验性彩色视觉码。';

  @override
  String get modeSaveError => '无法保存默认传输设置，请稍后重试。';

  @override
  String get appSection => '应用';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => '自动更新';

  @override
  String get desktopUpdatesSubtitle => '桌面端检查更新与自动检查设置。';

  @override
  String get mobileOfflineNote => '移动端不提供更新网络功能；只保留传输与语言入口。';

  @override
  String get languagePickerTitle => '选择语言';

  @override
  String get languageSaveError => '无法保存语言设置，请稍后重试。';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode，$speed';
  }

  @override
  String get experimentalVisualTransfer => '实验性离线视觉传输';

  @override
  String get workingPrinciple => '工作原理';

  @override
  String get workingPrincipleBody =>
      '文件先被编码成连续变化的视觉码，由发送设备显示；接收设备用相机逐帧读取、校验，再还原成文件。整个过程只走屏幕与摄像头之间的短距离光路。';

  @override
  String get whyWeBuiltIt => '为什么做';

  @override
  String get whyWeBuiltItBody =>
      '让两台设备在没有网络、没有账号、没有配对的情况下，也能直接交换文件。OneSend 把设备已有的屏幕和相机，变成一条简单的离线通道。';

  @override
  String get privacy => '隐私说明';

  @override
  String get privacyBody => '传输不经网络或服务器；移动端只需要相机权限。';

  @override
  String get openSourceAndAuthor => '开源与作者';

  @override
  String get author => '作者';

  @override
  String get license => '许可';

  @override
  String get version => '版本';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => '打开 GitHub';

  @override
  String get opening => '打开中…';

  @override
  String get versionUnavailable => '版本号暂不可用';

  @override
  String get readingVersion => '读取版本…';

  @override
  String get cannotOpenGithub => '无法打开 GitHub 页面，请稍后重试。';

  @override
  String get aboutFooter => 'OneSend · 光传文件';

  @override
  String versionLabel(Object version) {
    return '版本 $version';
  }

  @override
  String get chooseAFile => '选一个文件';

  @override
  String sendFileDescription(Object maxSize) {
    return '文件会被编码成一串不断变化的视觉码。\n最大支持 $maxSize，建议从小文件开始体验。';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return '新传输默认使用$mode模式 · 理论码流约 $speed';
  }

  @override
  String get transferModeLabel => '传输模式';

  @override
  String get dropFilesHint => '也可以把文件拖到这里';

  @override
  String get dropFilesActive => '松手即可发送';

  @override
  String get reading => '读取中…';

  @override
  String get chooseFile => '选择文件';

  @override
  String get sampleVideo => '一键发送内置测试视频';

  @override
  String get encodedPayloadTooLarge => '文件编码后超过光传协议上限。';

  @override
  String modeBadge(Object mode) {
    return '$mode模式';
  }

  @override
  String get broadcasting => '正在持续播放视觉码';

  @override
  String get pausedPlayback => '已暂停播放';

  @override
  String get cameraAim => '请把另一台设备的摄像头对准这块白色区域';

  @override
  String passAndFrames(Object frames, Object pass) {
    return '第 $pass 轮 · 已发 $frames 帧';
  }

  @override
  String runningTime(Object duration) {
    return '运行 $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return '理论码流 $speed';
  }

  @override
  String currentRate(Object speed) {
    return '当前码流 $speed';
  }

  @override
  String get resume => '继续';

  @override
  String get pause => '暂停';

  @override
  String get endTransfer => '结束传输';

  @override
  String get sendAnother => '发送另一个文件';

  @override
  String get chooseOtherFile => '选择其他文件';

  @override
  String fileTooLarge(Object maxSize) {
    return '文件不能超过 $maxSize。';
  }

  @override
  String get cannotReadFile => 'OneSend 无法读取这个文件。';

  @override
  String get sampleVideoEmpty => 'OneSend 内置测试视频不可用。';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return '内置测试视频不能超过 $maxSize。';
  }

  @override
  String get genericTransferError => '传输无法开始，请重试。';

  @override
  String get scanReceive => '扫描接收';

  @override
  String get torch => '手电筒';

  @override
  String get checkingAndSaving => '正在校验并保存文件…';

  @override
  String get pausedKeepProgress => '已暂停，点击继续即可保留当前进度。';

  @override
  String get lookingForSender => '正在寻找发送端…';

  @override
  String lockedModeCollecting(Object mode) {
    return '已锁定$mode模式 · 正在收集视觉码';
  }

  @override
  String get scanInstruction => '把视觉码完整放进框内，保持设备稳定。';

  @override
  String get scannerBytesUnavailable => '识别到二维码，但相机未返回数据；正在继续扫描。';

  @override
  String get scannerInvalidFrame => '识别到的二维码不是 OneSend 数据；正在继续扫描。';

  @override
  String get desktopCameraInstruction => '桌面端使用摄像头截图解码，速度会比手机慢一些。';

  @override
  String get verifying => '校验中…';

  @override
  String get paused => '已暂停';

  @override
  String get waitingFirstFrame => '等待第一帧';

  @override
  String fountainProgress(Object frames) {
    return '$frames 帧 · Fountain 恢复中';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames 帧 · $solved/$blocks 块';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => '继续扫描';

  @override
  String get pauseScan => '暂停扫描';

  @override
  String get restart => '重新开始';

  @override
  String get receivedComplete => '接收完成';

  @override
  String get verifiedNotSaved => '文件已校验通过，但还没有保存成功。';

  @override
  String get verifiedSaved => '文件已校验通过，并保存到本机。';

  @override
  String get retrySave => '重试保存';

  @override
  String get continueReceiving => '继续接收';

  @override
  String recordWriteError(Object error) {
    return '文件已保存，但记录未写入：$error';
  }

  @override
  String saveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get fileActions => '文件操作';

  @override
  String get saveLocation => '保存位置';

  @override
  String get unrecordedLocation => '未记录保存路径。';

  @override
  String get fileMissing => '文件不存在，可能已被移动或删除。';

  @override
  String savedTo(Object path) {
    return '已保存到：$path';
  }

  @override
  String iosSavedLocation(Object name) {
    return '文件 App > 我的 iPhone/iPad > OneSend > Received > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return '已保存到应用存储：$name；点“保存副本”选择可见文件夹。';
  }

  @override
  String copyExported(Object name) {
    return '副本已导出：$name（位置由系统文件选择器决定）';
  }

  @override
  String copyExportedDesktop(Object path) {
    return '副本已导出到：$path';
  }

  @override
  String get fileOperationError => '文件操作失败，请重试。';

  @override
  String get fileNotFound => '文件不存在。';

  @override
  String get fileAccessDenied => '没有权限访问这个文件。';

  @override
  String get operationCancelled => '操作已取消。';

  @override
  String get unsupportedOperation => '当前设备不支持这个操作。';

  @override
  String get openFileError => '系统无法打开这个文件。';

  @override
  String get shareFileError => '无法分享这个文件，请重试。';

  @override
  String get revealFileError => '无法打开文件所在文件夹，请重试。';

  @override
  String get saveFileError => '无法导出文件，请重试。';

  @override
  String get locationPathUnknown => '保存位置未知。';

  @override
  String get updateAppDescription => '屏幕与摄像头之间的离线文件传输。';

  @override
  String get currentVersion => '当前版本';

  @override
  String get automaticChecks => '自动检查更新';

  @override
  String get automaticChecksSubtitle => '每天静默检查一次；发现新版本时再提示。';

  @override
  String get downloadPage => '下载页面';

  @override
  String get checking => '检查中…';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version 可用';
  }

  @override
  String get releaseNotes => '更新内容';

  @override
  String get downloading => '正在下载并校验…';

  @override
  String downloadingPercent(Object percent) {
    return '正在下载并校验 $percent%';
  }

  @override
  String get viewRelease => '查看发布页';

  @override
  String get later => '稍后';

  @override
  String get downloadUpdate => '下载更新';

  @override
  String get latestVersion => '已经是最新版本。';

  @override
  String get updateCheckWindowOpened => '更新检查窗口已打开。';

  @override
  String get unsupportedUpdate => '当前平台不支持应用内更新。';

  @override
  String get updateCheckFailed => '检查更新失败，请稍后重试。';

  @override
  String get automaticUpdateError => '无法修改自动更新设置。';

  @override
  String get downloadPageError => '无法打开下载页面。';

  @override
  String get releasePageError => '无法打开发布页面。';

  @override
  String get downloadError => '更新包下载失败，请稍后重试。';

  @override
  String get cimbarSendTitle => 'CIMBAR 高速发送';

  @override
  String get cimbarReceiveTitle => 'CIMBAR 高速接收';

  @override
  String get cimbarUnsupported => 'CIMBAR 实验性传输引擎仅支持 Android 和 iOS。';

  @override
  String get cimbarLoading => '正在加载实验引擎…';

  @override
  String get cimbarPageReadySend => '实验引擎已加载，请选择文件。';

  @override
  String get cimbarPageReadyReceive => '实验引擎已加载，点击开始后请求摄像头权限。';

  @override
  String get cimbarEngineReady => '实验引擎已就绪 · 模式 B';

  @override
  String get cimbarPreparingFile => '正在准备文件…';

  @override
  String get cimbarPaused => '已暂停播放';

  @override
  String get cimbarPlaying => '正在播放';

  @override
  String get cimbarBroadcasting => '文件已准备，正在播放视觉码';

  @override
  String get cimbarDecoderReady => '解码器已就绪，正在寻找 CIMBAR。';

  @override
  String get cimbarDecoderReadyStart => '解码器已就绪，点击开始后请求摄像头权限。';

  @override
  String get cimbarCameraStarted => '摄像头已启动，正在寻找 CIMBAR。';

  @override
  String get cimbarDecoding => '正在使用上游 worker 解码';

  @override
  String get cimbarFileHeaderReceived => '文件头已校验，正在接收分块。';

  @override
  String get cimbarReceiving => '正在接收已校验的字节';

  @override
  String get cimbarRecoveredSaving => '文件已完整恢复，正在保存…';

  @override
  String get cimbarRecoveredNotSaved => '文件已完整恢复，但尚未保存。';

  @override
  String get cimbarReceiveComplete => '接收完成';

  @override
  String get cimbarLoadFailed => '加载失败，请重试。';

  @override
  String get cimbarTransferFailed => 'CIMBAR 传输失败，请重试。';

  @override
  String get cimbarReloading => '正在重新加载实验引擎…';

  @override
  String get cimbarRequestingCamera => '正在请求摄像头权限…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return '文件：$name · $size';
  }

  @override
  String get cimbarSendRate => '上游参考：106 KB/s · 模式 B';

  @override
  String cimbarReceiveRate(Object speed) {
    return '上游参考：106 KB/s · 本次接收实测：$speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return '已恢复 $received / $expected · $seconds 秒';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return '已恢复 $received · $seconds 秒';
  }

  @override
  String get cimbarStartReceive => '开始接收（请求摄像头）';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return '移动端 CIMBAR 文件不能超过 $maxSize。';
  }

  @override
  String get cimbarPageLoadError => '无法加载离线 CIMBAR 页面，请重试。';

  @override
  String get cimbarBridgeError => 'CIMBAR 传输了无效事件，请重试。';

  @override
  String get cimbarEngineError => 'CIMBAR 引擎不可用，请重试。';

  @override
  String get cimbarCameraError => '摄像头访问或解码失败，请检查权限后重试。';

  @override
  String get cimbarSendError => 'CIMBAR 发送端无法准备文件，请重试。';

  @override
  String get cimbarReceiveError => 'CIMBAR 接收端无法解码文件，请重试。';

  @override
  String get cimbarVerificationError => '接收文件无法通过校验，请重试。';

  @override
  String get cimbarSaveError => '恢复的文件无法保存，请重试保存。';

  @override
  String get cimbarHistoryError => '文件已保存，但传输记录无法写入。';

  @override
  String get cimbarAllFiles => '所有文件';

  @override
  String get cimbarSelectedFileName => 'selected.bin';

  @override
  String get cimbarReceivedFileName => 'received.bin';

  @override
  String cimbarBytes(Object value) {
    return '$value B';
  }

  @override
  String cimbarKibibytes(Object value) {
    return '$value KiB';
  }

  @override
  String cimbarMebibytes(Object value) {
    return '$value MiB';
  }

  @override
  String durationHoursMinutes(Object hours, Object minutes) {
    return '$hours小时 $minutes分';
  }

  @override
  String durationMinutesSeconds(Object minutes, Object seconds) {
    return '$minutes:$seconds';
  }

  @override
  String errorDetails(Object message) {
    return '$message';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'OneSend · 扫传';

  @override
  String get followSystem => '跟随系统';

  @override
  String get language => '语言';

  @override
  String get modeFast => '快速';

  @override
  String get modeReliable => '可靠';

  @override
  String get modeTurboQr => 'Turbo QR';

  @override
  String get modeCimbar => '彩色视觉码';

  @override
  String get modeQr => '二维码';

  @override
  String get compatibilityMode => '兼容';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get close => '关闭';

  @override
  String get openFile => '打开';

  @override
  String get shareFile => '分享 / 转发';

  @override
  String get saveCopy => '保存副本';

  @override
  String get revealInFolder => '在文件夹中显示';

  @override
  String get more => '更多';

  @override
  String get settings => '设置';

  @override
  String get about => '关于 OneSend';

  @override
  String get transferTab => '传输';

  @override
  String get filesTab => '文件';

  @override
  String get filesTitle => '文件';

  @override
  String get filesSubtitle => '管理传输记录和已接收文件。';

  @override
  String get theme => '主题';

  @override
  String get themeSubtitle => '跟随系统、日间或夜间';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '日间';

  @override
  String get themeDark => '夜间';

  @override
  String get themeSaveError => '无法保存主题设置，请稍后重试。';

  @override
  String get aboutSubtitle => '查看版本、隐私与开源信息。';

  @override
  String get clearHistory => '清空记录';

  @override
  String get clearHistoryQuestion => '清空传输记录？';

  @override
  String get clearHistoryDescription => '只会清除 OneSend 里的记录，不会删除已经保存的文件。';

  @override
  String get clearAction => '清空';

  @override
  String get homeHeadline => '文件，\n用光传过去。';

  @override
  String get homeSubtitle => '无需网络，无需配对。\n只要一块屏幕和一枚摄像头。';

  @override
  String get sendEyebrow => '发送';

  @override
  String get receiveEyebrow => '接收';

  @override
  String get sendFile => '发送文件';

  @override
  String get receiveFile => '接收文件';

  @override
  String get sendCardDescription => '把视觉码放到屏幕上，让另一台设备对准它。';

  @override
  String get receiveCardDescription => '打开摄像头，持续扫描变化中的视觉码。';

  @override
  String get recentTransfers => '最近传输';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 条',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter => '屏幕 ↔ 摄像头 · 文件只在两台设备之间经过光传递';

  @override
  String get emptyHistory => '还没有传输记录。选一个文件，开始第一次光传。';

  @override
  String get receivedAndVerified => '收到并校验';

  @override
  String get sendEnded => '发送已结束';

  @override
  String get sent => '发出';

  @override
  String get receivedFileActions => '接收文件操作';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 分钟前',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 小时前',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 天前',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle => '应用设置';

  @override
  String get settingsIntroBody => '传输模式请在发送页选择。';

  @override
  String get transportSection => '传输';

  @override
  String get defaultTransferAlgorithm => '默认传输算法';

  @override
  String get algorithmDescription =>
      '可选择二维码配置或实验性的 CIMBAR 彩色视觉码。二维码接收模式会由每帧自描述。';

  @override
  String theoreticalSpeed(Object speed) {
    return '理论约 $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed；稳定快速，适合固定设备和明亮屏幕。';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed；可靠兼容，纠错余量更大，但传输更慢。';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed；实验性高容量二维码配置，扫描余量更小。';
  }

  @override
  String get cimbarModeDescription =>
      '上游基准约 106 KB/s；Android 和 iOS 上可用的实验性彩色视觉码。';

  @override
  String get modeSaveError => '无法保存默认传输设置，请稍后重试。';

  @override
  String get appSection => '应用';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => '自动更新';

  @override
  String get desktopUpdatesSubtitle => '桌面端检查更新与自动检查设置。';

  @override
  String get mobileOfflineNote => '移动端不提供更新网络功能；只保留传输与语言入口。';

  @override
  String get languagePickerTitle => '选择语言';

  @override
  String get languageSaveError => '无法保存语言设置，请稍后重试。';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode，$speed';
  }

  @override
  String get experimentalVisualTransfer => '实验性离线视觉传输';

  @override
  String get workingPrinciple => '工作原理';

  @override
  String get workingPrincipleBody =>
      '文件先被编码成连续变化的视觉码，由发送设备显示；接收设备用相机逐帧读取、校验，再还原成文件。整个过程只走屏幕与摄像头之间的短距离光路。';

  @override
  String get whyWeBuiltIt => '为什么做';

  @override
  String get whyWeBuiltItBody =>
      '让两台设备在没有网络、没有账号、没有配对的情况下，也能直接交换文件。OneSend 把设备已有的屏幕和相机，变成一条简单的离线通道。';

  @override
  String get privacy => '隐私说明';

  @override
  String get privacyBody => '传输不经网络或服务器；移动端只需要相机权限。';

  @override
  String get openSourceAndAuthor => '开源与作者';

  @override
  String get author => '作者';

  @override
  String get license => '许可';

  @override
  String get version => '版本';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => '打开 GitHub';

  @override
  String get opening => '打开中…';

  @override
  String get versionUnavailable => '版本号暂不可用';

  @override
  String get readingVersion => '读取版本…';

  @override
  String get cannotOpenGithub => '无法打开 GitHub 页面，请稍后重试。';

  @override
  String get aboutFooter => 'OneSend · 光传文件';

  @override
  String versionLabel(Object version) {
    return '版本 $version';
  }

  @override
  String get chooseAFile => '选一个文件';

  @override
  String sendFileDescription(Object maxSize) {
    return '文件会被编码成一串不断变化的视觉码。\n最大支持 $maxSize，建议从小文件开始体验。';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return '新传输默认使用$mode模式 · 理论码流约 $speed';
  }

  @override
  String get transferModeLabel => '传输模式';

  @override
  String get dropFilesHint => '也可以把文件拖到这里';

  @override
  String get dropFilesActive => '松手即可发送';

  @override
  String get reading => '读取中…';

  @override
  String get chooseFile => '选择文件';

  @override
  String get sampleVideo => '一键发送内置测试视频';

  @override
  String get encodedPayloadTooLarge => '文件编码后超过光传协议上限。';

  @override
  String modeBadge(Object mode) {
    return '$mode模式';
  }

  @override
  String get broadcasting => '正在持续播放视觉码';

  @override
  String get pausedPlayback => '已暂停播放';

  @override
  String get cameraAim => '请把另一台设备的摄像头对准这块白色区域';

  @override
  String passAndFrames(Object frames, Object pass) {
    return '第 $pass 轮 · 已发 $frames 帧';
  }

  @override
  String runningTime(Object duration) {
    return '运行 $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return '理论码流 $speed';
  }

  @override
  String currentRate(Object speed) {
    return '当前码流 $speed';
  }

  @override
  String get resume => '继续';

  @override
  String get pause => '暂停';

  @override
  String get endTransfer => '结束传输';

  @override
  String get sendAnother => '发送另一个文件';

  @override
  String get chooseOtherFile => '选择其他文件';

  @override
  String fileTooLarge(Object maxSize) {
    return '文件不能超过 $maxSize。';
  }

  @override
  String get cannotReadFile => 'OneSend 无法读取这个文件。';

  @override
  String get sampleVideoEmpty => 'OneSend 内置测试视频不可用。';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return '内置测试视频不能超过 $maxSize。';
  }

  @override
  String get genericTransferError => '传输无法开始，请重试。';

  @override
  String get scanReceive => '扫描接收';

  @override
  String get torch => '手电筒';

  @override
  String get checkingAndSaving => '正在校验并保存文件…';

  @override
  String get pausedKeepProgress => '已暂停，点击继续即可保留当前进度。';

  @override
  String get lookingForSender => '正在寻找发送端…';

  @override
  String lockedModeCollecting(Object mode) {
    return '已锁定$mode模式 · 正在收集视觉码';
  }

  @override
  String get scanInstruction => '把视觉码完整放进框内，保持设备稳定。';

  @override
  String get scannerBytesUnavailable => '识别到二维码，但相机未返回数据；正在继续扫描。';

  @override
  String get scannerInvalidFrame => '识别到的二维码不是 OneSend 数据；正在继续扫描。';

  @override
  String get desktopCameraInstruction => '桌面端使用摄像头截图解码，速度会比手机慢一些。';

  @override
  String get verifying => '校验中…';

  @override
  String get paused => '已暂停';

  @override
  String get waitingFirstFrame => '等待第一帧';

  @override
  String fountainProgress(Object frames) {
    return '$frames 帧 · Fountain 恢复中';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames 帧 · $solved/$blocks 块';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => '继续扫描';

  @override
  String get pauseScan => '暂停扫描';

  @override
  String get restart => '重新开始';

  @override
  String get receivedComplete => '接收完成';

  @override
  String get verifiedNotSaved => '文件已校验通过，但还没有保存成功。';

  @override
  String get verifiedSaved => '文件已校验通过，并保存到本机。';

  @override
  String get retrySave => '重试保存';

  @override
  String get continueReceiving => '继续接收';

  @override
  String recordWriteError(Object error) {
    return '文件已保存，但记录未写入：$error';
  }

  @override
  String saveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get fileActions => '文件操作';

  @override
  String get saveLocation => '保存位置';

  @override
  String get unrecordedLocation => '未记录保存路径。';

  @override
  String get fileMissing => '文件不存在，可能已被移动或删除。';

  @override
  String savedTo(Object path) {
    return '已保存到：$path';
  }

  @override
  String iosSavedLocation(Object name) {
    return '文件 App > 我的 iPhone/iPad > OneSend > Received > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return '已保存到应用存储：$name；点“保存副本”选择可见文件夹。';
  }

  @override
  String copyExported(Object name) {
    return '副本已导出：$name（位置由系统文件选择器决定）';
  }

  @override
  String copyExportedDesktop(Object path) {
    return '副本已导出到：$path';
  }

  @override
  String get fileOperationError => '文件操作失败，请重试。';

  @override
  String get fileNotFound => '文件不存在。';

  @override
  String get fileAccessDenied => '没有权限访问这个文件。';

  @override
  String get operationCancelled => '操作已取消。';

  @override
  String get unsupportedOperation => '当前设备不支持这个操作。';

  @override
  String get openFileError => '系统无法打开这个文件。';

  @override
  String get shareFileError => '无法分享这个文件，请重试。';

  @override
  String get revealFileError => '无法打开文件所在文件夹，请重试。';

  @override
  String get saveFileError => '无法导出文件，请重试。';

  @override
  String get locationPathUnknown => '保存位置未知。';

  @override
  String get updateAppDescription => '屏幕与摄像头之间的离线文件传输。';

  @override
  String get currentVersion => '当前版本';

  @override
  String get automaticChecks => '自动检查更新';

  @override
  String get automaticChecksSubtitle => '每天静默检查一次；发现新版本时再提示。';

  @override
  String get downloadPage => '下载页面';

  @override
  String get checking => '检查中…';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version 可用';
  }

  @override
  String get releaseNotes => '更新内容';

  @override
  String get downloading => '正在下载并校验…';

  @override
  String downloadingPercent(Object percent) {
    return '正在下载并校验 $percent%';
  }

  @override
  String get viewRelease => '查看发布页';

  @override
  String get later => '稍后';

  @override
  String get downloadUpdate => '下载更新';

  @override
  String get latestVersion => '已经是最新版本。';

  @override
  String get updateCheckWindowOpened => '更新检查窗口已打开。';

  @override
  String get unsupportedUpdate => '当前平台不支持应用内更新。';

  @override
  String get updateCheckFailed => '检查更新失败，请稍后重试。';

  @override
  String get automaticUpdateError => '无法修改自动更新设置。';

  @override
  String get downloadPageError => '无法打开下载页面。';

  @override
  String get releasePageError => '无法打开发布页面。';

  @override
  String get downloadError => '更新包下载失败，请稍后重试。';

  @override
  String get cimbarSendTitle => 'CIMBAR 高速发送';

  @override
  String get cimbarReceiveTitle => 'CIMBAR 高速接收';

  @override
  String get cimbarUnsupported => 'CIMBAR 实验性传输引擎仅支持 Android 和 iOS。';

  @override
  String get cimbarLoading => '正在加载实验引擎…';

  @override
  String get cimbarPageReadySend => '实验引擎已加载，请选择文件。';

  @override
  String get cimbarPageReadyReceive => '实验引擎已加载，点击开始后请求摄像头权限。';

  @override
  String get cimbarEngineReady => '实验引擎已就绪 · 模式 B';

  @override
  String get cimbarPreparingFile => '正在准备文件…';

  @override
  String get cimbarPaused => '已暂停播放';

  @override
  String get cimbarPlaying => '正在播放';

  @override
  String get cimbarBroadcasting => '文件已准备，正在播放视觉码';

  @override
  String get cimbarDecoderReady => '解码器已就绪，正在寻找 CIMBAR。';

  @override
  String get cimbarDecoderReadyStart => '解码器已就绪，点击开始后请求摄像头权限。';

  @override
  String get cimbarCameraStarted => '摄像头已启动，正在寻找 CIMBAR。';

  @override
  String get cimbarDecoding => '正在使用上游 worker 解码';

  @override
  String get cimbarFileHeaderReceived => '文件头已校验，正在接收分块。';

  @override
  String get cimbarReceiving => '正在接收已校验的字节';

  @override
  String get cimbarRecoveredSaving => '文件已完整恢复，正在保存…';

  @override
  String get cimbarRecoveredNotSaved => '文件已完整恢复，但尚未保存。';

  @override
  String get cimbarReceiveComplete => '接收完成';

  @override
  String get cimbarLoadFailed => '加载失败，请重试。';

  @override
  String get cimbarTransferFailed => 'CIMBAR 传输失败，请重试。';

  @override
  String get cimbarReloading => '正在重新加载实验引擎…';

  @override
  String get cimbarRequestingCamera => '正在请求摄像头权限…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return '文件：$name · $size';
  }

  @override
  String get cimbarSendRate => '上游参考：106 KB/s · 模式 B';

  @override
  String cimbarReceiveRate(Object speed) {
    return '上游参考：106 KB/s · 本次接收实测：$speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return '已恢复 $received / $expected · $seconds 秒';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return '已恢复 $received · $seconds 秒';
  }

  @override
  String get cimbarStartReceive => '开始接收（请求摄像头）';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return '移动端 CIMBAR 文件不能超过 $maxSize。';
  }

  @override
  String get cimbarPageLoadError => '无法加载离线 CIMBAR 页面，请重试。';

  @override
  String get cimbarBridgeError => 'CIMBAR 传输了无效事件，请重试。';

  @override
  String get cimbarEngineError => 'CIMBAR 引擎不可用，请重试。';

  @override
  String get cimbarCameraError => '摄像头访问或解码失败，请检查权限后重试。';

  @override
  String get cimbarSendError => 'CIMBAR 发送端无法准备文件，请重试。';

  @override
  String get cimbarReceiveError => 'CIMBAR 接收端无法解码文件，请重试。';

  @override
  String get cimbarVerificationError => '接收文件无法通过校验，请重试。';

  @override
  String get cimbarSaveError => '恢复的文件无法保存，请重试保存。';

  @override
  String get cimbarHistoryError => '文件已保存，但传输记录无法写入。';

  @override
  String get cimbarAllFiles => '所有文件';

  @override
  String get cimbarSelectedFileName => 'selected.bin';

  @override
  String get cimbarReceivedFileName => 'received.bin';

  @override
  String cimbarBytes(Object value) {
    return '$value B';
  }

  @override
  String cimbarKibibytes(Object value) {
    return '$value KiB';
  }

  @override
  String cimbarMebibytes(Object value) {
    return '$value MiB';
  }

  @override
  String durationHoursMinutes(Object hours, Object minutes) {
    return '$hours小时 $minutes分';
  }

  @override
  String durationMinutesSeconds(Object minutes, Object seconds) {
    return '$minutes:$seconds';
  }

  @override
  String errorDetails(Object message) {
    return '$message';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'OneSend · 掃傳';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get language => '語言';

  @override
  String get modeFast => '快速';

  @override
  String get modeReliable => '可靠';

  @override
  String get modeTurboQr => 'Turbo QR';

  @override
  String get modeCimbar => '彩色視覺碼';

  @override
  String get modeQr => '二維碼';

  @override
  String get compatibilityMode => '相容性';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get close => '關閉';

  @override
  String get openFile => '開啟';

  @override
  String get shareFile => '分享／轉寄';

  @override
  String get saveCopy => '儲存副本';

  @override
  String get revealInFolder => '在資料夾中顯示';

  @override
  String get more => '更多';

  @override
  String get settings => '設定';

  @override
  String get about => '關於 OneSend';

  @override
  String get transferTab => '傳輸';

  @override
  String get filesTab => '檔案';

  @override
  String get filesTitle => '檔案';

  @override
  String get filesSubtitle => '管理傳輸記錄與已接收檔案。';

  @override
  String get theme => '主題';

  @override
  String get themeSubtitle => '跟隨系統、日間或夜間';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '日間';

  @override
  String get themeDark => '夜間';

  @override
  String get themeSaveError => '無法儲存主題設定，請稍後再試。';

  @override
  String get aboutSubtitle => '查看版本、隱私與開源資訊。';

  @override
  String get clearHistory => '清除歷史記錄';

  @override
  String get clearHistoryQuestion => '要清除傳輸歷史記錄嗎？';

  @override
  String get clearHistoryDescription => '這只會移除 OneSend 中的記錄，不會刪除已儲存的檔案。';

  @override
  String get clearAction => '清除';

  @override
  String get homeHeadline => '用光，\n傳送檔案。';

  @override
  String get homeSubtitle => '不用網路。不用配對。\n只需一個螢幕和一台相機。';

  @override
  String get sendEyebrow => '傳送';

  @override
  String get receiveEyebrow => '接收';

  @override
  String get sendFile => '傳送檔案';

  @override
  String get receiveFile => '接收檔案';

  @override
  String get sendCardDescription => '將代碼顯示在螢幕上，並讓另一台裝置對準它。';

  @override
  String get receiveCardDescription => '開啟相機，掃描不斷變化的視覺碼。';

  @override
  String get recentTransfers => '最近傳輸';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 筆記錄',
      one: '1 筆記錄',
      zero: '0 筆記錄',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter => '螢幕 ↔ 相機 · 檔案只以光在兩台裝置間傳輸';

  @override
  String get emptyHistory => '尚無傳輸歷史記錄。選擇檔案，開始第一次光學傳輸。';

  @override
  String get receivedAndVerified => '已接收並驗證';

  @override
  String get sendEnded => '傳送結束';

  @override
  String get sent => '已傳送';

  @override
  String get receivedFileActions => '已接收檔案的操作';

  @override
  String get justNow => '剛剛';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 分鐘前',
      one: '1 分鐘前',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 小時前',
      one: '1 小時前',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 天前',
      one: '1 天前',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle => '應用設定';

  @override
  String get settingsIntroBody => '傳輸模式請在傳送頁選擇。';

  @override
  String get transportSection => '傳輸';

  @override
  String get defaultTransferAlgorithm => '預設傳輸演算法';

  @override
  String get algorithmDescription =>
      '選擇 QR 設定或實驗性的 CIMBAR 彩色視覺碼。QR 接收模式會在每個影格中自我描述。';

  @override
  String theoreticalSpeed(Object speed) {
    return '約 $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed；穩定快速，適合固定裝置和明亮螢幕。';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed；可靠且相容性高，錯誤修正餘量更大，但傳輸較慢。';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed；實驗性高容量 QR 設定，掃描餘量較小。';
  }

  @override
  String get cimbarModeDescription =>
      '上游基準約 106 KB/s；Android 和 iOS 上可用的實驗性彩色視覺碼。';

  @override
  String get modeSaveError => '無法儲存預設傳輸設定，請稍後再試。';

  @override
  String get appSection => '應用程式';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => '自動更新';

  @override
  String get desktopUpdatesSubtitle => '在桌面裝置上檢查更新並設定自動檢查。';

  @override
  String get mobileOfflineNote => '行動裝置維持離線：只能使用傳輸和語言設定。';

  @override
  String get languagePickerTitle => '選擇語言';

  @override
  String get languageSaveError => '無法儲存語言設定，請再試一次。';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode，$speed';
  }

  @override
  String get experimentalVisualTransfer => '實驗性離線視覺傳輸';

  @override
  String get workingPrinciple => '運作方式';

  @override
  String get workingPrincipleBody =>
      '檔案會被編碼成不斷變化的視覺碼序列。傳送端顯示這些代碼；接收端用相機讀取並驗證每個影格，然後還原檔案。路徑只有螢幕與相機之間的光。';

  @override
  String get whyWeBuiltIt => '開發初衷';

  @override
  String get whyWeBuiltItBody =>
      '兩台裝置無需網路、帳戶或配對就能交換檔案。OneSend 將裝置上現有的螢幕和相機變成簡單的離線通道。';

  @override
  String get privacy => '隱私權';

  @override
  String get privacyBody => '傳輸不使用網路或伺服器。行動裝置只需要相機存取權限。';

  @override
  String get openSourceAndAuthor => '開放原始碼與作者';

  @override
  String get author => '作者';

  @override
  String get license => '授權條款';

  @override
  String get version => '版本';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => '開啟 GitHub';

  @override
  String get opening => '開啟中…';

  @override
  String get versionUnavailable => '無法取得版本';

  @override
  String get readingVersion => '讀取版本中…';

  @override
  String get cannotOpenGithub => '無法開啟 GitHub 頁面，請再試一次。';

  @override
  String get aboutFooter => 'OneSend · 光學檔案傳輸';

  @override
  String versionLabel(Object version) {
    return '版本 $version';
  }

  @override
  String get chooseAFile => '選擇檔案';

  @override
  String sendFileDescription(Object maxSize) {
    return '檔案會變成不斷變化的視覺碼序列。\n上限為 $maxSize；第一次測試請先從小檔案開始。';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return '新的傳送會使用 $mode 模式 · 理論速率約 $speed';
  }

  @override
  String get transferModeLabel => '傳輸模式';

  @override
  String get dropFilesHint => '也可以把檔案拖到這裡';

  @override
  String get dropFilesActive => '放開即可傳送';

  @override
  String get reading => '讀取中…';

  @override
  String get chooseFile => '選擇檔案';

  @override
  String get sampleVideo => '傳送內建測試影片';

  @override
  String get encodedPayloadTooLarge => '編碼後的檔案大於光學傳輸上限。';

  @override
  String modeBadge(Object mode) {
    return '$mode 模式';
  }

  @override
  String get broadcasting => '正在傳送不斷變化的視覺碼';

  @override
  String get pausedPlayback => '播放已暫停';

  @override
  String get cameraAim => '將另一台裝置的相機對準這個白色區域';

  @override
  String passAndFrames(Object frames, Object pass) {
    return '階段 $pass · 已傳送 $frames 個影格';
  }

  @override
  String runningTime(Object duration) {
    return '執行時間 $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return '理論速率 $speed';
  }

  @override
  String currentRate(Object speed) {
    return '目前速率 $speed';
  }

  @override
  String get resume => '繼續';

  @override
  String get pause => '暫停';

  @override
  String get endTransfer => '結束傳輸';

  @override
  String get sendAnother => '傳送其他檔案';

  @override
  String get chooseOtherFile => '選擇其他檔案';

  @override
  String fileTooLarge(Object maxSize) {
    return '檔案大小不得超過 $maxSize。';
  }

  @override
  String get cannotReadFile => 'OneSend 無法讀取此檔案。';

  @override
  String get sampleVideoEmpty => '無法使用內建測試影片。';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return '內建測試影片大於 $maxSize。';
  }

  @override
  String get genericTransferError => '無法開始傳輸，請再試一次。';

  @override
  String get scanReceive => '掃描以接收';

  @override
  String get torch => '手電筒';

  @override
  String get checkingAndSaving => '正在驗證並儲存…';

  @override
  String get pausedKeepProgress => '已暫停。點選「繼續」可保留目前進度。';

  @override
  String get lookingForSender => '正在尋找傳送端…';

  @override
  String lockedModeCollecting(Object mode) {
    return '已鎖定 $mode 模式 · 正在收集視覺碼';
  }

  @override
  String get scanInstruction => '讓視覺碼完整位於畫面內，並穩定握住裝置。';

  @override
  String get scannerBytesUnavailable => '已識別 QR 碼，但相機未傳回資料；正在繼續掃描。';

  @override
  String get scannerInvalidFrame => '識別到的 QR 碼不是 OneSend 資料；正在繼續掃描。';

  @override
  String get desktopCameraInstruction => '桌面相機解碼使用螢幕截圖，因此比行動裝置慢。';

  @override
  String get verifying => '驗證中…';

  @override
  String get paused => '已暫停';

  @override
  String get waitingFirstFrame => '等待第一個影格';

  @override
  String fountainProgress(Object frames) {
    return '$frames 個影格 · Fountain 復原';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames 個影格 · $solved/$blocks 個區塊';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => '繼續掃描';

  @override
  String get pauseScan => '暫停掃描';

  @override
  String get restart => '重新開始';

  @override
  String get receivedComplete => '已接收';

  @override
  String get verifiedNotSaved => '檔案已驗證，但尚未儲存。';

  @override
  String get verifiedSaved => '檔案已驗證並儲存到此裝置。';

  @override
  String get retrySave => '重試儲存';

  @override
  String get continueReceiving => '再接收一個';

  @override
  String recordWriteError(Object error) {
    return '檔案已儲存，但無法寫入歷史記錄：$error';
  }

  @override
  String saveFailed(Object error) {
    return '儲存失敗：$error';
  }

  @override
  String get fileActions => '檔案操作';

  @override
  String get saveLocation => '儲存位置';

  @override
  String get unrecordedLocation => '未記錄儲存位置。';

  @override
  String get fileMissing => '找不到檔案；檔案可能已移動或刪除。';

  @override
  String savedTo(Object path) {
    return '已儲存至：$path';
  }

  @override
  String iosSavedLocation(Object name) {
    return '檔案 > 我的 iPhone/iPad > OneSend > 已接收 > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return '已儲存至應用程式儲存空間：$name。使用「儲存副本」選擇可見的資料夾。';
  }

  @override
  String copyExported(Object name) {
    return '已匯出副本：$name（系統檔案選擇器已選擇位置）';
  }

  @override
  String copyExportedDesktop(Object path) {
    return '已將副本匯出至：$path';
  }

  @override
  String get fileOperationError => '檔案操作失敗，請再試一次。';

  @override
  String get fileNotFound => '檔案不存在。';

  @override
  String get fileAccessDenied => '你沒有存取此檔案的權限。';

  @override
  String get operationCancelled => '操作已取消。';

  @override
  String get unsupportedOperation => '目前裝置不支援此操作。';

  @override
  String get openFileError => '系統無法開啟此檔案。';

  @override
  String get shareFileError => '無法分享此檔案，請再試一次。';

  @override
  String get revealFileError => '無法在其資料夾中顯示此檔案，請再試一次。';

  @override
  String get saveFileError => '無法匯出檔案，請再試一次。';

  @override
  String get locationPathUnknown => '不知道儲存位置。';

  @override
  String get updateAppDescription => '螢幕與相機之間的離線檔案傳輸';

  @override
  String get currentVersion => '目前版本';

  @override
  String get automaticChecks => '自動檢查更新';

  @override
  String get automaticChecksSubtitle => '每天安靜地檢查一次，只有找到新版本時才通知你。';

  @override
  String get downloadPage => '下載頁面';

  @override
  String get checking => '檢查中…';

  @override
  String get checkForUpdates => '檢查更新';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version 已可用';
  }

  @override
  String get releaseNotes => '更新內容';

  @override
  String get downloading => '正在下載並驗證…';

  @override
  String downloadingPercent(Object percent) {
    return '正在下載並驗證 $percent%';
  }

  @override
  String get viewRelease => '檢視版本頁面';

  @override
  String get later => '稍後';

  @override
  String get downloadUpdate => '下載更新';

  @override
  String get latestVersion => '你已使用最新版本。';

  @override
  String get updateCheckWindowOpened => '更新檢查視窗已開啟。';

  @override
  String get unsupportedUpdate => '此平台不支援應用程式內更新。';

  @override
  String get updateCheckFailed => '無法檢查更新，請稍後再試。';

  @override
  String get automaticUpdateError => '無法變更自動更新設定。';

  @override
  String get downloadPageError => '無法開啟下載頁面。';

  @override
  String get releasePageError => '無法開啟版本頁面。';

  @override
  String get downloadError => '無法下載更新套件，請稍後再試。';

  @override
  String get cimbarSendTitle => 'CIMBAR 高速傳送';

  @override
  String get cimbarReceiveTitle => 'CIMBAR 高速接收';

  @override
  String get cimbarUnsupported => 'CIMBAR 實驗性傳輸引擎僅支援 Android 與 iOS。';

  @override
  String get cimbarLoading => '正在載入實驗引擎…';

  @override
  String get cimbarPageReadySend => '實驗引擎已載入，請選擇檔案。';

  @override
  String get cimbarPageReadyReceive => '實驗引擎已載入，點選開始後請求相機權限。';

  @override
  String get cimbarEngineReady => '實驗引擎已就緒 · 模式 B';

  @override
  String get cimbarPreparingFile => '正在準備檔案…';

  @override
  String get cimbarPaused => '已暫停播放';

  @override
  String get cimbarPlaying => '正在播放';

  @override
  String get cimbarBroadcasting => '檔案已準備，正在播放視覺碼';

  @override
  String get cimbarDecoderReady => '解碼器已就緒，正在尋找 CIMBAR。';

  @override
  String get cimbarDecoderReadyStart => '解碼器已就緒，點選開始後請求相機權限。';

  @override
  String get cimbarCameraStarted => '相機已啟動，正在尋找 CIMBAR。';

  @override
  String get cimbarDecoding => '正在使用上游 worker 解碼';

  @override
  String get cimbarFileHeaderReceived => '檔案標頭已校驗，正在接收分塊。';

  @override
  String get cimbarReceiving => '正在接收已校驗的位元組';

  @override
  String get cimbarRecoveredSaving => '檔案已完整還原，正在儲存…';

  @override
  String get cimbarRecoveredNotSaved => '檔案已完整還原，但尚未儲存。';

  @override
  String get cimbarReceiveComplete => '接收完成';

  @override
  String get cimbarLoadFailed => '載入失敗，請重試。';

  @override
  String get cimbarTransferFailed => 'CIMBAR 傳輸失敗，請重試。';

  @override
  String get cimbarReloading => '正在重新載入實驗引擎…';

  @override
  String get cimbarRequestingCamera => '正在請求相機權限…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return '檔案：$name · $size';
  }

  @override
  String get cimbarSendRate => '上游參考：106 KB/s · 模式 B';

  @override
  String cimbarReceiveRate(Object speed) {
    return '上游參考：106 KB/s · 本次接收實測：$speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return '已還原 $received / $expected · $seconds 秒';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return '已還原 $received · $seconds 秒';
  }

  @override
  String get cimbarStartReceive => '開始接收（請求相機）';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return '行動版 CIMBAR 檔案不可超過 $maxSize。';
  }

  @override
  String get cimbarPageLoadError => '無法載入離線 CIMBAR 頁面，請重試。';

  @override
  String get cimbarBridgeError => 'CIMBAR 傳送了無效事件，請重試。';

  @override
  String get cimbarEngineError => 'CIMBAR 引擎無法使用，請重試。';

  @override
  String get cimbarCameraError => '相機存取或解碼失敗，請檢查權限後重試。';

  @override
  String get cimbarSendError => 'CIMBAR 傳送端無法準備檔案，請重試。';

  @override
  String get cimbarReceiveError => 'CIMBAR 接收端無法解碼檔案，請重試。';

  @override
  String get cimbarVerificationError => '接收檔案無法通過校驗，請重試。';

  @override
  String get cimbarSaveError => '還原的檔案無法儲存，請重試儲存。';

  @override
  String get cimbarHistoryError => '檔案已儲存，但傳輸記錄無法寫入。';

  @override
  String get cimbarAllFiles => '所有檔案';

  @override
  String get cimbarSelectedFileName => 'selected.bin';

  @override
  String get cimbarReceivedFileName => 'received.bin';

  @override
  String cimbarBytes(Object value) {
    return '$value B';
  }

  @override
  String cimbarKibibytes(Object value) {
    return '$value KiB';
  }

  @override
  String cimbarMebibytes(Object value) {
    return '$value MiB';
  }

  @override
  String durationHoursMinutes(Object hours, Object minutes) {
    return '$hours 小時 $minutes 分鐘';
  }

  @override
  String durationMinutesSeconds(Object minutes, Object seconds) {
    return '$minutes:$seconds';
  }

  @override
  String errorDetails(Object message) {
    return '$message';
  }
}
