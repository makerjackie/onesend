// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OneSend';

  @override
  String get followSystem => 'Follow system';

  @override
  String get language => 'Language';

  @override
  String get modeFast => 'Standard (Recommended)';

  @override
  String get modeReliable => 'Compatible';

  @override
  String get modeTurboQr => 'Fast';

  @override
  String get modeCimbar => 'Color (Experimental)';

  @override
  String get modeQr => 'QR code';

  @override
  String get compatibilityMode => 'Compatibility';

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
  String get transferTab => 'Transfer';

  @override
  String get filesTab => 'Files';

  @override
  String get filesTitle => 'Files';

  @override
  String get filesSubtitle => 'Manage transfer history and received files.';

  @override
  String get theme => 'Theme';

  @override
  String get themeSubtitle => 'System, light, or dark';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSaveError => 'Could not save the theme setting. Try again.';

  @override
  String get aboutSubtitle => 'Release details, privacy, and open source.';

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
  String get receiveFile => 'Receive a file';

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
  String get settingsIntroTitle => 'App settings';

  @override
  String get settingsIntroBody => 'Choose transfer mode on the send screen.';

  @override
  String get transportSection => 'TRANSFER';

  @override
  String get defaultTransferAlgorithm => 'Default transfer algorithm';

  @override
  String get algorithmDescription =>
      'Leave Standard selected for daily use. Switch to Compatible, Fast, or experimental Color in settings.';

  @override
  String theoreticalSpeed(Object speed) {
    return 'About $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed; daily default for most phones and a bright screen.';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed; slower but steadier when light is poor or focus is hard.';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed; faster, with tighter focus, exposure, and device demands.';
  }

  @override
  String get cimbarModeDescription =>
      'Experimental color code; higher peak speed, both sides must match, tougher conditions.';

  @override
  String get modeSaveError =>
      'Could not save the default transfer settings. Try again.';

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
  String get openPrivacyPolicy => 'Open privacy policy';

  @override
  String get cannotOpenPrivacy =>
      'Could not open the privacy policy. Try again.';

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
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String settingsVersionFooter(String version) {
    return '$version';
  }

  @override
  String get acknowledgments => 'Acknowledgments';

  @override
  String get acknowledgmentsIntro =>
      'OneSend is grateful to these open-source projects for ideas, reference designs, and assets:';

  @override
  String get creditDecimen =>
      'decimen-optical-transfer — LT-code / protocol foundation (MIT)';

  @override
  String get creditQrDataTransfer =>
      'qr-data-transfer — public architecture reviewed; no code included';

  @override
  String get creditLibcimbar =>
      'libcimbar v0.6.7c — experimental color visual code (MPL-2.0)';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get sendFeedbackSubtitle => 'Report issues on GitHub';

  @override
  String get openGithubIssues => 'Open GitHub Issues';

  @override
  String get cannotOpenGithubIssues =>
      'Could not open GitHub Issues. Try again.';

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
  String get transferModeLabel => 'Transfer mode';

  @override
  String get dropFilesHint => 'Or drag and drop a file here';

  @override
  String get dropFilesActive => 'Drop to send';

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
  String get scannerBytesUnavailable =>
      'QR detected, but the camera returned no data. Keep scanning.';

  @override
  String get scannerInvalidFrame =>
      'A non-OneSend QR was detected. Keep scanning.';

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
  String get cimbarSendTitle => 'CIMBAR high-speed send';

  @override
  String get cimbarReceiveTitle => 'CIMBAR high-speed receive';

  @override
  String get cimbarUnsupported =>
      'The CIMBAR experimental transfer engine is available only on Android and iOS.';

  @override
  String get cimbarLoading => 'Loading the experimental engine…';

  @override
  String get cimbarPageReadySend =>
      'Experimental engine loaded. Choose a file.';

  @override
  String get cimbarPageReadyReceive =>
      'Experimental engine loaded. Tap start to request camera access.';

  @override
  String get cimbarEngineReady => 'Experimental engine ready · Mode B';

  @override
  String get cimbarPreparingFile => 'Preparing file…';

  @override
  String get cimbarPaused => 'Playback paused';

  @override
  String get cimbarPlaying => 'Playing';

  @override
  String get cimbarBroadcasting => 'File ready; broadcasting the visual code';

  @override
  String get cimbarDecoderReady => 'Decoder ready. Looking for CIMBAR.';

  @override
  String get cimbarDecoderReadyStart =>
      'Decoder ready. Tap start to request camera access.';

  @override
  String get cimbarCameraStarted => 'Camera started. Looking for CIMBAR.';

  @override
  String get cimbarDecoding => 'Decoding with the upstream worker';

  @override
  String get cimbarFileHeaderReceived =>
      'File header verified. Receiving chunks.';

  @override
  String get cimbarReceiving => 'Receiving verified bytes';

  @override
  String get cimbarRecoveredSaving => 'File fully recovered. Saving…';

  @override
  String get cimbarRecoveredNotSaved =>
      'File fully recovered, but it has not been saved.';

  @override
  String get cimbarReceiveComplete => 'Receive complete';

  @override
  String get cimbarLoadFailed => 'Loading failed. Try again.';

  @override
  String get cimbarTransferFailed => 'CIMBAR transfer failed. Try again.';

  @override
  String get cimbarReloading => 'Reloading the experimental engine…';

  @override
  String get cimbarRequestingCamera => 'Opening camera…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return 'File: $name · $size';
  }

  @override
  String get cimbarSendRate => 'Upstream reference: 106 KB/s · Mode B';

  @override
  String cimbarReceiveRate(Object speed) {
    return 'Upstream reference: 106 KB/s · Measured for this receive: $speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return 'Recovered $received / $expected · $seconds s';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return 'Recovered $received · $seconds s';
  }

  @override
  String get cimbarStartReceive => 'Start receiving (request camera)';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return 'Mobile CIMBAR files must be no larger than $maxSize.';
  }

  @override
  String get cimbarPageLoadError =>
      'The offline CIMBAR page could not be loaded. Try again.';

  @override
  String get cimbarBridgeError =>
      'The CIMBAR transfer sent an invalid event. Try again.';

  @override
  String get cimbarEngineError =>
      'The CIMBAR engine is unavailable. Try again.';

  @override
  String get cimbarCameraError =>
      'Camera access or decoding failed. Check permission and try again.';

  @override
  String get cimbarSendError =>
      'The CIMBAR sender could not prepare the file. Try again.';

  @override
  String get cimbarReceiveError =>
      'The CIMBAR receiver could not decode the file. Try again.';

  @override
  String get cimbarVerificationError =>
      'The received file could not be verified. Try again.';

  @override
  String get cimbarSaveError =>
      'The recovered file could not be saved. Try Retry save.';

  @override
  String get cimbarHistoryError =>
      'The file was saved, but its transfer history record could not be written.';

  @override
  String get cimbarAllFiles => 'All files';

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
