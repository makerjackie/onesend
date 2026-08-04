// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'OneSend';

  @override
  String get followSystem => 'システムに従う';

  @override
  String get language => '言語';

  @override
  String get modeFast => '標準（推奨）';

  @override
  String get modeReliable => '互換';

  @override
  String get modeTurboQr => '高速';

  @override
  String get modeCimbar => 'カラー（実験）';

  @override
  String get modeQr => 'QR コード';

  @override
  String get compatibilityMode => '互換性';

  @override
  String get cancel => 'キャンセル';

  @override
  String get done => '完了';

  @override
  String get close => '閉じる';

  @override
  String get openFile => '開く';

  @override
  String get shareFile => '共有／転送';

  @override
  String get saveCopy => 'コピーを保存';

  @override
  String get revealInFolder => 'フォルダで表示';

  @override
  String get more => 'その他';

  @override
  String get settings => '設定';

  @override
  String get about => 'OneSend について';

  @override
  String get transferTab => '転送';

  @override
  String get filesTab => 'ファイル';

  @override
  String get filesTitle => 'ファイル';

  @override
  String get filesSubtitle => '転送履歴と受信ファイルを管理します。';

  @override
  String get theme => 'テーマ';

  @override
  String get themeSubtitle => 'システム、ライト、ダーク';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get themeSaveError => 'テーマを保存できませんでした。もう一度お試しください。';

  @override
  String get aboutSubtitle => 'バージョン、プライバシー、オープンソース。';

  @override
  String get clearHistory => '履歴を消去';

  @override
  String get clearHistoryQuestion => '転送履歴を消去しますか？';

  @override
  String get clearHistoryDescription =>
      'これは OneSend から記録だけを削除します。保存済みファイルは削除されません。';

  @override
  String get clearAction => '消去';

  @override
  String get homeHeadline => 'ファイルを、\n光で送る。';

  @override
  String get homeSubtitle => 'ネットワーク不要。ペアリング不要。\n画面とカメラだけ。';

  @override
  String get sendEyebrow => '送信';

  @override
  String get receiveEyebrow => '受信';

  @override
  String get sendFile => 'ファイルを送信';

  @override
  String get receiveFile => 'ファイルを受信';

  @override
  String get sendCardDescription => 'コードを画面に表示し、別の端末を向けてください。';

  @override
  String get receiveCardDescription => 'カメラを開き、変化するビジュアルコードをスキャンしてください。';

  @override
  String get recentTransfers => '最近の転送';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 件',
      one: '1 件',
      zero: '0 件',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter => '画面 ↔ カメラ · 2 台の端末間を光だけでファイルが移動';

  @override
  String get emptyHistory => '転送履歴はまだありません。ファイルを選んで、最初の光転送を始めましょう。';

  @override
  String get receivedAndVerified => '受信して検証済み';

  @override
  String get sendEnded => '送信終了';

  @override
  String get sent => '送信済み';

  @override
  String get receivedFileActions => '受信ファイルの操作';

  @override
  String get justNow => 'たった今';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 分前',
      one: '1 分前',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 時間前',
      one: '1 時間前',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 日前',
      one: '1 日前',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle => '次の転送を端末に合わせて調整';

  @override
  String get settingsIntroBody => '新しい送信にはデフォルトのモードが使われます。';

  @override
  String get transportSection => '転送';

  @override
  String get defaultTransferAlgorithm => 'デフォルトの転送アルゴリズム';

  @override
  String get algorithmDescription => '日常は「標準」のまま。設定で互換・高速・実験カラーに変更できます。';

  @override
  String theoreticalSpeed(Object speed) {
    return '約 $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed；多くの端末と明るい画面向けの日常デフォルト。';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed；暗い場所やピントが合いにくいときの、より安定した低速モード。';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed；より高速。ピント・露出・端末への要求は高めです。';
  }

  @override
  String get cimbarModeDescription => '実験的カラーコード。ピークは高いが、双方でカラーを選び、条件が厳しいです。';

  @override
  String get modeSaveError => 'デフォルトの転送設定を保存できませんでした。もう一度お試しください。';

  @override
  String get appSection => 'アプリ';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => '自動更新';

  @override
  String get desktopUpdatesSubtitle => 'デスクトップで更新を確認し、自動確認を設定します。';

  @override
  String get mobileOfflineNote => 'モバイルはオフラインのままです。利用できるのは転送と言語設定だけです。';

  @override
  String get languagePickerTitle => '言語を選択';

  @override
  String get languageSaveError => '言語設定を保存できませんでした。もう一度お試しください。';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode、$speed';
  }

  @override
  String get experimentalVisualTransfer => '実験的なオフライン光転送';

  @override
  String get workingPrinciple => '仕組み';

  @override
  String get workingPrincipleBody =>
      'ファイルは変化するビジュアルコードの連続に変換されます。送信側が表示し、受信側がカメラで各フレームを読み取って検証し、ファイルを復元します。経路は画面とカメラの間の光だけです。';

  @override
  String get whyWeBuiltIt => '開発した理由';

  @override
  String get whyWeBuiltItBody =>
      '2 台の端末は、ネットワーク、アカウント、ペアリングなしでファイルを交換できます。OneSend は端末にある画面とカメラを、シンプルなオフライン経路に変えます。';

  @override
  String get privacy => 'プライバシー';

  @override
  String get privacyBody => '転送にネットワークやサーバーは使いません。モバイルではカメラへのアクセスだけが必要です。';

  @override
  String get openSourceAndAuthor => 'オープンソースと作者';

  @override
  String get author => '作者';

  @override
  String get license => 'ライセンス';

  @override
  String get version => 'バージョン';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => 'GitHub を開く';

  @override
  String get opening => '開いています…';

  @override
  String get versionUnavailable => 'バージョンを取得できません';

  @override
  String get readingVersion => 'バージョンを読み取り中…';

  @override
  String get cannotOpenGithub => 'GitHub ページを開けませんでした。もう一度お試しください。';

  @override
  String get aboutFooter => 'OneSend · 光ファイル転送';

  @override
  String versionLabel(Object version) {
    return 'バージョン $version';
  }

  @override
  String get chooseAFile => 'ファイルを選択';

  @override
  String sendFileDescription(Object maxSize) {
    return 'ファイルは変化するビジュアルコードの連続になります。\n$maxSize まで。最初のテストは小さなファイルから始めてください。';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return '新しい送信は $mode モードを使用 · 理論上の速度は約 $speed';
  }

  @override
  String get transferModeLabel => '転送モード';

  @override
  String get dropFilesHint => 'またはファイルをここにドラッグ＆ドロップ';

  @override
  String get dropFilesActive => 'ドロップして送信';

  @override
  String get reading => '読み取り中…';

  @override
  String get chooseFile => 'ファイルを選択';

  @override
  String get sampleVideo => '内蔵のテスト動画を送信';

  @override
  String get encodedPayloadTooLarge => 'エンコード後のファイルが光転送の上限を超えています。';

  @override
  String modeBadge(Object mode) {
    return '$mode モード';
  }

  @override
  String get broadcasting => '変化するビジュアルコードを送信中';

  @override
  String get pausedPlayback => '再生を一時停止しました';

  @override
  String get cameraAim => '別の端末のカメラをこの白い領域に向けてください';

  @override
  String passAndFrames(Object frames, Object pass) {
    return 'パス $pass · $frames フレーム送信済み';
  }

  @override
  String runningTime(Object duration) {
    return '稼働時間 $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return '理論速度 $speed';
  }

  @override
  String currentRate(Object speed) {
    return '現在の速度 $speed';
  }

  @override
  String get resume => '再開';

  @override
  String get pause => '一時停止';

  @override
  String get endTransfer => '転送を終了';

  @override
  String get sendAnother => '別のファイルを送信';

  @override
  String get chooseOtherFile => '別のファイルを選択';

  @override
  String fileTooLarge(Object maxSize) {
    return 'ファイルは $maxSize 以下にしてください。';
  }

  @override
  String get cannotReadFile => 'OneSend はこのファイルを読み取れませんでした。';

  @override
  String get sampleVideoEmpty => '内蔵のテスト動画を利用できません。';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return '内蔵のテスト動画が $maxSize を超えています。';
  }

  @override
  String get genericTransferError => '転送を開始できませんでした。もう一度お試しください。';

  @override
  String get scanReceive => 'スキャンして受信';

  @override
  String get torch => 'ライト';

  @override
  String get checkingAndSaving => '検証して保存中…';

  @override
  String get pausedKeepProgress => '一時停止中です。現在の進行状況を保持するには「再開」をタップしてください。';

  @override
  String get lookingForSender => '送信側を探しています…';

  @override
  String lockedModeCollecting(Object mode) {
    return '$mode モードに固定 · ビジュアルコードを収集中';
  }

  @override
  String get scanInstruction => 'ビジュアルコード全体をフレーム内に収め、端末を動かさないでください。';

  @override
  String get scannerBytesUnavailable =>
      'QR コードを検出しましたが、カメラからデータを取得できませんでした。スキャンを続けます。';

  @override
  String get scannerInvalidFrame => 'OneSend データではない QR コードを検出しました。スキャンを続けます。';

  @override
  String get desktopCameraInstruction =>
      'デスクトップのカメラによるデコードはスクリーンショットを使うため、モバイルより遅くなります。';

  @override
  String get verifying => '検証中…';

  @override
  String get paused => '一時停止中';

  @override
  String get waitingFirstFrame => '最初のフレームを待っています';

  @override
  String fountainProgress(Object frames) {
    return '$frames フレーム · Fountain 復元';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames フレーム · $solved/$blocks ブロック';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => 'スキャンを再開';

  @override
  String get pauseScan => 'スキャンを一時停止';

  @override
  String get restart => '再起動';

  @override
  String get receivedComplete => '受信済み';

  @override
  String get verifiedNotSaved => 'ファイルは検証されましたが、まだ保存できませんでした。';

  @override
  String get verifiedSaved => 'ファイルを検証し、この端末に保存しました。';

  @override
  String get retrySave => '保存を再試行';

  @override
  String get continueReceiving => 'もう一つ受信';

  @override
  String recordWriteError(Object error) {
    return 'ファイルは保存されましたが、履歴レコードを書き込めませんでした：$error';
  }

  @override
  String saveFailed(Object error) {
    return '保存に失敗しました：$error';
  }

  @override
  String get fileActions => 'ファイル操作';

  @override
  String get saveLocation => '保存先';

  @override
  String get unrecordedLocation => '保存先は記録されていません。';

  @override
  String get fileMissing => 'ファイルがありません。移動または削除された可能性があります。';

  @override
  String savedTo(Object path) {
    return '保存先：$path';
  }

  @override
  String iosSavedLocation(Object name) {
    return 'ファイル > この iPhone/iPad 内 > OneSend > 受信済み > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return 'アプリのストレージに保存：$name。「コピーを保存」で表示できるフォルダを選択できます。';
  }

  @override
  String copyExported(Object name) {
    return 'コピーを書き出しました：$name（システムのファイルピッカーで保存先を選択）';
  }

  @override
  String copyExportedDesktop(Object path) {
    return 'コピーを書き出しました：$path';
  }

  @override
  String get fileOperationError => 'ファイル操作に失敗しました。もう一度お試しください。';

  @override
  String get fileNotFound => 'ファイルが存在しません。';

  @override
  String get fileAccessDenied => 'このファイルにアクセスする権限がありません。';

  @override
  String get operationCancelled => '操作をキャンセルしました。';

  @override
  String get unsupportedOperation => '現在の端末ではこの操作に対応していません。';

  @override
  String get openFileError => 'システムがこのファイルを開けませんでした。';

  @override
  String get shareFileError => 'このファイルを共有できませんでした。もう一度お試しください。';

  @override
  String get revealFileError => 'フォルダ内でファイルを表示できませんでした。もう一度お試しください。';

  @override
  String get saveFileError => 'ファイルを書き出せませんでした。もう一度お試しください。';

  @override
  String get locationPathUnknown => '保存先が不明です。';

  @override
  String get updateAppDescription => '画面とカメラの間で行うオフラインファイル転送';

  @override
  String get currentVersion => '現在のバージョン';

  @override
  String get automaticChecks => '更新を自動的に確認';

  @override
  String get automaticChecksSubtitle =>
      '1 日に 1 回静かに確認し、新しいバージョンが見つかったときだけ通知します。';

  @override
  String get downloadPage => 'ダウンロードページ';

  @override
  String get checking => '確認中…';

  @override
  String get checkForUpdates => '更新を確認';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version を利用できます';
  }

  @override
  String get releaseNotes => '更新内容';

  @override
  String get downloading => 'ダウンロードして検証中…';

  @override
  String downloadingPercent(Object percent) {
    return '$percent% をダウンロードして検証中…';
  }

  @override
  String get viewRelease => 'リリースページを表示';

  @override
  String get later => '後で';

  @override
  String get downloadUpdate => '更新をダウンロード';

  @override
  String get latestVersion => '最新バージョンを使用中です。';

  @override
  String get updateCheckWindowOpened => '更新確認ウィンドウが開いています。';

  @override
  String get unsupportedUpdate => 'このプラットフォームではアプリ内更新に対応していません。';

  @override
  String get updateCheckFailed => '更新を確認できませんでした。後でもう一度お試しください。';

  @override
  String get automaticUpdateError => '自動更新設定を変更できませんでした。';

  @override
  String get downloadPageError => 'ダウンロードページを開けませんでした。';

  @override
  String get releasePageError => 'リリースページを開けませんでした。';

  @override
  String get downloadError => '更新パッケージをダウンロードできませんでした。後でもう一度お試しください。';

  @override
  String get cimbarSendTitle => 'CIMBAR 高速送信';

  @override
  String get cimbarReceiveTitle => 'CIMBAR 高速受信';

  @override
  String get cimbarUnsupported => '実験的な CIMBAR 転送は Android と iOS のみで利用できます。';

  @override
  String get cimbarLoading => '実験エンジンを読み込み中…';

  @override
  String get cimbarPageReadySend => '実験エンジンを読み込みました。ファイルを選択してください。';

  @override
  String get cimbarPageReadyReceive => '実験エンジンを読み込みました。開始をタップしてカメラへのアクセスを求めます。';

  @override
  String get cimbarEngineReady => '実験エンジンの準備完了 · モード B';

  @override
  String get cimbarPreparingFile => 'ファイルを準備中…';

  @override
  String get cimbarPaused => '再生を一時停止中';

  @override
  String get cimbarPlaying => '再生中';

  @override
  String get cimbarBroadcasting => 'ファイルの準備完了。ビジュアルコードを表示中';

  @override
  String get cimbarDecoderReady => 'デコーダーの準備完了。CIMBAR を探しています。';

  @override
  String get cimbarDecoderReadyStart => 'デコーダーの準備完了。開始をタップしてカメラへのアクセスを求めます。';

  @override
  String get cimbarCameraStarted => 'カメラを開始しました。CIMBAR を探しています。';

  @override
  String get cimbarDecoding => '上流 worker でデコード中';

  @override
  String get cimbarFileHeaderReceived => 'ファイルヘッダーを検証しました。チャンクを受信中です。';

  @override
  String get cimbarReceiving => '検証済みバイトを受信中';

  @override
  String get cimbarRecoveredSaving => 'ファイルを完全に復元しました。保存中…';

  @override
  String get cimbarRecoveredNotSaved => 'ファイルを完全に復元しましたが、まだ保存されていません。';

  @override
  String get cimbarReceiveComplete => '受信完了';

  @override
  String get cimbarLoadFailed => '読み込みに失敗しました。もう一度お試しください。';

  @override
  String get cimbarTransferFailed => 'CIMBAR 転送に失敗しました。もう一度お試しください。';

  @override
  String get cimbarReloading => '実験エンジンを再読み込み中…';

  @override
  String get cimbarRequestingCamera => 'カメラへのアクセスを求めています…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return 'ファイル：$name · $size';
  }

  @override
  String get cimbarSendRate => '上流参考値：106 KB/s · モード B';

  @override
  String cimbarReceiveRate(Object speed) {
    return '上流参考値：106 KB/s · 今回の受信実測値：$speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return '復元済み $received / $expected · $seconds 秒';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return '復元済み $received · $seconds 秒';
  }

  @override
  String get cimbarStartReceive => '受信を開始（カメラを要求）';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return 'モバイル CIMBAR ファイルは $maxSize 以下にしてください。';
  }

  @override
  String get cimbarPageLoadError => 'オフライン CIMBAR ページを読み込めませんでした。もう一度お試しください。';

  @override
  String get cimbarBridgeError => 'CIMBAR 転送が無効なイベントを送信しました。もう一度お試しください。';

  @override
  String get cimbarEngineError => 'CIMBAR エンジンを利用できません。もう一度お試しください。';

  @override
  String get cimbarCameraError => 'カメラへのアクセスまたはデコードに失敗しました。権限を確認してもう一度お試しください。';

  @override
  String get cimbarSendError => 'CIMBAR 送信側でファイルを準備できませんでした。もう一度お試しください。';

  @override
  String get cimbarReceiveError => 'CIMBAR 受信側でファイルをデコードできませんでした。もう一度お試しください。';

  @override
  String get cimbarVerificationError => '受信ファイルを検証できませんでした。もう一度お試しください。';

  @override
  String get cimbarSaveError => '復元したファイルを保存できませんでした。もう一度お試しください。';

  @override
  String get cimbarHistoryError => 'ファイルは保存されましたが、転送履歴を記録できませんでした。';

  @override
  String get cimbarAllFiles => 'すべてのファイル';

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
    return '$hours時間 $minutes分';
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
