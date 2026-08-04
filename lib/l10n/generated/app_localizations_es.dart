// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OneSend';

  @override
  String get followSystem => 'Seguir el sistema';

  @override
  String get language => 'Idioma';

  @override
  String get modeFast => 'Estándar (recomendado)';

  @override
  String get modeReliable => 'Compatible';

  @override
  String get modeTurboQr => 'Rápido';

  @override
  String get modeCimbar => 'Color (experimental)';

  @override
  String get modeQr => 'Código QR';

  @override
  String get compatibilityMode => 'Compatibilidad';

  @override
  String get cancel => 'Cancelar';

  @override
  String get done => 'Listo';

  @override
  String get close => 'Cerrar';

  @override
  String get openFile => 'Abrir';

  @override
  String get shareFile => 'Compartir / reenviar';

  @override
  String get saveCopy => 'Guardar una copia';

  @override
  String get revealInFolder => 'Mostrar en la carpeta';

  @override
  String get more => 'Más';

  @override
  String get settings => 'Ajustes';

  @override
  String get about => 'Acerca de OneSend';

  @override
  String get transferTab => 'Transferir';

  @override
  String get filesTab => 'Archivos';

  @override
  String get filesTitle => 'Archivos';

  @override
  String get filesSubtitle => 'Gestiona el historial y los archivos recibidos.';

  @override
  String get theme => 'Tema';

  @override
  String get themeSubtitle => 'Sistema, claro u oscuro';

  @override
  String get themeSystem => 'Seguir sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSaveError =>
      'No se pudo guardar el tema. Inténtalo de nuevo.';

  @override
  String get aboutSubtitle => 'Versión, privacidad y código abierto.';

  @override
  String get clearHistory => 'Borrar historial';

  @override
  String get clearHistoryQuestion => '¿Borrar el historial de transferencias?';

  @override
  String get clearHistoryDescription =>
      'Esto solo elimina los registros de OneSend. Los archivos guardados no se eliminarán.';

  @override
  String get clearAction => 'Borrar';

  @override
  String get homeHeadline => 'Envía archivos,\ncon luz.';

  @override
  String get homeSubtitle =>
      'Sin red. Sin emparejamiento.\nSolo una pantalla y una cámara.';

  @override
  String get sendEyebrow => 'ENVIAR';

  @override
  String get receiveEyebrow => 'RECIBIR';

  @override
  String get sendFile => 'Enviar un archivo';

  @override
  String get receiveFile => 'Recibir un archivo';

  @override
  String get sendCardDescription =>
      'Pon el código en pantalla y apunta otro dispositivo hacia él.';

  @override
  String get receiveCardDescription =>
      'Abre la cámara y escanea el código visual cambiante.';

  @override
  String get recentTransfers => 'Transferencias recientes';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# registros',
      one: '1 registro',
      zero: '0 registros',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter =>
      'Pantalla ↔ cámara · Los archivos viajan solo como luz entre dos dispositivos';

  @override
  String get emptyHistory =>
      'Aún no hay historial de transferencias. Elige un archivo para iniciar tu primera transferencia óptica.';

  @override
  String get receivedAndVerified => 'Recibido y verificado';

  @override
  String get sendEnded => 'Envío finalizado';

  @override
  String get sent => 'Enviado';

  @override
  String get receivedFileActions => 'Acciones del archivo recibido';

  @override
  String get justNow => 'Ahora mismo';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # minutos',
      one: 'hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace # días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle =>
      'Ajusta la próxima transferencia a tu dispositivo.';

  @override
  String get settingsIntroBody =>
      'El modo predeterminado se usa para los nuevos envíos.';

  @override
  String get transportSection => 'TRANSFERENCIA';

  @override
  String get defaultTransferAlgorithm =>
      'Algoritmo de transferencia predeterminado';

  @override
  String get algorithmDescription =>
      'Deje Estándar para el uso diario. En ajustes: Compatible, Rápido o Color experimental.';

  @override
  String theoreticalSpeed(Object speed) {
    return 'Aproximadamente $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed; predeterminado diario para la mayoría de teléfonos y pantallas brillantes.';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed; más lento pero más estable con poca luz o enfoque difícil.';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed; más rápido, con mayores exigencias de enfoque, exposición y dispositivo.';
  }

  @override
  String get cimbarModeDescription =>
      'Código de color experimental; pico más alto, ambos lados deben coincidir, condiciones más exigentes.';

  @override
  String get modeSaveError =>
      'No se pudieron guardar los ajustes de transferencia predeterminados. Inténtalo de nuevo.';

  @override
  String get appSection => 'APLICACIÓN';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => 'Actualizaciones automáticas';

  @override
  String get desktopUpdatesSubtitle =>
      'Buscar actualizaciones y configurar comprobaciones automáticas en el escritorio.';

  @override
  String get mobileOfflineNote =>
      'El móvil permanece sin conexión: solo están disponibles los ajustes de transferencia e idioma.';

  @override
  String get languagePickerTitle => 'Elegir idioma';

  @override
  String get languageSaveError =>
      'No se pudo guardar el ajuste de idioma. Inténtalo de nuevo.';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode, $speed';
  }

  @override
  String get experimentalVisualTransfer =>
      'Transferencia visual sin conexión experimental';

  @override
  String get workingPrinciple => 'Cómo funciona';

  @override
  String get workingPrincipleBody =>
      'Un archivo se codifica en una secuencia cambiante de códigos visuales. El emisor los muestra; el receptor lee y verifica cada fotograma con su cámara y, después, restaura el archivo. El trayecto es solo luz entre la pantalla y la cámara.';

  @override
  String get whyWeBuiltIt => 'Por qué lo creamos';

  @override
  String get whyWeBuiltItBody =>
      'Dos dispositivos pueden intercambiar un archivo sin red, cuenta ni emparejamiento. OneSend convierte la pantalla y la cámara que ya tienen tus dispositivos en un canal sencillo sin conexión.';

  @override
  String get privacy => 'Privacidad';

  @override
  String get privacyBody =>
      'Las transferencias no usan red ni servidor. En el móvil solo se necesita acceso a la cámara.';

  @override
  String get openSourceAndAuthor => 'Código abierto y autor';

  @override
  String get author => 'Autor';

  @override
  String get license => 'Licencia';

  @override
  String get version => 'Versión';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => 'Abrir GitHub';

  @override
  String get opening => 'Abriendo…';

  @override
  String get versionUnavailable => 'Versión no disponible';

  @override
  String get readingVersion => 'Leyendo la versión…';

  @override
  String get cannotOpenGithub =>
      'No se pudo abrir la página de GitHub. Inténtalo de nuevo.';

  @override
  String get aboutFooter => 'OneSend · transferencia óptica de archivos';

  @override
  String versionLabel(Object version) {
    return 'Versión $version';
  }

  @override
  String get chooseAFile => 'Elegir un archivo';

  @override
  String sendFileDescription(Object maxSize) {
    return 'El archivo se convierte en una secuencia cambiante de códigos visuales.\nHasta $maxSize; comienza con un archivo pequeño para la primera prueba.';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return 'Los nuevos envíos usan el modo $mode · velocidad teórica de aproximadamente $speed';
  }

  @override
  String get transferModeLabel => 'Modo de transferencia';

  @override
  String get dropFilesHint => 'O arrastra un archivo aquí';

  @override
  String get dropFilesActive => 'Suelta para enviar';

  @override
  String get reading => 'Leyendo…';

  @override
  String get chooseFile => 'Elegir archivo';

  @override
  String get sampleVideo => 'Enviar el vídeo de prueba incluido';

  @override
  String get encodedPayloadTooLarge =>
      'El archivo codificado supera el límite de la transferencia óptica.';

  @override
  String modeBadge(Object mode) {
    return 'Modo $mode';
  }

  @override
  String get broadcasting => 'Emitiendo el código visual cambiante';

  @override
  String get pausedPlayback => 'Reproducción en pausa';

  @override
  String get cameraAim =>
      'Apunta la cámara del otro dispositivo a esta zona blanca';

  @override
  String passAndFrames(Object frames, Object pass) {
    return 'Pasada $pass · $frames fotogramas enviados';
  }

  @override
  String runningTime(Object duration) {
    return 'Tiempo transcurrido $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return 'Velocidad teórica $speed';
  }

  @override
  String currentRate(Object speed) {
    return 'Velocidad actual $speed';
  }

  @override
  String get resume => 'Reanudar';

  @override
  String get pause => 'Pausar';

  @override
  String get endTransfer => 'Finalizar transferencia';

  @override
  String get sendAnother => 'Enviar otro archivo';

  @override
  String get chooseOtherFile => 'Elegir otro archivo';

  @override
  String fileTooLarge(Object maxSize) {
    return 'Los archivos no pueden superar $maxSize.';
  }

  @override
  String get cannotReadFile => 'OneSend no pudo leer este archivo.';

  @override
  String get sampleVideoEmpty =>
      'El vídeo de prueba incluido no está disponible.';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return 'El vídeo de prueba incluido supera $maxSize.';
  }

  @override
  String get genericTransferError =>
      'No se pudo iniciar la transferencia. Inténtalo de nuevo.';

  @override
  String get scanReceive => 'Escanear para recibir';

  @override
  String get torch => 'Linterna';

  @override
  String get checkingAndSaving => 'Verificando y guardando…';

  @override
  String get pausedKeepProgress =>
      'En pausa. Toca Reanudar para conservar el progreso actual.';

  @override
  String get lookingForSender => 'Buscando un emisor…';

  @override
  String lockedModeCollecting(Object mode) {
    return 'Modo $mode bloqueado · recopilando códigos visuales';
  }

  @override
  String get scanInstruction =>
      'Mantén el código visual completamente dentro del encuadre y sujeta el dispositivo sin moverlo.';

  @override
  String get scannerBytesUnavailable =>
      'Se detectó un QR, pero la cámara no devolvió datos. El escaneo continúa.';

  @override
  String get scannerInvalidFrame =>
      'Se detectó un QR que no contiene datos de OneSend. El escaneo continúa.';

  @override
  String get desktopCameraInstruction =>
      'La decodificación con la cámara del escritorio usa capturas de pantalla, por lo que es más lenta que en el móvil.';

  @override
  String get verifying => 'Verificando…';

  @override
  String get paused => 'En pausa';

  @override
  String get waitingFirstFrame => 'Esperando el primer fotograma';

  @override
  String fountainProgress(Object frames) {
    return '$frames fotogramas · recuperación Fountain';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames fotogramas · $solved/$blocks bloques';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => 'Reanudar escaneo';

  @override
  String get pauseScan => 'Pausar escaneo';

  @override
  String get restart => 'Reiniciar';

  @override
  String get receivedComplete => 'Recibido';

  @override
  String get verifiedNotSaved =>
      'El archivo se verificó, pero aún no se ha podido guardar.';

  @override
  String get verifiedSaved =>
      'El archivo se verificó y se guardó en este dispositivo.';

  @override
  String get retrySave => 'Reintentar guardar';

  @override
  String get continueReceiving => 'Recibir otro';

  @override
  String recordWriteError(Object error) {
    return 'El archivo se guardó, pero no se pudo escribir su registro en el historial: $error';
  }

  @override
  String saveFailed(Object error) {
    return 'Error al guardar: $error';
  }

  @override
  String get fileActions => 'Acciones del archivo';

  @override
  String get saveLocation => 'Ubicación guardada';

  @override
  String get unrecordedLocation =>
      'No se registró ninguna ubicación de guardado.';

  @override
  String get fileMissing =>
      'Falta el archivo; puede haberse movido o eliminado.';

  @override
  String savedTo(Object path) {
    return 'Guardado en: $path';
  }

  @override
  String iosSavedLocation(Object name) {
    return 'Archivos > En mi iPhone/iPad > OneSend > Received > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return 'Guardado en el almacenamiento de la aplicación: $name. Usa Guardar una copia para elegir una carpeta visible.';
  }

  @override
  String copyExported(Object name) {
    return 'Copia exportada: $name (el selector de archivos del sistema eligió la ubicación)';
  }

  @override
  String copyExportedDesktop(Object path) {
    return 'Copia exportada a: $path';
  }

  @override
  String get fileOperationError =>
      'Error en la operación del archivo. Inténtalo de nuevo.';

  @override
  String get fileNotFound => 'El archivo no existe.';

  @override
  String get fileAccessDenied =>
      'No tienes permiso para acceder a este archivo.';

  @override
  String get operationCancelled => 'Operación cancelada.';

  @override
  String get unsupportedOperation =>
      'Esta operación no es compatible con el dispositivo actual.';

  @override
  String get openFileError => 'El sistema no pudo abrir este archivo.';

  @override
  String get shareFileError =>
      'No se pudo compartir este archivo. Inténtalo de nuevo.';

  @override
  String get revealFileError =>
      'No se pudo mostrar el archivo en su carpeta. Inténtalo de nuevo.';

  @override
  String get saveFileError =>
      'No se pudo exportar el archivo. Inténtalo de nuevo.';

  @override
  String get locationPathUnknown => 'Se desconoce la ubicación guardada.';

  @override
  String get updateAppDescription =>
      'Transferencia de archivos sin conexión entre una pantalla y una cámara.';

  @override
  String get currentVersion => 'Versión actual';

  @override
  String get automaticChecks => 'Buscar actualizaciones automáticamente';

  @override
  String get automaticChecksSubtitle =>
      'Comprobar discretamente una vez al día y avisarte solo cuando se encuentre una versión nueva.';

  @override
  String get downloadPage => 'Página de descarga';

  @override
  String get checking => 'Comprobando…';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version está disponible';
  }

  @override
  String get releaseNotes => 'Novedades';

  @override
  String get downloading => 'Descargando y verificando…';

  @override
  String downloadingPercent(Object percent) {
    return 'Descargando y verificando $percent%';
  }

  @override
  String get viewRelease => 'Ver página de la versión';

  @override
  String get later => 'Más tarde';

  @override
  String get downloadUpdate => 'Descargar actualización';

  @override
  String get latestVersion => 'Ya tienes la versión más reciente.';

  @override
  String get updateCheckWindowOpened =>
      'La ventana de comprobación de actualizaciones está abierta.';

  @override
  String get unsupportedUpdate =>
      'Las actualizaciones dentro de la aplicación no son compatibles con esta plataforma.';

  @override
  String get updateCheckFailed =>
      'No se pudieron comprobar las actualizaciones. Inténtalo más tarde.';

  @override
  String get automaticUpdateError =>
      'No se pudieron cambiar los ajustes de actualización automática.';

  @override
  String get downloadPageError => 'No se pudo abrir la página de descarga.';

  @override
  String get releasePageError => 'No se pudo abrir la página de la versión.';

  @override
  String get downloadError =>
      'No se pudo descargar el paquete de actualización. Inténtalo más tarde.';

  @override
  String get cimbarSendTitle => 'Envío rápido CIMBAR';

  @override
  String get cimbarReceiveTitle => 'Recepción rápida CIMBAR';

  @override
  String get cimbarUnsupported =>
      'La transferencia experimental CIMBAR solo está disponible en Android e iOS.';

  @override
  String get cimbarLoading => 'Cargando el motor experimental…';

  @override
  String get cimbarPageReadySend =>
      'Motor experimental cargado. Elige un archivo.';

  @override
  String get cimbarPageReadyReceive =>
      'Motor experimental cargado. Toca iniciar para solicitar acceso a la cámara.';

  @override
  String get cimbarEngineReady => 'Motor experimental listo · Modo B';

  @override
  String get cimbarPreparingFile => 'Preparando el archivo…';

  @override
  String get cimbarPaused => 'Reproducción pausada';

  @override
  String get cimbarPlaying => 'Reproduciendo';

  @override
  String get cimbarBroadcasting => 'Archivo listo; mostrando el código visual';

  @override
  String get cimbarDecoderReady => 'Decodificador listo. Buscando CIMBAR.';

  @override
  String get cimbarDecoderReadyStart =>
      'Decodificador listo. Toca iniciar para solicitar acceso a la cámara.';

  @override
  String get cimbarCameraStarted => 'Cámara iniciada. Buscando CIMBAR.';

  @override
  String get cimbarDecoding => 'Decodificando con el worker upstream';

  @override
  String get cimbarFileHeaderReceived =>
      'Cabecera verificada. Recibiendo bloques.';

  @override
  String get cimbarReceiving => 'Recibiendo bytes verificados';

  @override
  String get cimbarRecoveredSaving =>
      'Archivo recuperado por completo. Guardando…';

  @override
  String get cimbarRecoveredNotSaved =>
      'Archivo recuperado por completo, pero aún no se ha guardado.';

  @override
  String get cimbarReceiveComplete => 'Recepción completada';

  @override
  String get cimbarLoadFailed => 'Error al cargar. Inténtalo de nuevo.';

  @override
  String get cimbarTransferFailed =>
      'Error en la transferencia CIMBAR. Inténtalo de nuevo.';

  @override
  String get cimbarReloading => 'Recargando el motor experimental…';

  @override
  String get cimbarRequestingCamera => 'Solicitando acceso a la cámara…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return 'Archivo: $name · $size';
  }

  @override
  String get cimbarSendRate => 'Referencia upstream: 106 KB/s · Modo B';

  @override
  String cimbarReceiveRate(Object speed) {
    return 'Referencia upstream: 106 KB/s · Medido en esta recepción: $speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return 'Recuperado $received / $expected · $seconds s';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return 'Recuperado $received · $seconds s';
  }

  @override
  String get cimbarStartReceive => 'Iniciar recepción (solicitar cámara)';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return 'Los archivos CIMBAR móviles no pueden superar $maxSize.';
  }

  @override
  String get cimbarPageLoadError =>
      'No se pudo cargar la página CIMBAR sin conexión. Inténtalo de nuevo.';

  @override
  String get cimbarBridgeError =>
      'La transferencia CIMBAR envió un evento no válido. Inténtalo de nuevo.';

  @override
  String get cimbarEngineError =>
      'El motor CIMBAR no está disponible. Inténtalo de nuevo.';

  @override
  String get cimbarCameraError =>
      'Falló el acceso a la cámara o la decodificación. Comprueba el permiso e inténtalo de nuevo.';

  @override
  String get cimbarSendError =>
      'El emisor CIMBAR no pudo preparar el archivo. Inténtalo de nuevo.';

  @override
  String get cimbarReceiveError =>
      'El receptor CIMBAR no pudo decodificar el archivo. Inténtalo de nuevo.';

  @override
  String get cimbarVerificationError =>
      'No se pudo verificar el archivo recibido. Inténtalo de nuevo.';

  @override
  String get cimbarSaveError =>
      'No se pudo guardar el archivo recuperado. Inténtalo de nuevo.';

  @override
  String get cimbarHistoryError =>
      'El archivo se guardó, pero no se pudo escribir el historial de transferencias.';

  @override
  String get cimbarAllFiles => 'Todos los archivos';

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
    return '$hours h $minutes min';
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
