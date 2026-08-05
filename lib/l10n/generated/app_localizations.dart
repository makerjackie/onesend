import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OneSend'**
  String get appTitle;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @modeFast.
  ///
  /// In en, this message translates to:
  /// **'Standard (Recommended)'**
  String get modeFast;

  /// No description provided for @modeReliable.
  ///
  /// In en, this message translates to:
  /// **'Compatible'**
  String get modeReliable;

  /// No description provided for @modeTurboQr.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get modeTurboQr;

  /// No description provided for @modeCimbar.
  ///
  /// In en, this message translates to:
  /// **'Color (Experimental)'**
  String get modeCimbar;

  /// No description provided for @modeQr.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get modeQr;

  /// No description provided for @compatibilityMode.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get compatibilityMode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openFile;

  /// No description provided for @shareFile.
  ///
  /// In en, this message translates to:
  /// **'Share / forward'**
  String get shareFile;

  /// No description provided for @saveCopy.
  ///
  /// In en, this message translates to:
  /// **'Save a copy'**
  String get saveCopy;

  /// No description provided for @revealInFolder.
  ///
  /// In en, this message translates to:
  /// **'Reveal in folder'**
  String get revealInFolder;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About OneSend'**
  String get about;

  /// No description provided for @transferTab.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferTab;

  /// No description provided for @filesTab.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTab;

  /// No description provided for @filesTitle.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTitle;

  /// No description provided for @filesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage transfer history and received files.'**
  String get filesSubtitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System, light, or dark'**
  String get themeSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the theme setting. Try again.'**
  String get themeSaveError;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Release details, privacy, and open source.'**
  String get aboutSubtitle;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearHistoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Clear transfer history?'**
  String get clearHistoryQuestion;

  /// No description provided for @clearHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'This only removes records from OneSend. Saved files will not be deleted.'**
  String get clearHistoryDescription;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @homeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Send files,\nwith light.'**
  String get homeHeadline;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No network. No pairing.\nJust a screen and a camera.'**
  String get homeSubtitle;

  /// No description provided for @sendEyebrow.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get sendEyebrow;

  /// No description provided for @receiveEyebrow.
  ///
  /// In en, this message translates to:
  /// **'RECEIVE'**
  String get receiveEyebrow;

  /// No description provided for @sendFile.
  ///
  /// In en, this message translates to:
  /// **'Send a file'**
  String get sendFile;

  /// No description provided for @receiveFile.
  ///
  /// In en, this message translates to:
  /// **'Receive a file'**
  String get receiveFile;

  /// No description provided for @sendCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Put the code on screen and aim another device at it.'**
  String get sendCardDescription;

  /// No description provided for @receiveCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the camera and scan the changing visual code.'**
  String get receiveCardDescription;

  /// No description provided for @recentTransfers.
  ///
  /// In en, this message translates to:
  /// **'Recent transfers'**
  String get recentTransfers;

  /// No description provided for @recordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {0 records} =1 {1 record} other {# records}}'**
  String recordCount(num count);

  /// No description provided for @historyFooter.
  ///
  /// In en, this message translates to:
  /// **'Screen ↔ camera · Files travel only as light between two devices'**
  String get historyFooter;

  /// No description provided for @emptyHistory.
  ///
  /// In en, this message translates to:
  /// **'No transfer history yet. Choose a file to start your first optical transfer.'**
  String get emptyHistory;

  /// No description provided for @receivedAndVerified.
  ///
  /// In en, this message translates to:
  /// **'Received and verified'**
  String get receivedAndVerified;

  /// No description provided for @sendEnded.
  ///
  /// In en, this message translates to:
  /// **'Sending ended'**
  String get sendEnded;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @receivedFileActions.
  ///
  /// In en, this message translates to:
  /// **'Received file actions'**
  String get receivedFileActions;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 minute ago} other {# minutes ago}}'**
  String minutesAgo(num count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 hour ago} other {# hours ago}}'**
  String hoursAgo(num count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 day ago} other {# days ago}}'**
  String daysAgo(num count);

  /// No description provided for @monthDay.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String monthDay(Object day, Object month);

  /// No description provided for @settingsIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get settingsIntroTitle;

  /// No description provided for @settingsIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Choose transfer mode on the send screen.'**
  String get settingsIntroBody;

  /// No description provided for @transportSection.
  ///
  /// In en, this message translates to:
  /// **'TRANSFER'**
  String get transportSection;

  /// No description provided for @defaultTransferAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Default transfer algorithm'**
  String get defaultTransferAlgorithm;

  /// No description provided for @algorithmDescription.
  ///
  /// In en, this message translates to:
  /// **'Leave Standard selected for daily use. Switch to Compatible, Fast, or experimental Color in settings.'**
  String get algorithmDescription;

  /// No description provided for @theoreticalSpeed.
  ///
  /// In en, this message translates to:
  /// **'About {speed}'**
  String theoreticalSpeed(Object speed);

  /// No description provided for @fastModeDescription.
  ///
  /// In en, this message translates to:
  /// **'{speed}; daily default for most phones and a bright screen.'**
  String fastModeDescription(Object speed);

  /// No description provided for @reliableModeDescription.
  ///
  /// In en, this message translates to:
  /// **'{speed}; slower but steadier when light is poor or focus is hard.'**
  String reliableModeDescription(Object speed);

  /// No description provided for @turboModeDescription.
  ///
  /// In en, this message translates to:
  /// **'{speed}; faster, with tighter focus, exposure, and device demands.'**
  String turboModeDescription(Object speed);

  /// No description provided for @cimbarModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Experimental color code; higher peak speed, both sides must match, tougher conditions.'**
  String get cimbarModeDescription;

  /// No description provided for @modeSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the default transfer settings. Try again.'**
  String get modeSaveError;

  /// No description provided for @appSection.
  ///
  /// In en, this message translates to:
  /// **'APP'**
  String get appSection;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{language}'**
  String languageSubtitle(Object language);

  /// No description provided for @desktopUpdates.
  ///
  /// In en, this message translates to:
  /// **'Automatic updates'**
  String get desktopUpdates;

  /// No description provided for @desktopUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates and configure automatic checks on desktop.'**
  String get desktopUpdatesSubtitle;

  /// No description provided for @mobileOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Mobile stays offline: only transfer and language settings are available.'**
  String get mobileOfflineNote;

  /// No description provided for @languagePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get languagePickerTitle;

  /// No description provided for @languageSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language setting. Try again.'**
  String get languageSaveError;

  /// No description provided for @modeAccessibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'{mode}, {speed}'**
  String modeAccessibilityLabel(Object mode, Object speed);

  /// No description provided for @experimentalVisualTransfer.
  ///
  /// In en, this message translates to:
  /// **'Experimental offline visual transfer'**
  String get experimentalVisualTransfer;

  /// No description provided for @workingPrinciple.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get workingPrinciple;

  /// No description provided for @workingPrincipleBody.
  ///
  /// In en, this message translates to:
  /// **'A file is encoded into a changing sequence of visual codes. The sender displays them; the receiver reads and verifies each frame with its camera, then restores the file. The path is only light between the screen and camera.'**
  String get workingPrincipleBody;

  /// No description provided for @whyWeBuiltIt.
  ///
  /// In en, this message translates to:
  /// **'Why we built it'**
  String get whyWeBuiltIt;

  /// No description provided for @whyWeBuiltItBody.
  ///
  /// In en, this message translates to:
  /// **'Two devices can exchange a file without a network, account, or pairing. OneSend turns the screen and camera already on your devices into a simple offline channel.'**
  String get whyWeBuiltItBody;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Transfers do not use a network or server. Mobile needs camera access only.'**
  String get privacyBody;

  /// No description provided for @openPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Open privacy policy'**
  String get openPrivacyPolicy;

  /// No description provided for @cannotOpenPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Could not open the privacy policy. Try again.'**
  String get cannotOpenPrivacy;

  /// No description provided for @openSourceAndAuthor.
  ///
  /// In en, this message translates to:
  /// **'Open source & author'**
  String get openSourceAndAuthor;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @github.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// No description provided for @openGithub.
  ///
  /// In en, this message translates to:
  /// **'Open GitHub'**
  String get openGithub;

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get opening;

  /// No description provided for @versionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Version unavailable'**
  String get versionUnavailable;

  /// No description provided for @readingVersion.
  ///
  /// In en, this message translates to:
  /// **'Reading version…'**
  String get readingVersion;

  /// No description provided for @cannotOpenGithub.
  ///
  /// In en, this message translates to:
  /// **'Could not open the GitHub page. Try again.'**
  String get cannotOpenGithub;

  /// No description provided for @aboutFooter.
  ///
  /// In en, this message translates to:
  /// **'OneSend · optical file transfer'**
  String get aboutFooter;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @settingsVersionFooter.
  ///
  /// In en, this message translates to:
  /// **'{version}'**
  String settingsVersionFooter(String version);

  /// No description provided for @acknowledgments.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgments'**
  String get acknowledgments;

  /// No description provided for @acknowledgmentsIntro.
  ///
  /// In en, this message translates to:
  /// **'OneSend is grateful to these open-source projects for ideas, reference designs, and assets:'**
  String get acknowledgmentsIntro;

  /// No description provided for @creditDecimen.
  ///
  /// In en, this message translates to:
  /// **'decimen-optical-transfer — LT-code / protocol foundation (MIT)'**
  String get creditDecimen;

  /// No description provided for @creditQrDataTransfer.
  ///
  /// In en, this message translates to:
  /// **'qr-data-transfer — public architecture reviewed; no code included'**
  String get creditQrDataTransfer;

  /// No description provided for @creditLibcimbar.
  ///
  /// In en, this message translates to:
  /// **'libcimbar v0.6.7c — experimental color visual code (MPL-2.0)'**
  String get creditLibcimbar;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report issues on GitHub'**
  String get sendFeedbackSubtitle;

  /// No description provided for @openGithubIssues.
  ///
  /// In en, this message translates to:
  /// **'Open GitHub Issues'**
  String get openGithubIssues;

  /// No description provided for @cannotOpenGithubIssues.
  ///
  /// In en, this message translates to:
  /// **'Could not open GitHub Issues. Try again.'**
  String get cannotOpenGithubIssues;

  /// No description provided for @chooseAFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get chooseAFile;

  /// No description provided for @sendFileDescription.
  ///
  /// In en, this message translates to:
  /// **'The file becomes a changing sequence of visual codes.\nUp to {maxSize}; start with a small file for the first test.'**
  String sendFileDescription(Object maxSize);

  /// No description provided for @newTransferStatus.
  ///
  /// In en, this message translates to:
  /// **'New sends use {mode} mode · theoretical rate about {speed}'**
  String newTransferStatus(Object mode, Object speed);

  /// No description provided for @transferModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer mode'**
  String get transferModeLabel;

  /// No description provided for @dropFilesHint.
  ///
  /// In en, this message translates to:
  /// **'Or drag and drop a file here'**
  String get dropFilesHint;

  /// No description provided for @dropFilesActive.
  ///
  /// In en, this message translates to:
  /// **'Drop to send'**
  String get dropFilesActive;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading…'**
  String get reading;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get chooseFile;

  /// No description provided for @sampleVideo.
  ///
  /// In en, this message translates to:
  /// **'Send the built-in test video'**
  String get sampleVideo;

  /// No description provided for @encodedPayloadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The encoded file is larger than the optical transfer limit.'**
  String get encodedPayloadTooLarge;

  /// No description provided for @modeBadge.
  ///
  /// In en, this message translates to:
  /// **'{mode} mode'**
  String modeBadge(Object mode);

  /// No description provided for @broadcasting.
  ///
  /// In en, this message translates to:
  /// **'Broadcasting the changing visual code'**
  String get broadcasting;

  /// No description provided for @pausedPlayback.
  ///
  /// In en, this message translates to:
  /// **'Playback paused'**
  String get pausedPlayback;

  /// No description provided for @cameraAim.
  ///
  /// In en, this message translates to:
  /// **'Aim the other device\'s camera at this white area'**
  String get cameraAim;

  /// No description provided for @passAndFrames.
  ///
  /// In en, this message translates to:
  /// **'Pass {pass} · {frames} frames sent'**
  String passAndFrames(Object frames, Object pass);

  /// No description provided for @runningTime.
  ///
  /// In en, this message translates to:
  /// **'Running {duration}'**
  String runningTime(Object duration);

  /// No description provided for @theoreticalRate.
  ///
  /// In en, this message translates to:
  /// **'Theoretical rate {speed}'**
  String theoreticalRate(Object speed);

  /// No description provided for @currentRate.
  ///
  /// In en, this message translates to:
  /// **'Current rate {speed}'**
  String currentRate(Object speed);

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @endTransfer.
  ///
  /// In en, this message translates to:
  /// **'End transfer'**
  String get endTransfer;

  /// No description provided for @sendAnother.
  ///
  /// In en, this message translates to:
  /// **'Send another file'**
  String get sendAnother;

  /// No description provided for @chooseOtherFile.
  ///
  /// In en, this message translates to:
  /// **'Choose another file'**
  String get chooseOtherFile;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Files must be no larger than {maxSize}.'**
  String fileTooLarge(Object maxSize);

  /// No description provided for @cannotReadFile.
  ///
  /// In en, this message translates to:
  /// **'OneSend could not read this file.'**
  String get cannotReadFile;

  /// No description provided for @sampleVideoEmpty.
  ///
  /// In en, this message translates to:
  /// **'The built-in test video is unavailable.'**
  String get sampleVideoEmpty;

  /// No description provided for @sampleVideoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The built-in test video is larger than {maxSize}.'**
  String sampleVideoTooLarge(Object maxSize);

  /// No description provided for @genericTransferError.
  ///
  /// In en, this message translates to:
  /// **'Transfer could not start. Try again.'**
  String get genericTransferError;

  /// No description provided for @scanReceive.
  ///
  /// In en, this message translates to:
  /// **'Scan to receive'**
  String get scanReceive;

  /// No description provided for @torch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get torch;

  /// No description provided for @checkingAndSaving.
  ///
  /// In en, this message translates to:
  /// **'Verifying and saving…'**
  String get checkingAndSaving;

  /// No description provided for @pausedKeepProgress.
  ///
  /// In en, this message translates to:
  /// **'Paused. Tap resume to keep the current progress.'**
  String get pausedKeepProgress;

  /// No description provided for @lookingForSender.
  ///
  /// In en, this message translates to:
  /// **'Looking for a sender…'**
  String get lookingForSender;

  /// No description provided for @lockedModeCollecting.
  ///
  /// In en, this message translates to:
  /// **'Locked to {mode} mode · collecting visual codes'**
  String lockedModeCollecting(Object mode);

  /// No description provided for @scanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Keep the visual code fully inside the frame and hold the device steady.'**
  String get scanInstruction;

  /// No description provided for @scannerBytesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'QR detected, but the camera returned no data. Keep scanning.'**
  String get scannerBytesUnavailable;

  /// No description provided for @scannerInvalidFrame.
  ///
  /// In en, this message translates to:
  /// **'A non-OneSend QR was detected. Keep scanning.'**
  String get scannerInvalidFrame;

  /// No description provided for @desktopCameraInstruction.
  ///
  /// In en, this message translates to:
  /// **'Desktop camera decoding uses screenshots, so it is slower than mobile.'**
  String get desktopCameraInstruction;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get verifying;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @waitingFirstFrame.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first frame'**
  String get waitingFirstFrame;

  /// No description provided for @fountainProgress.
  ///
  /// In en, this message translates to:
  /// **'{frames} frames · Fountain recovery'**
  String fountainProgress(Object frames);

  /// No description provided for @blockProgress.
  ///
  /// In en, this message translates to:
  /// **'{frames} frames · {solved}/{blocks} blocks'**
  String blockProgress(Object blocks, Object frames, Object solved);

  /// No description provided for @modeAndSize.
  ///
  /// In en, this message translates to:
  /// **'{mode} · {size}'**
  String modeAndSize(Object mode, Object size);

  /// No description provided for @resumeScan.
  ///
  /// In en, this message translates to:
  /// **'Resume scan'**
  String get resumeScan;

  /// No description provided for @pauseScan.
  ///
  /// In en, this message translates to:
  /// **'Pause scan'**
  String get pauseScan;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @receivedComplete.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get receivedComplete;

  /// No description provided for @verifiedNotSaved.
  ///
  /// In en, this message translates to:
  /// **'The file was verified, but could not be saved yet.'**
  String get verifiedNotSaved;

  /// No description provided for @verifiedSaved.
  ///
  /// In en, this message translates to:
  /// **'The file was verified and saved on this device.'**
  String get verifiedSaved;

  /// No description provided for @retrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry save'**
  String get retrySave;

  /// No description provided for @continueReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receive another'**
  String get continueReceiving;

  /// No description provided for @recordWriteError.
  ///
  /// In en, this message translates to:
  /// **'The file was saved, but its history record could not be written: {error}'**
  String recordWriteError(Object error);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// No description provided for @fileActions.
  ///
  /// In en, this message translates to:
  /// **'File actions'**
  String get fileActions;

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved location'**
  String get saveLocation;

  /// No description provided for @unrecordedLocation.
  ///
  /// In en, this message translates to:
  /// **'No saved location was recorded.'**
  String get unrecordedLocation;

  /// No description provided for @fileMissing.
  ///
  /// In en, this message translates to:
  /// **'The file is missing; it may have been moved or deleted.'**
  String get fileMissing;

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String savedTo(Object path);

  /// No description provided for @iosSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'Files > On My iPhone/iPad > OneSend > Received > {name}'**
  String iosSavedLocation(Object name);

  /// No description provided for @androidSavedLocation.
  ///
  /// In en, this message translates to:
  /// **'Saved in app storage: {name}. Use Save a copy to choose a visible folder.'**
  String androidSavedLocation(Object name);

  /// No description provided for @copyExported.
  ///
  /// In en, this message translates to:
  /// **'Copy exported: {name} (the system file picker chose the location)'**
  String copyExported(Object name);

  /// No description provided for @copyExportedDesktop.
  ///
  /// In en, this message translates to:
  /// **'Copy exported to: {path}'**
  String copyExportedDesktop(Object path);

  /// No description provided for @fileOperationError.
  ///
  /// In en, this message translates to:
  /// **'File operation failed. Try again.'**
  String get fileOperationError;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'The file does not exist.'**
  String get fileNotFound;

  /// No description provided for @fileAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this file.'**
  String get fileAccessDenied;

  /// No description provided for @operationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Operation cancelled.'**
  String get operationCancelled;

  /// No description provided for @unsupportedOperation.
  ///
  /// In en, this message translates to:
  /// **'This operation is not supported on the current device.'**
  String get unsupportedOperation;

  /// No description provided for @openFileError.
  ///
  /// In en, this message translates to:
  /// **'The system could not open this file.'**
  String get openFileError;

  /// No description provided for @shareFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not share this file. Try again.'**
  String get shareFileError;

  /// No description provided for @revealFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not reveal the file in its folder. Try again.'**
  String get revealFileError;

  /// No description provided for @saveFileError.
  ///
  /// In en, this message translates to:
  /// **'Could not export the file. Try again.'**
  String get saveFileError;

  /// No description provided for @locationPathUnknown.
  ///
  /// In en, this message translates to:
  /// **'The saved location is unknown.'**
  String get locationPathUnknown;

  /// No description provided for @updateAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Offline file transfer between a screen and a camera.'**
  String get updateAppDescription;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get currentVersion;

  /// No description provided for @automaticChecks.
  ///
  /// In en, this message translates to:
  /// **'Check for updates automatically'**
  String get automaticChecks;

  /// No description provided for @automaticChecksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check quietly once a day and notify you only when a new version is found.'**
  String get automaticChecksSubtitle;

  /// No description provided for @downloadPage.
  ///
  /// In en, this message translates to:
  /// **'Download page'**
  String get downloadPage;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'OneSend {version} is available'**
  String updateAvailable(Object version);

  /// No description provided for @releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get releaseNotes;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading and verifying…'**
  String get downloading;

  /// No description provided for @downloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading and verifying {percent}%'**
  String downloadingPercent(Object percent);

  /// No description provided for @viewRelease.
  ///
  /// In en, this message translates to:
  /// **'View release page'**
  String get viewRelease;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @downloadUpdate.
  ///
  /// In en, this message translates to:
  /// **'Download update'**
  String get downloadUpdate;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'You already have the latest version.'**
  String get latestVersion;

  /// No description provided for @updateCheckWindowOpened.
  ///
  /// In en, this message translates to:
  /// **'The update check window is open.'**
  String get updateCheckWindowOpened;

  /// No description provided for @unsupportedUpdate.
  ///
  /// In en, this message translates to:
  /// **'In-app updates are not supported on this platform.'**
  String get unsupportedUpdate;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Try again later.'**
  String get updateCheckFailed;

  /// No description provided for @automaticUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Could not change automatic update settings.'**
  String get automaticUpdateError;

  /// No description provided for @downloadPageError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the download page.'**
  String get downloadPageError;

  /// No description provided for @releasePageError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the release page.'**
  String get releasePageError;

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'The update package could not be downloaded. Try again later.'**
  String get downloadError;

  /// No description provided for @cimbarSendTitle.
  ///
  /// In en, this message translates to:
  /// **'CIMBAR high-speed send'**
  String get cimbarSendTitle;

  /// No description provided for @cimbarReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'CIMBAR high-speed receive'**
  String get cimbarReceiveTitle;

  /// No description provided for @cimbarUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The CIMBAR experimental transfer engine is available only on Android and iOS.'**
  String get cimbarUnsupported;

  /// No description provided for @cimbarLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the experimental engine…'**
  String get cimbarLoading;

  /// No description provided for @cimbarPageReadySend.
  ///
  /// In en, this message translates to:
  /// **'Experimental engine loaded. Choose a file.'**
  String get cimbarPageReadySend;

  /// No description provided for @cimbarPageReadyReceive.
  ///
  /// In en, this message translates to:
  /// **'Experimental engine loaded. Tap start to request camera access.'**
  String get cimbarPageReadyReceive;

  /// No description provided for @cimbarEngineReady.
  ///
  /// In en, this message translates to:
  /// **'Experimental engine ready · Mode B'**
  String get cimbarEngineReady;

  /// No description provided for @cimbarPreparingFile.
  ///
  /// In en, this message translates to:
  /// **'Preparing file…'**
  String get cimbarPreparingFile;

  /// No description provided for @cimbarPaused.
  ///
  /// In en, this message translates to:
  /// **'Playback paused'**
  String get cimbarPaused;

  /// No description provided for @cimbarPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get cimbarPlaying;

  /// No description provided for @cimbarBroadcasting.
  ///
  /// In en, this message translates to:
  /// **'File ready; broadcasting the visual code'**
  String get cimbarBroadcasting;

  /// No description provided for @cimbarDecoderReady.
  ///
  /// In en, this message translates to:
  /// **'Decoder ready. Looking for CIMBAR.'**
  String get cimbarDecoderReady;

  /// No description provided for @cimbarDecoderReadyStart.
  ///
  /// In en, this message translates to:
  /// **'Decoder ready. Tap start to request camera access.'**
  String get cimbarDecoderReadyStart;

  /// No description provided for @cimbarCameraStarted.
  ///
  /// In en, this message translates to:
  /// **'Camera started. Looking for CIMBAR.'**
  String get cimbarCameraStarted;

  /// No description provided for @cimbarDecoding.
  ///
  /// In en, this message translates to:
  /// **'Decoding with the upstream worker'**
  String get cimbarDecoding;

  /// No description provided for @cimbarFileHeaderReceived.
  ///
  /// In en, this message translates to:
  /// **'File header verified. Receiving chunks.'**
  String get cimbarFileHeaderReceived;

  /// No description provided for @cimbarReceiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving verified bytes'**
  String get cimbarReceiving;

  /// No description provided for @cimbarRecoveredSaving.
  ///
  /// In en, this message translates to:
  /// **'File fully recovered. Saving…'**
  String get cimbarRecoveredSaving;

  /// No description provided for @cimbarRecoveredNotSaved.
  ///
  /// In en, this message translates to:
  /// **'File fully recovered, but it has not been saved.'**
  String get cimbarRecoveredNotSaved;

  /// No description provided for @cimbarReceiveComplete.
  ///
  /// In en, this message translates to:
  /// **'Receive complete'**
  String get cimbarReceiveComplete;

  /// No description provided for @cimbarLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading failed. Try again.'**
  String get cimbarLoadFailed;

  /// No description provided for @cimbarTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'CIMBAR transfer failed. Try again.'**
  String get cimbarTransferFailed;

  /// No description provided for @cimbarReloading.
  ///
  /// In en, this message translates to:
  /// **'Reloading the experimental engine…'**
  String get cimbarReloading;

  /// No description provided for @cimbarRequestingCamera.
  ///
  /// In en, this message translates to:
  /// **'Opening camera…'**
  String get cimbarRequestingCamera;

  /// No description provided for @cimbarFileInfo.
  ///
  /// In en, this message translates to:
  /// **'File: {name} · {size}'**
  String cimbarFileInfo(Object name, Object size);

  /// No description provided for @cimbarSendRate.
  ///
  /// In en, this message translates to:
  /// **'Upstream reference: 106 KB/s · Mode B'**
  String get cimbarSendRate;

  /// No description provided for @cimbarReceiveRate.
  ///
  /// In en, this message translates to:
  /// **'Upstream reference: 106 KB/s · Measured for this receive: {speed} KB/s'**
  String cimbarReceiveRate(Object speed);

  /// No description provided for @cimbarReceiveProgress.
  ///
  /// In en, this message translates to:
  /// **'Recovered {received} / {expected} · {seconds} s'**
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  );

  /// No description provided for @cimbarReceiveProgressNoTotal.
  ///
  /// In en, this message translates to:
  /// **'Recovered {received} · {seconds} s'**
  String cimbarReceiveProgressNoTotal(Object received, Object seconds);

  /// No description provided for @cimbarStartReceive.
  ///
  /// In en, this message translates to:
  /// **'Start receiving (request camera)'**
  String get cimbarStartReceive;

  /// No description provided for @cimbarFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Mobile CIMBAR files must be no larger than {maxSize}.'**
  String cimbarFileTooLarge(Object maxSize);

  /// No description provided for @cimbarPageLoadError.
  ///
  /// In en, this message translates to:
  /// **'The offline CIMBAR page could not be loaded. Try again.'**
  String get cimbarPageLoadError;

  /// No description provided for @cimbarBridgeError.
  ///
  /// In en, this message translates to:
  /// **'The CIMBAR transfer sent an invalid event. Try again.'**
  String get cimbarBridgeError;

  /// No description provided for @cimbarEngineError.
  ///
  /// In en, this message translates to:
  /// **'The CIMBAR engine is unavailable. Try again.'**
  String get cimbarEngineError;

  /// No description provided for @cimbarCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera access or decoding failed. Check permission and try again.'**
  String get cimbarCameraError;

  /// No description provided for @cimbarSendError.
  ///
  /// In en, this message translates to:
  /// **'The CIMBAR sender could not prepare the file. Try again.'**
  String get cimbarSendError;

  /// No description provided for @cimbarReceiveError.
  ///
  /// In en, this message translates to:
  /// **'The CIMBAR receiver could not decode the file. Try again.'**
  String get cimbarReceiveError;

  /// No description provided for @cimbarVerificationError.
  ///
  /// In en, this message translates to:
  /// **'The received file could not be verified. Try again.'**
  String get cimbarVerificationError;

  /// No description provided for @cimbarSaveError.
  ///
  /// In en, this message translates to:
  /// **'The recovered file could not be saved. Try Retry save.'**
  String get cimbarSaveError;

  /// No description provided for @cimbarHistoryError.
  ///
  /// In en, this message translates to:
  /// **'The file was saved, but its transfer history record could not be written.'**
  String get cimbarHistoryError;

  /// No description provided for @cimbarAllFiles.
  ///
  /// In en, this message translates to:
  /// **'All files'**
  String get cimbarAllFiles;

  /// No description provided for @cimbarSelectedFileName.
  ///
  /// In en, this message translates to:
  /// **'selected.bin'**
  String get cimbarSelectedFileName;

  /// No description provided for @cimbarReceivedFileName.
  ///
  /// In en, this message translates to:
  /// **'received.bin'**
  String get cimbarReceivedFileName;

  /// No description provided for @cimbarBytes.
  ///
  /// In en, this message translates to:
  /// **'{value} B'**
  String cimbarBytes(Object value);

  /// No description provided for @cimbarKibibytes.
  ///
  /// In en, this message translates to:
  /// **'{value} KiB'**
  String cimbarKibibytes(Object value);

  /// No description provided for @cimbarMebibytes.
  ///
  /// In en, this message translates to:
  /// **'{value} MiB'**
  String cimbarMebibytes(Object value);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(Object hours, Object minutes);

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes}:{seconds}'**
  String durationMinutesSeconds(Object minutes, Object seconds);

  /// No description provided for @errorDetails.
  ///
  /// In en, this message translates to:
  /// **'{message}'**
  String errorDetails(Object message);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'pt',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
