// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'OneSend';

  @override
  String get followSystem => 'Systemeinstellung folgen';

  @override
  String get language => 'Sprache';

  @override
  String get modeFast => 'Standard (empfohlen)';

  @override
  String get modeReliable => 'Kompatibel';

  @override
  String get modeTurboQr => 'Schnell';

  @override
  String get modeCimbar => 'Farbe (experimentell)';

  @override
  String get modeQr => 'QR-Code';

  @override
  String get compatibilityMode => 'Kompatibilität';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get done => 'Fertig';

  @override
  String get close => 'Schließen';

  @override
  String get openFile => 'Öffnen';

  @override
  String get shareFile => 'Teilen / weiterleiten';

  @override
  String get saveCopy => 'Kopie speichern';

  @override
  String get revealInFolder => 'Im Ordner anzeigen';

  @override
  String get more => 'Mehr';

  @override
  String get settings => 'Einstellungen';

  @override
  String get about => 'Über OneSend';

  @override
  String get transferTab => 'Übertragung';

  @override
  String get filesTab => 'Dateien';

  @override
  String get filesTitle => 'Dateien';

  @override
  String get filesSubtitle =>
      'Übertragungsverlauf und empfangene Dateien verwalten.';

  @override
  String get theme => 'Darstellung';

  @override
  String get themeSubtitle => 'System, hell oder dunkel';

  @override
  String get themeSystem => 'Systemeinstellung';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSaveError =>
      'Die Darstellung konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String get aboutSubtitle => 'Version, Datenschutz und Open Source.';

  @override
  String get clearHistory => 'Verlauf löschen';

  @override
  String get clearHistoryQuestion => 'Übertragungsverlauf löschen?';

  @override
  String get clearHistoryDescription =>
      'Dadurch werden nur Einträge aus OneSend entfernt. Gespeicherte Dateien werden nicht gelöscht.';

  @override
  String get clearAction => 'Löschen';

  @override
  String get homeHeadline => 'Dateien senden,\nmit Licht.';

  @override
  String get homeSubtitle =>
      'Kein Netzwerk. Keine Kopplung.\nNur ein Bildschirm und eine Kamera.';

  @override
  String get sendEyebrow => 'SENDEN';

  @override
  String get receiveEyebrow => 'EMPFANGEN';

  @override
  String get sendFile => 'Datei senden';

  @override
  String get receiveFile => 'Datei empfangen';

  @override
  String get sendCardDescription =>
      'Zeige den Code auf dem Bildschirm an und richte ein anderes Gerät darauf.';

  @override
  String get receiveCardDescription =>
      'Öffne die Kamera und scanne den wechselnden visuellen Code.';

  @override
  String get recentTransfers => 'Letzte Übertragungen';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# Einträge',
      one: '1 Eintrag',
      zero: '0 Einträge',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter =>
      'Bildschirm ↔ Kamera · Dateien werden zwischen zwei Geräten nur als Licht übertragen';

  @override
  String get emptyHistory =>
      'Noch kein Übertragungsverlauf. Wähle eine Datei, um deine erste optische Übertragung zu starten.';

  @override
  String get receivedAndVerified => 'Empfangen und verifiziert';

  @override
  String get sendEnded => 'Senden beendet';

  @override
  String get sent => 'Gesendet';

  @override
  String get receivedFileActions => 'Aktionen für die empfangene Datei';

  @override
  String get justNow => 'Gerade eben';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor # Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor # Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor # Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle =>
      'Passe die nächste Übertragung an dein Gerät an.';

  @override
  String get settingsIntroBody =>
      'Der Standardmodus wird für neue Übertragungen verwendet.';

  @override
  String get transportSection => 'ÜBERTRAGUNG';

  @override
  String get defaultTransferAlgorithm => 'Standard-Übertragungsalgorithmus';

  @override
  String get algorithmDescription =>
      'Standard für den Alltag belassen. In den Einstellungen: Kompatibel, Schnell oder experimentelle Farbe.';

  @override
  String theoreticalSpeed(Object speed) {
    return 'Etwa $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed; Alltag-Standard für die meisten Handys und helle Bildschirme.';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed; langsamer, aber stabiler bei schlechtem Licht oder schwierigem Fokus.';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed; schneller, braucht bessere Fokussierung, Belichtung und Geräte.';
  }

  @override
  String get cimbarModeDescription =>
      'Experimenteller Farbcode; höhere Spitze, beide Seiten müssen passen, höhere Anforderungen.';

  @override
  String get modeSaveError =>
      'Die Standard-Übertragungseinstellungen konnten nicht gespeichert werden. Versuche es erneut.';

  @override
  String get appSection => 'APP';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => 'Automatische Updates';

  @override
  String get desktopUpdatesSubtitle =>
      'Auf dem Desktop nach Updates suchen und automatische Prüfungen konfigurieren.';

  @override
  String get mobileOfflineNote =>
      'Mobilgeräte bleiben offline: Es sind nur Übertragungs- und Spracheinstellungen verfügbar.';

  @override
  String get languagePickerTitle => 'Sprache auswählen';

  @override
  String get languageSaveError =>
      'Die Spracheinstellung konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode, $speed';
  }

  @override
  String get experimentalVisualTransfer =>
      'Experimentelle visuelle Offline-Übertragung';

  @override
  String get workingPrinciple => 'Funktionsweise';

  @override
  String get workingPrincipleBody =>
      'Eine Datei wird in eine wechselnde Folge visueller Codes kodiert. Der Sender zeigt sie an; der Empfänger liest und verifiziert jedes Einzelbild mit seiner Kamera und stellt anschließend die Datei wieder her. Der Übertragungsweg besteht nur aus Licht zwischen Bildschirm und Kamera.';

  @override
  String get whyWeBuiltIt => 'Warum wir OneSend entwickelt haben';

  @override
  String get whyWeBuiltItBody =>
      'Zwei Geräte können eine Datei ohne Netzwerk, Konto oder Kopplung austauschen. OneSend macht den Bildschirm und die Kamera deiner Geräte zu einem einfachen Offline-Kanal.';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get privacyBody =>
      'Übertragungen verwenden weder Netzwerk noch Server. Auf Mobilgeräten ist nur Kamerazugriff erforderlich.';

  @override
  String get openPrivacyPolicy => 'Datenschutzerklärung öffnen';

  @override
  String get cannotOpenPrivacy =>
      'Datenschutzerklärung konnte nicht geöffnet werden. Versuche es erneut.';

  @override
  String get openSourceAndAuthor => 'Open Source & Autor';

  @override
  String get author => 'Autor';

  @override
  String get license => 'Lizenz';

  @override
  String get version => 'Version';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => 'GitHub öffnen';

  @override
  String get opening => 'Wird geöffnet…';

  @override
  String get versionUnavailable => 'Version nicht verfügbar';

  @override
  String get readingVersion => 'Version wird gelesen…';

  @override
  String get cannotOpenGithub =>
      'Die GitHub-Seite konnte nicht geöffnet werden. Versuche es erneut.';

  @override
  String get aboutFooter => 'OneSend · optische Dateiübertragung';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String settingsVersionFooter(String version) {
    return '$version';
  }

  @override
  String get acknowledgments => 'Danksagungen';

  @override
  String get acknowledgmentsIntro =>
      'OneSend dankt diesen Open-Source-Projekten für Ideen und Assets:';

  @override
  String get creditDecimen =>
      'decimen-optical-transfer — LT-Code / Protokollgrundlage (MIT)';

  @override
  String get creditQrDataTransfer =>
      'qr-data-transfer — öffentliche Architektur geprüft; kein Code übernommen';

  @override
  String get creditLibcimbar =>
      'libcimbar v0.6.7c — experimenteller Farb-Visualcode (MPL-2.0)';

  @override
  String get sendFeedback => 'Feedback senden';

  @override
  String get sendFeedbackSubtitle => 'Issue auf GitHub melden';

  @override
  String get openGithubIssues => 'GitHub Issues öffnen';

  @override
  String get cannotOpenGithubIssues =>
      'GitHub Issues konnte nicht geöffnet werden. Versuche es erneut.';

  @override
  String get chooseAFile => 'Datei auswählen';

  @override
  String sendFileDescription(Object maxSize) {
    return 'Die Datei wird in eine wechselnde Folge visueller Codes umgewandelt.\nBis zu $maxSize; beginne beim ersten Test mit einer kleinen Datei.';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return 'Neue Übertragungen nutzen den Modus $mode · theoretische Rate: etwa $speed';
  }

  @override
  String get transferModeLabel => 'Übertragungsmodus';

  @override
  String get dropFilesHint => 'Oder ziehe eine Datei hierher';

  @override
  String get dropFilesActive => 'Zum Senden ablegen';

  @override
  String get reading => 'Wird gelesen…';

  @override
  String get chooseFile => 'Datei auswählen';

  @override
  String get sampleVideo => 'Integriertes Testvideo senden';

  @override
  String get encodedPayloadTooLarge =>
      'Die kodierte Datei überschreitet das Limit für optische Übertragungen.';

  @override
  String modeBadge(Object mode) {
    return 'Modus: $mode';
  }

  @override
  String get broadcasting => 'Wechselnder visueller Code wird übertragen';

  @override
  String get pausedPlayback => 'Wiedergabe pausiert';

  @override
  String get cameraAim =>
      'Richte die Kamera des anderen Geräts auf diesen weißen Bereich';

  @override
  String passAndFrames(Object frames, Object pass) {
    return 'Durchgang $pass · $frames Einzelbilder gesendet';
  }

  @override
  String runningTime(Object duration) {
    return 'Laufzeit: $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return 'Theoretische Rate: $speed';
  }

  @override
  String currentRate(Object speed) {
    return 'Aktuelle Rate: $speed';
  }

  @override
  String get resume => 'Fortsetzen';

  @override
  String get pause => 'Pausieren';

  @override
  String get endTransfer => 'Übertragung beenden';

  @override
  String get sendAnother => 'Weitere Datei senden';

  @override
  String get chooseOtherFile => 'Andere Datei auswählen';

  @override
  String fileTooLarge(Object maxSize) {
    return 'Dateien dürfen nicht größer als $maxSize sein.';
  }

  @override
  String get cannotReadFile => 'OneSend konnte diese Datei nicht lesen.';

  @override
  String get sampleVideoEmpty =>
      'Das integrierte Testvideo ist nicht verfügbar.';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return 'Das integrierte Testvideo ist größer als $maxSize.';
  }

  @override
  String get genericTransferError =>
      'Die Übertragung konnte nicht gestartet werden. Versuche es erneut.';

  @override
  String get scanReceive => 'Zum Empfangen scannen';

  @override
  String get torch => 'Taschenlampe';

  @override
  String get checkingAndSaving => 'Wird verifiziert und gespeichert…';

  @override
  String get pausedKeepProgress =>
      'Pausiert. Tippe auf „Fortsetzen“, damit der aktuelle Fortschritt erhalten bleibt.';

  @override
  String get lookingForSender => 'Suche nach einem Sender…';

  @override
  String lockedModeCollecting(Object mode) {
    return 'Modus $mode festgelegt · visuelle Codes werden gesammelt';
  }

  @override
  String get scanInstruction =>
      'Halte den visuellen Code vollständig im Bildausschnitt und das Gerät ruhig.';

  @override
  String get scannerBytesUnavailable =>
      'QR-Code erkannt, aber die Kamera lieferte keine Daten. Scan läuft weiter.';

  @override
  String get scannerInvalidFrame =>
      'Ein QR-Code ohne OneSend-Daten wurde erkannt. Scan läuft weiter.';

  @override
  String get desktopCameraInstruction =>
      'Die Dekodierung mit der Desktop-Kamera erfolgt über Bildschirmfotos und ist daher langsamer als auf Mobilgeräten.';

  @override
  String get verifying => 'Wird verifiziert…';

  @override
  String get paused => 'Pausiert';

  @override
  String get waitingFirstFrame => 'Warte auf das erste Einzelbild';

  @override
  String fountainProgress(Object frames) {
    return '$frames Einzelbilder · Fountain-Wiederherstellung';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames Einzelbilder · $solved/$blocks Blöcke gelöst';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => 'Scan fortsetzen';

  @override
  String get pauseScan => 'Scan pausieren';

  @override
  String get restart => 'Neu starten';

  @override
  String get receivedComplete => 'Empfangen';

  @override
  String get verifiedNotSaved =>
      'Die Datei wurde verifiziert, konnte aber noch nicht gespeichert werden.';

  @override
  String get verifiedSaved =>
      'Die Datei wurde verifiziert und auf diesem Gerät gespeichert.';

  @override
  String get retrySave => 'Erneut speichern';

  @override
  String get continueReceiving => 'Weitere Datei empfangen';

  @override
  String recordWriteError(Object error) {
    return 'Die Datei wurde gespeichert, aber der Verlaufseintrag konnte nicht geschrieben werden: $error';
  }

  @override
  String saveFailed(Object error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String get fileActions => 'Dateiaktionen';

  @override
  String get saveLocation => 'Speicherort';

  @override
  String get unrecordedLocation => 'Kein Speicherort erfasst.';

  @override
  String get fileMissing =>
      'Die Datei fehlt; sie wurde möglicherweise verschoben oder gelöscht.';

  @override
  String savedTo(Object path) {
    return 'Gespeichert unter: $path';
  }

  @override
  String iosSavedLocation(Object name) {
    return 'Dateien > Auf meinem iPhone/iPad > OneSend > Received > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return 'Im App-Speicher gespeichert: $name. Verwende „Kopie speichern“, um einen sichtbaren Ordner auszuwählen.';
  }

  @override
  String copyExported(Object name) {
    return 'Kopie exportiert: $name (der System-Dateiauswahldialog hat den Speicherort gewählt)';
  }

  @override
  String copyExportedDesktop(Object path) {
    return 'Kopie exportiert nach: $path';
  }

  @override
  String get fileOperationError =>
      'Dateivorgang fehlgeschlagen. Versuche es erneut.';

  @override
  String get fileNotFound => 'Die Datei existiert nicht.';

  @override
  String get fileAccessDenied =>
      'Du hast keine Berechtigung, auf diese Datei zuzugreifen.';

  @override
  String get operationCancelled => 'Vorgang abgebrochen.';

  @override
  String get unsupportedOperation =>
      'Dieser Vorgang wird auf dem aktuellen Gerät nicht unterstützt.';

  @override
  String get openFileError => 'Das System konnte diese Datei nicht öffnen.';

  @override
  String get shareFileError =>
      'Diese Datei konnte nicht geteilt werden. Versuche es erneut.';

  @override
  String get revealFileError =>
      'Die Datei konnte nicht in ihrem Ordner angezeigt werden. Versuche es erneut.';

  @override
  String get saveFileError =>
      'Die Datei konnte nicht exportiert werden. Versuche es erneut.';

  @override
  String get locationPathUnknown => 'Der Speicherort ist unbekannt.';

  @override
  String get updateAppDescription =>
      'Offline-Dateiübertragung zwischen Bildschirm und Kamera.';

  @override
  String get currentVersion => 'Aktuelle Version';

  @override
  String get automaticChecks => 'Automatisch nach Updates suchen';

  @override
  String get automaticChecksSubtitle =>
      'Einmal täglich unauffällig prüfen; Benachrichtigung nur bei einer neuen Version.';

  @override
  String get downloadPage => 'Downloadseite';

  @override
  String get checking => 'Wird geprüft…';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version ist verfügbar';
  }

  @override
  String get releaseNotes => 'Neuigkeiten';

  @override
  String get downloading => 'Wird heruntergeladen und verifiziert…';

  @override
  String downloadingPercent(Object percent) {
    return 'Wird heruntergeladen und verifiziert: $percent %';
  }

  @override
  String get viewRelease => 'Versionsseite anzeigen';

  @override
  String get later => 'Später';

  @override
  String get downloadUpdate => 'Update herunterladen';

  @override
  String get latestVersion => 'Du hast bereits die neueste Version.';

  @override
  String get updateCheckWindowOpened =>
      'Das Fenster für die Update-Prüfung ist geöffnet.';

  @override
  String get unsupportedUpdate =>
      'Updates in der App werden auf dieser Plattform nicht unterstützt.';

  @override
  String get updateCheckFailed =>
      'Nach Updates konnte nicht gesucht werden. Versuche es später erneut.';

  @override
  String get automaticUpdateError =>
      'Die Einstellungen für automatische Updates konnten nicht geändert werden.';

  @override
  String get downloadPageError =>
      'Die Downloadseite konnte nicht geöffnet werden.';

  @override
  String get releasePageError =>
      'Die Versionsseite konnte nicht geöffnet werden.';

  @override
  String get downloadError =>
      'Das Update-Paket konnte nicht heruntergeladen werden. Versuche es später erneut.';

  @override
  String get cimbarSendTitle => 'CIMBAR-Schnellsenden';

  @override
  String get cimbarReceiveTitle => 'CIMBAR-Schnellempfang';

  @override
  String get cimbarUnsupported =>
      'Die experimentelle CIMBAR-Übertragung ist nur auf Android und iOS verfügbar.';

  @override
  String get cimbarLoading => 'Experimentelle Engine wird geladen…';

  @override
  String get cimbarPageReadySend =>
      'Experimentelle Engine geladen. Wähle eine Datei.';

  @override
  String get cimbarPageReadyReceive =>
      'Experimentelle Engine geladen. Tippe auf Start, um den Kamerazugriff anzufordern.';

  @override
  String get cimbarEngineReady => 'Experimentelle Engine bereit · Modus B';

  @override
  String get cimbarPreparingFile => 'Datei wird vorbereitet…';

  @override
  String get cimbarPaused => 'Wiedergabe pausiert';

  @override
  String get cimbarPlaying => 'Wiedergabe läuft';

  @override
  String get cimbarBroadcasting => 'Datei bereit; Farbcode wird angezeigt';

  @override
  String get cimbarDecoderReady => 'Decoder bereit. Suche nach CIMBAR.';

  @override
  String get cimbarDecoderReadyStart =>
      'Decoder bereit. Tippe auf Start, um den Kamerazugriff anzufordern.';

  @override
  String get cimbarCameraStarted => 'Kamera gestartet. Suche nach CIMBAR.';

  @override
  String get cimbarDecoding => 'Dekodierung mit dem Upstream-Worker';

  @override
  String get cimbarFileHeaderReceived =>
      'Dateikopf geprüft. Datenblöcke werden empfangen.';

  @override
  String get cimbarReceiving => 'Geprüfte Bytes werden empfangen';

  @override
  String get cimbarRecoveredSaving =>
      'Datei vollständig wiederhergestellt. Wird gespeichert…';

  @override
  String get cimbarRecoveredNotSaved =>
      'Datei vollständig wiederhergestellt, aber noch nicht gespeichert.';

  @override
  String get cimbarReceiveComplete => 'Empfang abgeschlossen';

  @override
  String get cimbarLoadFailed => 'Laden fehlgeschlagen. Versuche es erneut.';

  @override
  String get cimbarTransferFailed =>
      'CIMBAR-Übertragung fehlgeschlagen. Versuche es erneut.';

  @override
  String get cimbarReloading => 'Experimentelle Engine wird neu geladen…';

  @override
  String get cimbarRequestingCamera => 'Kamerazugriff wird angefordert…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return 'Datei: $name · $size';
  }

  @override
  String get cimbarSendRate => 'Upstream-Richtwert: 106 KB/s · Modus B';

  @override
  String cimbarReceiveRate(Object speed) {
    return 'Upstream-Richtwert: 106 KB/s · Für diesen Empfang gemessen: $speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return 'Wiederhergestellt: $received / $expected · $seconds s';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return 'Wiederhergestellt: $received · $seconds s';
  }

  @override
  String get cimbarStartReceive => 'Empfang starten (Kamera anfordern)';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return 'Mobile CIMBAR-Dateien dürfen höchstens $maxSize groß sein.';
  }

  @override
  String get cimbarPageLoadError =>
      'Die Offline-CIMBAR-Seite konnte nicht geladen werden. Versuche es erneut.';

  @override
  String get cimbarBridgeError =>
      'Die CIMBAR-Übertragung hat ein ungültiges Ereignis gesendet. Versuche es erneut.';

  @override
  String get cimbarEngineError =>
      'Die CIMBAR-Engine ist nicht verfügbar. Versuche es erneut.';

  @override
  String get cimbarCameraError =>
      'Kamerazugriff oder Dekodierung fehlgeschlagen. Prüfe die Berechtigung und versuche es erneut.';

  @override
  String get cimbarSendError =>
      'Der CIMBAR-Sender konnte die Datei nicht vorbereiten. Versuche es erneut.';

  @override
  String get cimbarReceiveError =>
      'Der CIMBAR-Empfänger konnte die Datei nicht dekodieren. Versuche es erneut.';

  @override
  String get cimbarVerificationError =>
      'Die empfangene Datei konnte nicht geprüft werden. Versuche es erneut.';

  @override
  String get cimbarSaveError =>
      'Die wiederhergestellte Datei konnte nicht gespeichert werden. Versuche es erneut.';

  @override
  String get cimbarHistoryError =>
      'Die Datei wurde gespeichert, aber der Übertragungsverlauf konnte nicht geschrieben werden.';

  @override
  String get cimbarAllFiles => 'Alle Dateien';

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
    return '$hours h $minutes Min.';
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
