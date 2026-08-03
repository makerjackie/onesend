// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'OneSend';

  @override
  String get followSystem => 'Suivre le système';

  @override
  String get language => 'Langue';

  @override
  String get modeFast => 'Rapide';

  @override
  String get modeReliable => 'Fiable';

  @override
  String get modeTurboQr => 'Turbo QR (expérimental)';

  @override
  String get modeCimbar => 'Code visuel couleur CIMBAR (expérimental)';

  @override
  String get compatibilityMode => 'Compatibilité';

  @override
  String get cancel => 'Annuler';

  @override
  String get done => 'Terminé';

  @override
  String get close => 'Fermer';

  @override
  String get openFile => 'Ouvrir';

  @override
  String get shareFile => 'Partager / transférer';

  @override
  String get saveCopy => 'Enregistrer une copie';

  @override
  String get revealInFolder => 'Afficher dans le dossier';

  @override
  String get more => 'Plus';

  @override
  String get settings => 'Paramètres';

  @override
  String get about => 'À propos de OneSend';

  @override
  String get clearHistory => 'Effacer l’historique';

  @override
  String get clearHistoryQuestion => 'Effacer l’historique des transferts ?';

  @override
  String get clearHistoryDescription =>
      'Cela supprime uniquement les enregistrements de OneSend. Les fichiers enregistrés ne seront pas supprimés.';

  @override
  String get clearAction => 'Effacer';

  @override
  String get homeHeadline => 'Envoyer des fichiers,\npar la lumière.';

  @override
  String get homeSubtitle =>
      'Pas de réseau. Pas de jumelage.\nJuste un écran et une caméra.';

  @override
  String get sendEyebrow => 'ENVOYER';

  @override
  String get receiveEyebrow => 'RECEVOIR';

  @override
  String get sendFile => 'Envoyer un fichier';

  @override
  String get receiveFile => 'Scanner pour recevoir';

  @override
  String get sendCardDescription =>
      'Affichez le code à l’écran et visez-le avec un autre appareil.';

  @override
  String get receiveCardDescription =>
      'Ouvrez la caméra et scannez le code visuel changeant.';

  @override
  String get recentTransfers => 'Transferts récents';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# enregistrements',
      one: '1 enregistrement',
      zero: '0 enregistrement',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter =>
      'Écran ↔ caméra · Les fichiers voyagent uniquement sous forme de lumière entre deux appareils';

  @override
  String get emptyHistory =>
      'Aucun historique de transfert. Choisissez un fichier pour commencer votre premier transfert optique.';

  @override
  String get receivedAndVerified => 'Reçu et vérifié';

  @override
  String get sendEnded => 'Envoi terminé';

  @override
  String get sent => 'Envoyé';

  @override
  String get receivedFileActions => 'Actions sur le fichier reçu';

  @override
  String get justNow => 'À l’instant';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a # minutes',
      one: 'Il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a # heures',
      one: 'Il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a # jours',
      one: 'Il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle =>
      'Réglez le prochain transfert pour votre appareil.';

  @override
  String get settingsIntroBody =>
      'Le mode par défaut est utilisé pour les nouveaux envois.';

  @override
  String get transportSection => 'TRANSFERT';

  @override
  String get defaultTransferAlgorithm => 'Algorithme de transfert par défaut';

  @override
  String get algorithmDescription =>
      'Choisissez un profil QR ou le code visuel couleur CIMBAR expérimental. Le mode de réception QR est indiqué par chaque image.';

  @override
  String theoreticalSpeed(Object speed) {
    return 'Environ $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed ; rapide et stable dans une configuration fixe avec un écran lumineux.';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed ; compatibilité fiable grâce à une meilleure marge de correction d’erreurs, mais plus lent.';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed ; profil QR expérimental à haute capacité, avec une marge de scan réduite.';
  }

  @override
  String get cimbarModeDescription =>
      'Référence de débit montant : environ 106 KB/s ; code visuel couleur expérimental sur Android et iOS.';

  @override
  String get modeSaveError =>
      'Impossible d’enregistrer les paramètres de transfert par défaut. Réessayez.';

  @override
  String get appSection => 'APPLICATION';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => 'Mises à jour automatiques';

  @override
  String get desktopUpdatesSubtitle =>
      'Rechercher les mises à jour et configurer les vérifications automatiques sur ordinateur.';

  @override
  String get mobileOfflineNote =>
      'Le mobile reste hors ligne : seuls les paramètres de transfert et de langue sont disponibles.';

  @override
  String get languagePickerTitle => 'Choisir la langue';

  @override
  String get languageSaveError =>
      'Impossible d’enregistrer le paramètre de langue. Réessayez.';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode, $speed';
  }

  @override
  String get experimentalVisualTransfer =>
      'Transfert visuel hors ligne expérimental';

  @override
  String get workingPrinciple => 'Fonctionnement';

  @override
  String get workingPrincipleBody =>
      'Un fichier est encodé en une séquence changeante de codes visuels. L’expéditeur les affiche ; le récepteur lit et vérifie chaque image avec sa caméra, puis restaure le fichier. Le trajet se fait uniquement par la lumière entre l’écran et la caméra.';

  @override
  String get whyWeBuiltIt => 'Pourquoi cette application ?';

  @override
  String get whyWeBuiltItBody =>
      'Deux appareils peuvent échanger un fichier sans réseau, compte ni jumelage. OneSend transforme l’écran et la caméra déjà présents sur vos appareils en un simple canal hors ligne.';

  @override
  String get privacy => 'Confidentialité';

  @override
  String get privacyBody =>
      'Les transferts n’utilisent ni réseau ni serveur. Sur mobile, seul l’accès à la caméra est nécessaire.';

  @override
  String get openSourceAndAuthor => 'Code source ouvert et auteur';

  @override
  String get author => 'Auteur';

  @override
  String get license => 'Licence';

  @override
  String get version => 'Version';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => 'Ouvrir GitHub';

  @override
  String get opening => 'Ouverture…';

  @override
  String get versionUnavailable => 'Version indisponible';

  @override
  String get readingVersion => 'Lecture de la version…';

  @override
  String get cannotOpenGithub =>
      'Impossible d’ouvrir la page GitHub. Réessayez.';

  @override
  String get aboutFooter => 'OneSend · transfert de fichiers optique';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get chooseAFile => 'Choisir un fichier';

  @override
  String sendFileDescription(Object maxSize) {
    return 'Le fichier devient une séquence changeante de codes visuels.\nJusqu’à $maxSize ; commencez par un petit fichier pour le premier test.';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return 'Les nouveaux envois utilisent le mode $mode · débit théorique d’environ $speed';
  }

  @override
  String get reading => 'Lecture…';

  @override
  String get chooseFile => 'Choisir un fichier';

  @override
  String get sampleVideo => 'Envoyer la vidéo de test intégrée';

  @override
  String get encodedPayloadTooLarge =>
      'Le fichier encodé dépasse la limite du transfert optique.';

  @override
  String modeBadge(Object mode) {
    return 'Mode $mode';
  }

  @override
  String get broadcasting => 'Diffusion du code visuel changeant';

  @override
  String get pausedPlayback => 'Lecture en pause';

  @override
  String get cameraAim =>
      'Visez cette zone blanche avec la caméra de l’autre appareil';

  @override
  String passAndFrames(Object frames, Object pass) {
    return 'Passe $pass · $frames images envoyées';
  }

  @override
  String runningTime(Object duration) {
    return 'Durée $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return 'Débit théorique $speed';
  }

  @override
  String currentRate(Object speed) {
    return 'Débit actuel $speed';
  }

  @override
  String get resume => 'Reprendre';

  @override
  String get pause => 'Mettre en pause';

  @override
  String get endTransfer => 'Terminer le transfert';

  @override
  String get sendAnother => 'Envoyer un autre fichier';

  @override
  String get chooseOtherFile => 'Choisir un autre fichier';

  @override
  String fileTooLarge(Object maxSize) {
    return 'Les fichiers ne doivent pas dépasser $maxSize.';
  }

  @override
  String get cannotReadFile => 'OneSend n’a pas pu lire ce fichier.';

  @override
  String get sampleVideoEmpty => 'La vidéo de test intégrée est indisponible.';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return 'La vidéo de test intégrée dépasse $maxSize.';
  }

  @override
  String get genericTransferError =>
      'Impossible de démarrer le transfert. Réessayez.';

  @override
  String get scanReceive => 'Scanner pour recevoir';

  @override
  String get torch => 'Lampe torche';

  @override
  String get checkingAndSaving => 'Vérification et enregistrement…';

  @override
  String get pausedKeepProgress =>
      'En pause. Appuyez sur Reprendre pour conserver la progression actuelle.';

  @override
  String get lookingForSender => 'Recherche d’un expéditeur…';

  @override
  String lockedModeCollecting(Object mode) {
    return 'Mode $mode verrouillé · collecte des codes visuels';
  }

  @override
  String get scanInstruction =>
      'Gardez le code visuel entièrement dans le cadre et maintenez l’appareil immobile.';

  @override
  String get desktopCameraInstruction =>
      'Le décodage par caméra sur ordinateur utilise des captures d’écran ; il est donc plus lent que sur mobile.';

  @override
  String get verifying => 'Vérification…';

  @override
  String get paused => 'En pause';

  @override
  String get waitingFirstFrame => 'En attente de la première image';

  @override
  String fountainProgress(Object frames) {
    return '$frames images · récupération Fountain';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames images · $solved/$blocks blocs';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => 'Reprendre le scan';

  @override
  String get pauseScan => 'Mettre le scan en pause';

  @override
  String get restart => 'Redémarrer';

  @override
  String get receivedComplete => 'Reçu';

  @override
  String get verifiedNotSaved =>
      'Le fichier a été vérifié, mais n’a pas encore pu être enregistré.';

  @override
  String get verifiedSaved =>
      'Le fichier a été vérifié et enregistré sur cet appareil.';

  @override
  String get retrySave => 'Réessayer d’enregistrer';

  @override
  String get continueReceiving => 'Recevoir un autre fichier';

  @override
  String recordWriteError(Object error) {
    return 'Le fichier a été enregistré, mais son entrée d’historique n’a pas pu être créée : $error';
  }

  @override
  String saveFailed(Object error) {
    return 'Échec de l’enregistrement : $error';
  }

  @override
  String get fileActions => 'Actions sur le fichier';

  @override
  String get saveLocation => 'Emplacement d’enregistrement';

  @override
  String get unrecordedLocation =>
      'Aucun emplacement d’enregistrement n’a été indiqué.';

  @override
  String get fileMissing =>
      'Le fichier est introuvable ; il a peut-être été déplacé ou supprimé.';

  @override
  String savedTo(Object path) {
    return 'Enregistré dans : $path';
  }

  @override
  String iosSavedLocation(Object name) {
    return 'Fichiers > Sur mon iPhone/iPad > OneSend > Received > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return 'Enregistré dans le stockage de l’application : $name. Utilisez Enregistrer une copie pour choisir un dossier visible.';
  }

  @override
  String copyExported(Object name) {
    return 'Copie exportée : $name (l’emplacement a été choisi par le sélecteur de fichiers système)';
  }

  @override
  String copyExportedDesktop(Object path) {
    return 'Copie exportée vers : $path';
  }

  @override
  String get fileOperationError =>
      'Échec de l’opération sur le fichier. Réessayez.';

  @override
  String get fileNotFound => 'Le fichier n’existe pas.';

  @override
  String get fileAccessDenied =>
      'Vous n’avez pas l’autorisation d’accéder à ce fichier.';

  @override
  String get operationCancelled => 'Opération annulée.';

  @override
  String get unsupportedOperation =>
      'Cette opération n’est pas prise en charge sur l’appareil actuel.';

  @override
  String get openFileError => 'Le système n’a pas pu ouvrir ce fichier.';

  @override
  String get shareFileError => 'Impossible de partager ce fichier. Réessayez.';

  @override
  String get revealFileError =>
      'Impossible d’afficher le fichier dans son dossier. Réessayez.';

  @override
  String get saveFileError => 'Impossible d’exporter le fichier. Réessayez.';

  @override
  String get locationPathUnknown =>
      'L’emplacement d’enregistrement est inconnu.';

  @override
  String get updateAppDescription =>
      'Transfert de fichiers hors ligne entre un écran et une caméra.';

  @override
  String get currentVersion => 'Version actuelle';

  @override
  String get automaticChecks => 'Rechercher automatiquement les mises à jour';

  @override
  String get automaticChecksSubtitle =>
      'Vérifier discrètement une fois par jour et vous avertir uniquement lorsqu’une nouvelle version est trouvée.';

  @override
  String get downloadPage => 'Page de téléchargement';

  @override
  String get checking => 'Vérification…';

  @override
  String get checkForUpdates => 'Rechercher les mises à jour';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version est disponible';
  }

  @override
  String get releaseNotes => 'Nouveautés';

  @override
  String get downloading => 'Téléchargement et vérification…';

  @override
  String downloadingPercent(Object percent) {
    return 'Téléchargement et vérification de $percent%';
  }

  @override
  String get viewRelease => 'Afficher la page de la version';

  @override
  String get later => 'Plus tard';

  @override
  String get downloadUpdate => 'Télécharger la mise à jour';

  @override
  String get latestVersion => 'Vous disposez déjà de la dernière version.';

  @override
  String get updateCheckWindowOpened =>
      'La fenêtre de recherche de mises à jour est ouverte.';

  @override
  String get unsupportedUpdate =>
      'Les mises à jour dans l’application ne sont pas prises en charge sur cette plateforme.';

  @override
  String get updateCheckFailed =>
      'Impossible de rechercher les mises à jour. Réessayez plus tard.';

  @override
  String get automaticUpdateError =>
      'Impossible de modifier les paramètres de mise à jour automatique.';

  @override
  String get downloadPageError =>
      'Impossible d’ouvrir la page de téléchargement.';

  @override
  String get releasePageError => 'Impossible d’ouvrir la page de la version.';

  @override
  String get downloadError =>
      'Le paquet de mise à jour n’a pas pu être téléchargé. Réessayez plus tard.';

  @override
  String get cimbarSendTitle => 'Envoi rapide CIMBAR';

  @override
  String get cimbarReceiveTitle => 'Réception rapide CIMBAR';

  @override
  String get cimbarUnsupported =>
      'Le transfert CIMBAR expérimental est disponible uniquement sur Android et iOS.';

  @override
  String get cimbarLoading => 'Chargement du moteur expérimental…';

  @override
  String get cimbarPageReadySend =>
      'Moteur expérimental chargé. Choisissez un fichier.';

  @override
  String get cimbarPageReadyReceive =>
      'Moteur expérimental chargé. Touchez Démarrer pour demander l’accès à la caméra.';

  @override
  String get cimbarEngineReady => 'Moteur expérimental prêt · Mode B';

  @override
  String get cimbarPreparingFile => 'Préparation du fichier…';

  @override
  String get cimbarPaused => 'Lecture en pause';

  @override
  String get cimbarPlaying => 'Lecture en cours';

  @override
  String get cimbarBroadcasting => 'Fichier prêt ; code visuel affiché';

  @override
  String get cimbarDecoderReady => 'Décodeur prêt. Recherche de CIMBAR.';

  @override
  String get cimbarDecoderReadyStart =>
      'Décodeur prêt. Touchez Démarrer pour demander l’accès à la caméra.';

  @override
  String get cimbarCameraStarted => 'Caméra démarrée. Recherche de CIMBAR.';

  @override
  String get cimbarDecoding => 'Décodage avec le worker upstream';

  @override
  String get cimbarFileHeaderReceived =>
      'En-tête vérifié. Réception des blocs.';

  @override
  String get cimbarReceiving => 'Réception des octets vérifiés';

  @override
  String get cimbarRecoveredSaving =>
      'Fichier entièrement récupéré. Enregistrement…';

  @override
  String get cimbarRecoveredNotSaved =>
      'Fichier entièrement récupéré, mais pas encore enregistré.';

  @override
  String get cimbarReceiveComplete => 'Réception terminée';

  @override
  String get cimbarLoadFailed => 'Échec du chargement. Réessayez.';

  @override
  String get cimbarTransferFailed => 'Échec du transfert CIMBAR. Réessayez.';

  @override
  String get cimbarReloading => 'Rechargement du moteur expérimental…';

  @override
  String get cimbarRequestingCamera => 'Demande d’accès à la caméra…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return 'Fichier : $name · $size';
  }

  @override
  String get cimbarSendRate => 'Référence upstream : 106 KB/s · Mode B';

  @override
  String cimbarReceiveRate(Object speed) {
    return 'Référence upstream : 106 KB/s · Mesuré pour cette réception : $speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return 'Récupéré : $received / $expected · $seconds s';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return 'Récupéré : $received · $seconds s';
  }

  @override
  String get cimbarStartReceive => 'Démarrer la réception (demander la caméra)';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return 'Les fichiers CIMBAR mobiles ne doivent pas dépasser $maxSize.';
  }

  @override
  String get cimbarPageLoadError =>
      'La page CIMBAR hors ligne n’a pas pu être chargée. Réessayez.';

  @override
  String get cimbarBridgeError =>
      'Le transfert CIMBAR a envoyé un événement invalide. Réessayez.';

  @override
  String get cimbarEngineError =>
      'Le moteur CIMBAR est indisponible. Réessayez.';

  @override
  String get cimbarCameraError =>
      'L’accès à la caméra ou le décodage a échoué. Vérifiez l’autorisation et réessayez.';

  @override
  String get cimbarSendError =>
      'L’émetteur CIMBAR n’a pas pu préparer le fichier. Réessayez.';

  @override
  String get cimbarReceiveError =>
      'Le récepteur CIMBAR n’a pas pu décoder le fichier. Réessayez.';

  @override
  String get cimbarVerificationError =>
      'Le fichier reçu n’a pas pu être vérifié. Réessayez.';

  @override
  String get cimbarSaveError =>
      'Le fichier récupéré n’a pas pu être enregistré. Réessayez.';

  @override
  String get cimbarHistoryError =>
      'Le fichier a été enregistré, mais l’historique du transfert n’a pas pu être écrit.';

  @override
  String get cimbarAllFiles => 'Tous les fichiers';

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
    return '$hours h $minutes min';
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
