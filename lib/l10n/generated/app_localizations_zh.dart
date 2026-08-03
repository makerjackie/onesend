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
  String get clearHistory => '清空记录';

  @override
  String get clearHistoryQuestion => '清空传输记录？';

  @override
  String get clearHistoryDescription => '只会清除 OneSend 里的记录，不会删除已经保存的文件。';

  @override
  String get clearAction => '清空';

  @override
  String get homeHeadline => '文件，\\n用光传过去。';

  @override
  String get homeSubtitle => '无需网络，无需配对。\\n只要一块屏幕和一枚摄像头。';

  @override
  String get sendEyebrow => '发送';

  @override
  String get receiveEyebrow => '接收';

  @override
  String get sendFile => '发送文件';

  @override
  String get receiveFile => '扫描接收';

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
  String get settingsIntroTitle => '让之后的传输按你的设备来。';

  @override
  String get settingsIntroBody => '默认模式用于之后的新建发送。';

  @override
  String get transportSection => '传输';

  @override
  String get defaultTransferAlgorithm => '默认传输算法';

  @override
  String get algorithmDescription => '快速适合固定设备；可靠给手持扫描更多余量。';

  @override
  String theoreticalSpeed(Object speed) {
    return '理论约 $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed；适合固定设备和明亮屏幕。';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed；纠错余量更大，但传输更慢。';
  }

  @override
  String get modeSaveError => '无法保存默认传输模式，请稍后重试。';

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
    return '文件会被编码成一串不断变化的视觉码。\\n最大支持 $maxSize，建议从小文件开始体验。';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return '新传输默认使用$mode模式 · 理论码流约 $speed';
  }

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
  String get clearHistory => '清空记录';

  @override
  String get clearHistoryQuestion => '清空传输记录？';

  @override
  String get clearHistoryDescription => '只会清除 OneSend 里的记录，不会删除已经保存的文件。';

  @override
  String get clearAction => '清空';

  @override
  String get homeHeadline => '文件，\\n用光传过去。';

  @override
  String get homeSubtitle => '无需网络，无需配对。\\n只要一块屏幕和一枚摄像头。';

  @override
  String get sendEyebrow => '发送';

  @override
  String get receiveEyebrow => '接收';

  @override
  String get sendFile => '发送文件';

  @override
  String get receiveFile => '扫描接收';

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
  String get settingsIntroTitle => '让之后的传输按你的设备来。';

  @override
  String get settingsIntroBody => '默认模式用于之后的新建发送。';

  @override
  String get transportSection => '传输';

  @override
  String get defaultTransferAlgorithm => '默认传输算法';

  @override
  String get algorithmDescription => '快速适合固定设备；可靠给手持扫描更多余量。';

  @override
  String theoreticalSpeed(Object speed) {
    return '理论约 $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed；适合固定设备和明亮屏幕。';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed；纠错余量更大，但传输更慢。';
  }

  @override
  String get modeSaveError => '无法保存默认传输模式，请稍后重试。';

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
    return '文件会被编码成一串不断变化的视觉码。\\n最大支持 $maxSize，建议从小文件开始体验。';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return '新传输默认使用$mode模式 · 理论码流约 $speed';
  }

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
  String get appTitle => 'OneSend';

  @override
  String get followSystem => 'Follow system';

  @override
  String get language => 'Language';

  @override
  String get modeFast => 'Fast';

  @override
  String get modeReliable => 'Reliable';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get openFile => 'Open';

  @override
  String get shareFile => 'Share / forward';

  @override
  String get saveCopy => 'Save a copy';

  @override
  String get revealInFolder => 'Reveal in folder';

  @override
  String get more => 'More';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About OneSend';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryQuestion => 'Clear transfer history?';

  @override
  String get clearHistoryDescription =>
      'This only removes records from OneSend. Saved files will not be deleted.';

  @override
  String get clearAction => 'Clear';

  @override
  String get homeHeadline => 'Send files,\nwith light.';

  @override
  String get homeSubtitle =>
      'No network. No pairing.\nJust a screen and a camera.';

  @override
  String get sendEyebrow => 'SEND';

  @override
  String get receiveEyebrow => 'RECEIVE';

  @override
  String get sendFile => 'Send a file';

  @override
  String get receiveFile => 'Scan to receive';

  @override
  String get sendCardDescription =>
      'Put the code on screen and aim another device at it.';

  @override
  String get receiveCardDescription =>
      'Open the camera and scan the changing visual code.';

  @override
  String get recentTransfers => 'Recent transfers';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# records',
      one: '1 record',
      zero: '0 records',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter =>
      'Screen ↔ camera · Files travel only as light between two devices';

  @override
  String get emptyHistory =>
      'No transfer history yet. Choose a file to start your first optical transfer.';

  @override
  String get receivedAndVerified => 'Received and verified';

  @override
  String get sendEnded => 'Sending ended';

  @override
  String get sent => 'Sent';

  @override
  String get receivedFileActions => 'Received file actions';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle => 'Tune the next transfer to your device.';

  @override
  String get settingsIntroBody => 'The default mode is used for new sends.';

  @override
  String get transportSection => 'TRANSFER';

  @override
  String get defaultTransferAlgorithm => 'Default transfer algorithm';

  @override
  String get algorithmDescription =>
      'Fast is best for a steady setup; Reliable gives handheld scanning more headroom.';

  @override
  String theoreticalSpeed(Object speed) {
    return 'About $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed; best for a steady setup and bright screen.';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed; more error-correction headroom, but slower.';
  }

  @override
  String get modeSaveError =>
      'Could not save the default transfer mode. Try again.';

  @override
  String get appSection => 'APP';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => 'Automatic updates';

  @override
  String get desktopUpdatesSubtitle =>
      'Check for updates and configure automatic checks on desktop.';

  @override
  String get mobileOfflineNote =>
      'Mobile stays offline: only transfer and language settings are available.';

  @override
  String get languagePickerTitle => 'Choose language';

  @override
  String get languageSaveError =>
      'Could not save the language setting. Try again.';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode, $speed';
  }

  @override
  String get experimentalVisualTransfer =>
      'Experimental offline visual transfer';

  @override
  String get workingPrinciple => 'How it works';

  @override
  String get workingPrincipleBody =>
      'A file is encoded into a changing sequence of visual codes. The sender displays them; the receiver reads and verifies each frame with its camera, then restores the file. The path is only light between the screen and camera.';

  @override
  String get whyWeBuiltIt => 'Why we built it';

  @override
  String get whyWeBuiltItBody =>
      'Two devices can exchange a file without a network, account, or pairing. OneSend turns the screen and camera already on your devices into a simple offline channel.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody =>
      'Transfers do not use a network or server. Mobile needs camera access only.';

  @override
  String get openSourceAndAuthor => 'Open source & author';

  @override
  String get author => 'Author';

  @override
  String get license => 'License';

  @override
  String get version => 'Version';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => 'Open GitHub';

  @override
  String get opening => 'Opening…';

  @override
  String get versionUnavailable => 'Version unavailable';

  @override
  String get readingVersion => 'Reading version…';

  @override
  String get cannotOpenGithub => 'Could not open the GitHub page. Try again.';

  @override
  String get aboutFooter => 'OneSend · optical file transfer';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get chooseAFile => 'Choose a file';

  @override
  String sendFileDescription(Object maxSize) {
    return 'The file becomes a changing sequence of visual codes.\nUp to $maxSize; start with a small file for the first test.';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return 'New sends use $mode mode · theoretical rate about $speed';
  }

  @override
  String get reading => 'Reading…';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get sampleVideo => 'Send the built-in test video';

  @override
  String get encodedPayloadTooLarge =>
      'The encoded file is larger than the optical transfer limit.';

  @override
  String modeBadge(Object mode) {
    return '$mode mode';
  }

  @override
  String get broadcasting => 'Broadcasting the changing visual code';

  @override
  String get pausedPlayback => 'Playback paused';

  @override
  String get cameraAim => 'Aim the other device\'s camera at this white area';

  @override
  String passAndFrames(Object frames, Object pass) {
    return 'Pass $pass · $frames frames sent';
  }

  @override
  String runningTime(Object duration) {
    return 'Running $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return 'Theoretical rate $speed';
  }

  @override
  String currentRate(Object speed) {
    return 'Current rate $speed';
  }

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get endTransfer => 'End transfer';

  @override
  String get sendAnother => 'Send another file';

  @override
  String get chooseOtherFile => 'Choose another file';

  @override
  String fileTooLarge(Object maxSize) {
    return 'Files must be no larger than $maxSize.';
  }

  @override
  String get cannotReadFile => 'OneSend could not read this file.';

  @override
  String get sampleVideoEmpty => 'The built-in test video is unavailable.';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return 'The built-in test video is larger than $maxSize.';
  }

  @override
  String get genericTransferError => 'Transfer could not start. Try again.';

  @override
  String get scanReceive => 'Scan to receive';

  @override
  String get torch => 'Torch';

  @override
  String get checkingAndSaving => 'Verifying and saving…';

  @override
  String get pausedKeepProgress =>
      'Paused. Tap resume to keep the current progress.';

  @override
  String get lookingForSender => 'Looking for a sender…';

  @override
  String lockedModeCollecting(Object mode) {
    return 'Locked to $mode mode · collecting visual codes';
  }

  @override
  String get scanInstruction =>
      'Keep the visual code fully inside the frame and hold the device steady.';

  @override
  String get desktopCameraInstruction =>
      'Desktop camera decoding uses screenshots, so it is slower than mobile.';

  @override
  String get verifying => 'Verifying…';

  @override
  String get paused => 'Paused';

  @override
  String get waitingFirstFrame => 'Waiting for the first frame';

  @override
  String fountainProgress(Object frames) {
    return '$frames frames · Fountain recovery';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames frames · $solved/$blocks blocks';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => 'Resume scan';

  @override
  String get pauseScan => 'Pause scan';

  @override
  String get restart => 'Restart';

  @override
  String get receivedComplete => 'Received';

  @override
  String get verifiedNotSaved =>
      'The file was verified, but could not be saved yet.';

  @override
  String get verifiedSaved => 'The file was verified and saved on this device.';

  @override
  String get retrySave => 'Retry save';

  @override
  String get continueReceiving => 'Receive another';

  @override
  String recordWriteError(Object error) {
    return 'The file was saved, but its history record could not be written: $error';
  }

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get fileActions => 'File actions';

  @override
  String get saveLocation => 'Saved location';

  @override
  String get unrecordedLocation => 'No saved location was recorded.';

  @override
  String get fileMissing =>
      'The file is missing; it may have been moved or deleted.';

  @override
  String savedTo(Object path) {
    return 'Saved to: $path';
  }

  @override
  String iosSavedLocation(Object name) {
    return 'Files > On My iPhone/iPad > OneSend > Received > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return 'Saved in app storage: $name. Use Save a copy to choose a visible folder.';
  }

  @override
  String copyExported(Object name) {
    return 'Copy exported: $name (the system file picker chose the location)';
  }

  @override
  String copyExportedDesktop(Object path) {
    return 'Copy exported to: $path';
  }

  @override
  String get fileOperationError => 'File operation failed. Try again.';

  @override
  String get fileNotFound => 'The file does not exist.';

  @override
  String get fileAccessDenied =>
      'You do not have permission to access this file.';

  @override
  String get operationCancelled => 'Operation cancelled.';

  @override
  String get unsupportedOperation =>
      'This operation is not supported on the current device.';

  @override
  String get openFileError => 'The system could not open this file.';

  @override
  String get shareFileError => 'Could not share this file. Try again.';

  @override
  String get revealFileError =>
      'Could not reveal the file in its folder. Try again.';

  @override
  String get saveFileError => 'Could not export the file. Try again.';

  @override
  String get locationPathUnknown => 'The saved location is unknown.';

  @override
  String get updateAppDescription =>
      'Offline file transfer between a screen and a camera.';

  @override
  String get currentVersion => 'Current version';

  @override
  String get automaticChecks => 'Check for updates automatically';

  @override
  String get automaticChecksSubtitle =>
      'Check quietly once a day and notify you only when a new version is found.';

  @override
  String get downloadPage => 'Download page';

  @override
  String get checking => 'Checking…';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version is available';
  }

  @override
  String get releaseNotes => 'What\'s new';

  @override
  String get downloading => 'Downloading and verifying…';

  @override
  String downloadingPercent(Object percent) {
    return 'Downloading and verifying $percent%';
  }

  @override
  String get viewRelease => 'View release page';

  @override
  String get later => 'Later';

  @override
  String get downloadUpdate => 'Download update';

  @override
  String get latestVersion => 'You already have the latest version.';

  @override
  String get updateCheckWindowOpened => 'The update check window is open.';

  @override
  String get unsupportedUpdate =>
      'In-app updates are not supported on this platform.';

  @override
  String get updateCheckFailed =>
      'Could not check for updates. Try again later.';

  @override
  String get automaticUpdateError =>
      'Could not change automatic update settings.';

  @override
  String get downloadPageError => 'Could not open the download page.';

  @override
  String get releasePageError => 'Could not open the release page.';

  @override
  String get downloadError =>
      'The update package could not be downloaded. Try again later.';

  @override
  String durationHoursMinutes(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
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
