// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'OneSend';

  @override
  String get followSystem => 'Seguir o sistema';

  @override
  String get language => 'Idioma';

  @override
  String get modeFast => 'Rápido';

  @override
  String get modeReliable => 'Confiável';

  @override
  String get modeTurboQr => 'Turbo QR (experimental)';

  @override
  String get modeCimbar => 'Código visual colorido CIMBAR (experimental)';

  @override
  String get modeQr => 'QR code';

  @override
  String get compatibilityMode => 'Compatibilidade';

  @override
  String get cancel => 'Cancelar';

  @override
  String get done => 'Concluído';

  @override
  String get close => 'Fechar';

  @override
  String get openFile => 'Abrir';

  @override
  String get shareFile => 'Compartilhar / encaminhar';

  @override
  String get saveCopy => 'Salvar uma cópia';

  @override
  String get revealInFolder => 'Mostrar na pasta';

  @override
  String get more => 'Mais';

  @override
  String get settings => 'Configurações';

  @override
  String get about => 'Sobre o OneSend';

  @override
  String get clearHistory => 'Limpar histórico';

  @override
  String get clearHistoryQuestion => 'Limpar histórico de transferências?';

  @override
  String get clearHistoryDescription =>
      'Isso remove apenas os registros do OneSend. Os arquivos salvos não serão excluídos.';

  @override
  String get clearAction => 'Limpar';

  @override
  String get homeHeadline => 'Envie arquivos,\ncom luz.';

  @override
  String get homeSubtitle =>
      'Sem rede. Sem pareamento.\nApenas uma tela e uma câmera.';

  @override
  String get sendEyebrow => 'ENVIAR';

  @override
  String get receiveEyebrow => 'RECEBER';

  @override
  String get sendFile => 'Enviar um arquivo';

  @override
  String get receiveFile => 'Escanear para receber';

  @override
  String get sendCardDescription =>
      'Exiba o código na tela e aponte outro dispositivo para ele.';

  @override
  String get receiveCardDescription =>
      'Abra a câmera e escaneie o código visual em mudança.';

  @override
  String get recentTransfers => 'Transferências recentes';

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
      'Tela ↔ câmera · Os arquivos viajam somente como luz entre dois dispositivos';

  @override
  String get emptyHistory =>
      'Ainda não há histórico de transferências. Escolha um arquivo para iniciar sua primeira transferência óptica.';

  @override
  String get receivedAndVerified => 'Recebido e verificado';

  @override
  String get sendEnded => 'Envio encerrado';

  @override
  String get sent => 'Enviado';

  @override
  String get receivedFileActions => 'Ações do arquivo recebido';

  @override
  String get justNow => 'Agora';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há # minutos',
      one: 'há 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há # horas',
      one: 'há 1 hora',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'há # dias',
      one: 'há 1 dia',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle =>
      'Ajuste a próxima transferência ao seu dispositivo.';

  @override
  String get settingsIntroBody => 'O modo padrão é usado para novos envios.';

  @override
  String get transportSection => 'TRANSFERÊNCIA';

  @override
  String get defaultTransferAlgorithm => 'Algoritmo de transferência padrão';

  @override
  String get algorithmDescription =>
      'Escolha um perfil QR ou o código visual colorido CIMBAR experimental. O modo de recebimento QR é descrito em cada quadro.';

  @override
  String theoreticalSpeed(Object speed) {
    return 'Cerca de $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed; rápido e estável em um ambiente estável e uma tela brilhante.';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed; com mais compatibilidade e margem para correção de erros, mas mais lento.';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed; perfil QR experimental de alta capacidade, com menos margem para leitura.';
  }

  @override
  String get cimbarModeDescription =>
      'Referência de envio de cerca de 106 KB/s; código visual colorido experimental no Android e iOS.';

  @override
  String get modeSaveError =>
      'Não foi possível salvar as configurações de transferência padrão. Tente novamente.';

  @override
  String get appSection => 'APLICATIVO';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => 'Atualizações automáticas';

  @override
  String get desktopUpdatesSubtitle =>
      'Verifique atualizações e configure verificações automáticas no desktop.';

  @override
  String get mobileOfflineNote =>
      'O celular permanece offline: apenas as configurações de transferência e idioma estão disponíveis.';

  @override
  String get languagePickerTitle => 'Escolha o idioma';

  @override
  String get languageSaveError =>
      'Não foi possível salvar a configuração de idioma. Tente novamente.';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode, $speed';
  }

  @override
  String get experimentalVisualTransfer =>
      'Transferência visual offline experimental';

  @override
  String get workingPrinciple => 'Como funciona';

  @override
  String get workingPrincipleBody =>
      'Um arquivo é codificado em uma sequência variável de códigos visuais. O remetente os exibe; o destinatário lê e verifica cada quadro com a câmera e então restaura o arquivo. O caminho usa apenas luz entre a tela e a câmera.';

  @override
  String get whyWeBuiltIt => 'Por que criamos isto';

  @override
  String get whyWeBuiltItBody =>
      'Dois dispositivos podem trocar um arquivo sem rede, conta ou pareamento. O OneSend transforma a tela e a câmera que já estão nos seus dispositivos em um canal offline simples.';

  @override
  String get privacy => 'Privacidade';

  @override
  String get privacyBody =>
      'As transferências não usam rede nem servidor. No celular, é necessário apenas acesso à câmera.';

  @override
  String get openSourceAndAuthor => 'Código aberto e autor';

  @override
  String get author => 'Autor';

  @override
  String get license => 'Licença';

  @override
  String get version => 'Versão';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => 'Abrir o GitHub';

  @override
  String get opening => 'Abrindo…';

  @override
  String get versionUnavailable => 'Versão indisponível';

  @override
  String get readingVersion => 'Lendo a versão…';

  @override
  String get cannotOpenGithub =>
      'Não foi possível abrir a página do GitHub. Tente novamente.';

  @override
  String get aboutFooter => 'OneSend · transferência óptica de arquivos';

  @override
  String versionLabel(Object version) {
    return 'Versão $version';
  }

  @override
  String get chooseAFile => 'Escolha um arquivo';

  @override
  String sendFileDescription(Object maxSize) {
    return 'O arquivo se torna uma sequência variável de códigos visuais.\nAté $maxSize; comece com um arquivo pequeno no primeiro teste.';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return 'Novos envios usam o modo $mode · taxa teórica de cerca de $speed';
  }

  @override
  String get transferModeLabel => 'Transfer mode';

  @override
  String get dropFilesHint => 'Or drag and drop a file here';

  @override
  String get dropFilesActive => 'Drop to send';

  @override
  String get reading => 'Lendo…';

  @override
  String get chooseFile => 'Escolher arquivo';

  @override
  String get sampleVideo => 'Enviar o vídeo de teste integrado';

  @override
  String get encodedPayloadTooLarge =>
      'O arquivo codificado é maior que o limite da transferência óptica.';

  @override
  String modeBadge(Object mode) {
    return 'Modo $mode';
  }

  @override
  String get broadcasting => 'Transmitindo o código visual variável';

  @override
  String get pausedPlayback => 'Reprodução pausada';

  @override
  String get cameraAim =>
      'Aponte a câmera do outro dispositivo para esta área branca';

  @override
  String passAndFrames(Object frames, Object pass) {
    return 'Etapa $pass · $frames quadros enviados';
  }

  @override
  String runningTime(Object duration) {
    return 'Em execução há $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return 'Taxa teórica $speed';
  }

  @override
  String currentRate(Object speed) {
    return 'Taxa atual $speed';
  }

  @override
  String get resume => 'Retomar';

  @override
  String get pause => 'Pausar';

  @override
  String get endTransfer => 'Encerrar transferência';

  @override
  String get sendAnother => 'Enviar outro arquivo';

  @override
  String get chooseOtherFile => 'Escolher outro arquivo';

  @override
  String fileTooLarge(Object maxSize) {
    return 'Os arquivos não podem ter mais de $maxSize.';
  }

  @override
  String get cannotReadFile => 'O OneSend não conseguiu ler este arquivo.';

  @override
  String get sampleVideoEmpty =>
      'O vídeo de teste integrado não está disponível.';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return 'O vídeo de teste integrado é maior que $maxSize.';
  }

  @override
  String get genericTransferError =>
      'Não foi possível iniciar a transferência. Tente novamente.';

  @override
  String get scanReceive => 'Escanear para receber';

  @override
  String get torch => 'Lanterna';

  @override
  String get checkingAndSaving => 'Verificando e salvando…';

  @override
  String get pausedKeepProgress =>
      'Pausado. Toque em Retomar para manter o progresso atual.';

  @override
  String get lookingForSender => 'Procurando um remetente…';

  @override
  String lockedModeCollecting(Object mode) {
    return 'Modo $mode bloqueado · coletando códigos visuais';
  }

  @override
  String get scanInstruction =>
      'Mantenha o código visual totalmente dentro do quadro e segure o dispositivo firme.';

  @override
  String get desktopCameraInstruction =>
      'A decodificação pela câmera do desktop usa capturas de tela, por isso é mais lenta que no celular.';

  @override
  String get verifying => 'Verificando…';

  @override
  String get paused => 'Pausado';

  @override
  String get waitingFirstFrame => 'Aguardando o primeiro quadro';

  @override
  String fountainProgress(Object frames) {
    return '$frames quadros · recuperação Fountain';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames quadros · $solved/$blocks blocos';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => 'Retomar escaneamento';

  @override
  String get pauseScan => 'Pausar escaneamento';

  @override
  String get restart => 'Reiniciar';

  @override
  String get receivedComplete => 'Recebido';

  @override
  String get verifiedNotSaved =>
      'O arquivo foi verificado, mas ainda não pôde ser salvo.';

  @override
  String get verifiedSaved =>
      'O arquivo foi verificado e salvo neste dispositivo.';

  @override
  String get retrySave => 'Tentar salvar novamente';

  @override
  String get continueReceiving => 'Receber outro';

  @override
  String recordWriteError(Object error) {
    return 'O arquivo foi salvo, mas não foi possível gravar seu registro no histórico: $error';
  }

  @override
  String saveFailed(Object error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String get fileActions => 'Ações do arquivo';

  @override
  String get saveLocation => 'Local de salvamento';

  @override
  String get unrecordedLocation => 'Nenhum local de salvamento foi registrado.';

  @override
  String get fileMissing =>
      'O arquivo está ausente; pode ter sido movido ou excluído.';

  @override
  String savedTo(Object path) {
    return 'Salvo em: $path';
  }

  @override
  String iosSavedLocation(Object name) {
    return 'Arquivos > No Meu iPhone/iPad > OneSend > Recebidos > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return 'Salvo no armazenamento do app: $name. Use Salvar uma cópia para escolher uma pasta visível.';
  }

  @override
  String copyExported(Object name) {
    return 'Cópia exportada: $name (o seletor de arquivos do sistema escolheu o local)';
  }

  @override
  String copyExportedDesktop(Object path) {
    return 'Cópia exportada para: $path';
  }

  @override
  String get fileOperationError =>
      'Falha na operação de arquivo. Tente novamente.';

  @override
  String get fileNotFound => 'O arquivo não existe.';

  @override
  String get fileAccessDenied =>
      'Você não tem permissão para acessar este arquivo.';

  @override
  String get operationCancelled => 'Operação cancelada.';

  @override
  String get unsupportedOperation =>
      'Esta operação não é compatível com o dispositivo atual.';

  @override
  String get openFileError => 'O sistema não conseguiu abrir este arquivo.';

  @override
  String get shareFileError =>
      'Não foi possível compartilhar este arquivo. Tente novamente.';

  @override
  String get revealFileError =>
      'Não foi possível mostrar o arquivo na pasta. Tente novamente.';

  @override
  String get saveFileError =>
      'Não foi possível exportar o arquivo. Tente novamente.';

  @override
  String get locationPathUnknown => 'O local de salvamento é desconhecido.';

  @override
  String get updateAppDescription =>
      'Transferência offline de arquivos entre uma tela e uma câmera.';

  @override
  String get currentVersion => 'Versão atual';

  @override
  String get automaticChecks => 'Verificar atualizações automaticamente';

  @override
  String get automaticChecksSubtitle =>
      'Verifique silenciosamente uma vez por dia e avise apenas quando uma nova versão for encontrada.';

  @override
  String get downloadPage => 'Página de download';

  @override
  String get checking => 'Verificando…';

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version está disponível';
  }

  @override
  String get releaseNotes => 'Novidades';

  @override
  String get downloading => 'Baixando e verificando…';

  @override
  String downloadingPercent(Object percent) {
    return 'Baixando e verificando $percent%';
  }

  @override
  String get viewRelease => 'Ver página da versão';

  @override
  String get later => 'Mais tarde';

  @override
  String get downloadUpdate => 'Baixar atualização';

  @override
  String get latestVersion => 'Você já tem a versão mais recente.';

  @override
  String get updateCheckWindowOpened =>
      'A janela de verificação de atualização está aberta.';

  @override
  String get unsupportedUpdate =>
      'Atualizações dentro do app não são compatíveis com esta plataforma.';

  @override
  String get updateCheckFailed =>
      'Não foi possível verificar atualizações. Tente novamente mais tarde.';

  @override
  String get automaticUpdateError =>
      'Não foi possível alterar as configurações de atualização automática.';

  @override
  String get downloadPageError =>
      'Não foi possível abrir a página de download.';

  @override
  String get releasePageError => 'Não foi possível abrir a página da versão.';

  @override
  String get downloadError =>
      'Não foi possível baixar o pacote de atualização. Tente novamente mais tarde.';

  @override
  String get cimbarSendTitle => 'Envio rápido CIMBAR';

  @override
  String get cimbarReceiveTitle => 'Receção rápida CIMBAR';

  @override
  String get cimbarUnsupported =>
      'A transferência experimental CIMBAR está disponível apenas no Android e no iOS.';

  @override
  String get cimbarLoading => 'A carregar o motor experimental…';

  @override
  String get cimbarPageReadySend =>
      'Motor experimental carregado. Escolha um ficheiro.';

  @override
  String get cimbarPageReadyReceive =>
      'Motor experimental carregado. Toque em iniciar para pedir acesso à câmara.';

  @override
  String get cimbarEngineReady => 'Motor experimental pronto · Modo B';

  @override
  String get cimbarPreparingFile => 'A preparar o ficheiro…';

  @override
  String get cimbarPaused => 'Reprodução pausada';

  @override
  String get cimbarPlaying => 'A reproduzir';

  @override
  String get cimbarBroadcasting => 'Ficheiro pronto; a mostrar o código visual';

  @override
  String get cimbarDecoderReady => 'Descodificador pronto. A procurar CIMBAR.';

  @override
  String get cimbarDecoderReadyStart =>
      'Descodificador pronto. Toque em iniciar para pedir acesso à câmara.';

  @override
  String get cimbarCameraStarted => 'Câmara iniciada. A procurar CIMBAR.';

  @override
  String get cimbarDecoding => 'A descodificar com o worker upstream';

  @override
  String get cimbarFileHeaderReceived =>
      'Cabeçalho verificado. A receber blocos.';

  @override
  String get cimbarReceiving => 'A receber bytes verificados';

  @override
  String get cimbarRecoveredSaving =>
      'Ficheiro totalmente recuperado. A guardar…';

  @override
  String get cimbarRecoveredNotSaved =>
      'Ficheiro totalmente recuperado, mas ainda não foi guardado.';

  @override
  String get cimbarReceiveComplete => 'Receção concluída';

  @override
  String get cimbarLoadFailed => 'Falha ao carregar. Tente novamente.';

  @override
  String get cimbarTransferFailed =>
      'Falha na transferência CIMBAR. Tente novamente.';

  @override
  String get cimbarReloading => 'A recarregar o motor experimental…';

  @override
  String get cimbarRequestingCamera => 'A pedir acesso à câmara…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return 'Ficheiro: $name · $size';
  }

  @override
  String get cimbarSendRate => 'Referência upstream: 106 KB/s · Modo B';

  @override
  String cimbarReceiveRate(Object speed) {
    return 'Referência upstream: 106 KB/s · Medido nesta receção: $speed KB/s';
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
  String get cimbarStartReceive => 'Iniciar receção (pedir câmara)';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return 'Os ficheiros CIMBAR móveis não podem exceder $maxSize.';
  }

  @override
  String get cimbarPageLoadError =>
      'Não foi possível carregar a página CIMBAR offline. Tente novamente.';

  @override
  String get cimbarBridgeError =>
      'A transferência CIMBAR enviou um evento inválido. Tente novamente.';

  @override
  String get cimbarEngineError =>
      'O motor CIMBAR não está disponível. Tente novamente.';

  @override
  String get cimbarCameraError =>
      'Falha no acesso à câmara ou na descodificação. Verifique a permissão e tente novamente.';

  @override
  String get cimbarSendError =>
      'O emissor CIMBAR não conseguiu preparar o ficheiro. Tente novamente.';

  @override
  String get cimbarReceiveError =>
      'O recetor CIMBAR não conseguiu descodificar o ficheiro. Tente novamente.';

  @override
  String get cimbarVerificationError =>
      'Não foi possível verificar o ficheiro recebido. Tente novamente.';

  @override
  String get cimbarSaveError =>
      'Não foi possível guardar o ficheiro recuperado. Tente novamente.';

  @override
  String get cimbarHistoryError =>
      'O ficheiro foi guardado, mas não foi possível escrever o histórico da transferência.';

  @override
  String get cimbarAllFiles => 'Todos os ficheiros';

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
    return '${hours}h ${minutes}min';
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
