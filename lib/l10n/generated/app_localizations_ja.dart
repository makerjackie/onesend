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
