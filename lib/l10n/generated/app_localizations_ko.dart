// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'OneSend';

  @override
  String get followSystem => '시스템 설정 따르기';

  @override
  String get language => '언어';

  @override
  String get modeFast => '표준(권장)';

  @override
  String get modeReliable => '호환';

  @override
  String get modeTurboQr => '고속';

  @override
  String get modeCimbar => '컬러(실험)';

  @override
  String get modeQr => 'QR 코드';

  @override
  String get compatibilityMode => '호환성';

  @override
  String get cancel => '취소';

  @override
  String get done => '완료';

  @override
  String get close => '닫기';

  @override
  String get openFile => '열기';

  @override
  String get shareFile => '공유 / 전달';

  @override
  String get saveCopy => '사본 저장';

  @override
  String get revealInFolder => '폴더에서 보기';

  @override
  String get more => '더 보기';

  @override
  String get settings => '설정';

  @override
  String get about => 'OneSend 정보';

  @override
  String get transferTab => '전송';

  @override
  String get filesTab => '파일';

  @override
  String get filesTitle => '파일';

  @override
  String get filesSubtitle => '전송 기록과 받은 파일을 관리합니다.';

  @override
  String get theme => '테마';

  @override
  String get themeSubtitle => '시스템, 라이트 또는 다크';

  @override
  String get themeSystem => '시스템 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get themeSaveError => '테마를 저장하지 못했습니다. 다시 시도하세요.';

  @override
  String get aboutSubtitle => '버전, 개인정보 보호 및 오픈 소스.';

  @override
  String get clearHistory => '전송 기록 삭제';

  @override
  String get clearHistoryQuestion => '전송 기록을 삭제할까요?';

  @override
  String get clearHistoryDescription =>
      'OneSend에서 기록만 삭제합니다. 저장된 파일은 삭제되지 않습니다.';

  @override
  String get clearAction => '삭제';

  @override
  String get homeHeadline => '파일을,\n빛으로 보냅니다.';

  @override
  String get homeSubtitle => '네트워크 없음. 페어링 없음.\n화면과 카메라만 있으면 됩니다.';

  @override
  String get sendEyebrow => '보내기';

  @override
  String get receiveEyebrow => '받기';

  @override
  String get sendFile => '파일 보내기';

  @override
  String get receiveFile => '파일 받기';

  @override
  String get sendCardDescription => '화면에 코드를 표시하고 다른 기기를 그쪽으로 향하게 하세요.';

  @override
  String get receiveCardDescription => '카메라를 열고 변화하는 비주얼 코드를 스캔하세요.';

  @override
  String get recentTransfers => '최근 전송';

  @override
  String recordCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#개 기록',
      one: '1개 기록',
      zero: '0개 기록',
    );
    return '$_temp0';
  }

  @override
  String get historyFooter => '화면 ↔ 카메라 · 두 기기 사이에서 파일은 빛으로만 이동합니다';

  @override
  String get emptyHistory => '아직 전송 기록이 없습니다. 파일을 선택해 첫 광학 전송을 시작하세요.';

  @override
  String get receivedAndVerified => '수신 및 검증 완료';

  @override
  String get sendEnded => '보내기 종료';

  @override
  String get sent => '보냄';

  @override
  String get receivedFileActions => '받은 파일 작업';

  @override
  String get justNow => '방금';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#분 전',
      one: '1분 전',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#시간 전',
      one: '1시간 전',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#일 전',
      one: '1일 전',
    );
    return '$_temp0';
  }

  @override
  String monthDay(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get settingsIntroTitle => '다음 전송을 기기에 맞게 조정하세요.';

  @override
  String get settingsIntroBody => '새로 보내는 파일에는 기본 모드가 사용됩니다.';

  @override
  String get transportSection => '전송';

  @override
  String get defaultTransferAlgorithm => '기본 전송 알고리즘';

  @override
  String get algorithmDescription =>
      '일상 사용은 표준을 유지하세요. 설정에서 호환·고속·실험 컬러로 바꿀 수 있습니다.';

  @override
  String theoreticalSpeed(Object speed) {
    return '약 $speed';
  }

  @override
  String fastModeDescription(Object speed) {
    return '$speed; 대부분의 휴대폰과 밝은 화면에 맞는 일상 기본값입니다.';
  }

  @override
  String reliableModeDescription(Object speed) {
    return '$speed; 조명이 어둡거나 초점이 어려울 때 더 느리지만 안정적입니다.';
  }

  @override
  String turboModeDescription(Object speed) {
    return '$speed; 더 빠르지만 초점·노출·기기 요구가 더 높습니다.';
  }

  @override
  String get cimbarModeDescription =>
      '실험용 컬러 코드; 정점은 더 높지만 양쪽 모두 컬러를 선택해야 하며 조건이 더 까다롭습니다.';

  @override
  String get modeSaveError => '기본 전송 설정을 저장하지 못했습니다. 다시 시도하세요.';

  @override
  String get appSection => '앱';

  @override
  String languageSubtitle(Object language) {
    return '$language';
  }

  @override
  String get desktopUpdates => '자동 업데이트';

  @override
  String get desktopUpdatesSubtitle => '데스크톱에서 업데이트를 확인하고 자동 확인을 설정합니다.';

  @override
  String get mobileOfflineNote =>
      '모바일은 오프라인 상태로 유지됩니다. 전송 및 언어 설정만 사용할 수 있습니다.';

  @override
  String get languagePickerTitle => '언어 선택';

  @override
  String get languageSaveError => '언어 설정을 저장하지 못했습니다. 다시 시도하세요.';

  @override
  String modeAccessibilityLabel(Object mode, Object speed) {
    return '$mode, $speed';
  }

  @override
  String get experimentalVisualTransfer => '실험적인 오프라인 시각 전송';

  @override
  String get workingPrinciple => '작동 방식';

  @override
  String get workingPrincipleBody =>
      '파일을 변화하는 비주얼 코드 시퀀스로 인코딩합니다. 보내는 기기는 이를 표시하고, 받는 기기는 카메라로 각 프레임을 읽고 검증한 다음 파일을 복원합니다. 경로에는 화면과 카메라 사이의 빛만 사용됩니다.';

  @override
  String get whyWeBuiltIt => '만든 이유';

  @override
  String get whyWeBuiltItBody =>
      '네트워크, 계정, 페어링 없이 두 기기에서 파일을 주고받을 수 있습니다. OneSend는 기기에 이미 있는 화면과 카메라를 간단한 오프라인 채널로 바꿉니다.';

  @override
  String get privacy => '개인정보';

  @override
  String get privacyBody => '전송에는 네트워크나 서버를 사용하지 않습니다. 모바일에서는 카메라 접근만 필요합니다.';

  @override
  String get openPrivacyPolicy => '개인정보 처리방침 열기';

  @override
  String get cannotOpenPrivacy => '개인정보 처리방침을 열 수 없습니다. 다시 시도하세요.';

  @override
  String get openSourceAndAuthor => '오픈 소스 및 제작자';

  @override
  String get author => '제작자';

  @override
  String get license => '라이선스';

  @override
  String get version => '버전';

  @override
  String get github => 'GitHub';

  @override
  String get openGithub => 'GitHub 열기';

  @override
  String get opening => '여는 중…';

  @override
  String get versionUnavailable => '버전을 사용할 수 없음';

  @override
  String get readingVersion => '버전 읽는 중…';

  @override
  String get cannotOpenGithub => 'GitHub 페이지를 열지 못했습니다. 다시 시도하세요.';

  @override
  String get aboutFooter => 'OneSend · 광학 파일 전송';

  @override
  String versionLabel(String version) {
    return '버전 $version';
  }

  @override
  String settingsVersionFooter(String version) {
    return '$version';
  }

  @override
  String get acknowledgments => '감사의 말';

  @override
  String get acknowledgmentsIntro => 'OneSend 는 다음 오픈소스 프로젝트에 감사드립니다:';

  @override
  String get creditDecimen =>
      'decimen-optical-transfer — LT 코드 / 프로토콜 기반 (MIT)';

  @override
  String get creditQrDataTransfer => 'qr-data-transfer — 공개 아키텍처 참고 (코드 미포함)';

  @override
  String get creditLibcimbar => 'libcimbar v0.6.7c — 실험용 컬러 시각 코드 (MPL-2.0)';

  @override
  String get sendFeedback => '피드백';

  @override
  String get sendFeedbackSubtitle => 'GitHub Issue 로 제보';

  @override
  String get openGithubIssues => 'GitHub Issues 열기';

  @override
  String get cannotOpenGithubIssues => 'GitHub Issues 를 열 수 없습니다. 다시 시도하세요.';

  @override
  String get chooseAFile => '파일 선택';

  @override
  String sendFileDescription(Object maxSize) {
    return '파일이 변화하는 비주얼 코드 시퀀스로 바뀝니다.\n최대 $maxSize; 첫 테스트는 작은 파일로 시작하세요.';
  }

  @override
  String newTransferStatus(Object mode, Object speed) {
    return '새로 보내는 파일은 $mode 모드를 사용 · 이론상 속도 약 $speed';
  }

  @override
  String get transferModeLabel => '전송 모드';

  @override
  String get dropFilesHint => '또는 파일을 여기로 드래그하세요';

  @override
  String get dropFilesActive => '놓아서 보내기';

  @override
  String get reading => '읽는 중…';

  @override
  String get chooseFile => '파일 선택';

  @override
  String get sampleVideo => '내장 테스트 동영상 보내기';

  @override
  String get encodedPayloadTooLarge => '인코딩된 파일이 광학 전송 한도를 초과했습니다.';

  @override
  String modeBadge(Object mode) {
    return '$mode 모드';
  }

  @override
  String get broadcasting => '변화하는 비주얼 코드를 방송 중';

  @override
  String get pausedPlayback => '재생 일시중지됨';

  @override
  String get cameraAim => '다른 기기의 카메라를 이 흰 영역에 맞추세요';

  @override
  String passAndFrames(Object frames, Object pass) {
    return '패스 $pass · 프레임 $frames개 전송됨';
  }

  @override
  String runningTime(Object duration) {
    return '실행 시간 $duration';
  }

  @override
  String theoreticalRate(Object speed) {
    return '이론상 속도 $speed';
  }

  @override
  String currentRate(Object speed) {
    return '현재 속도 $speed';
  }

  @override
  String get resume => '재개';

  @override
  String get pause => '일시중지';

  @override
  String get endTransfer => '전송 종료';

  @override
  String get sendAnother => '다른 파일 보내기';

  @override
  String get chooseOtherFile => '다른 파일 선택';

  @override
  String fileTooLarge(Object maxSize) {
    return '파일은 $maxSize보다 클 수 없습니다.';
  }

  @override
  String get cannotReadFile => 'OneSend에서 이 파일을 읽지 못했습니다.';

  @override
  String get sampleVideoEmpty => '내장 테스트 동영상을 사용할 수 없습니다.';

  @override
  String sampleVideoTooLarge(Object maxSize) {
    return '내장 테스트 동영상이 $maxSize보다 큽니다.';
  }

  @override
  String get genericTransferError => '전송을 시작하지 못했습니다. 다시 시도하세요.';

  @override
  String get scanReceive => '스캔하여 받기';

  @override
  String get torch => '손전등';

  @override
  String get checkingAndSaving => '확인 및 저장 중…';

  @override
  String get pausedKeepProgress => '일시중지됨. 현재 진행률을 유지하려면 재개를 누르세요.';

  @override
  String get lookingForSender => '보내는 기기를 찾는 중…';

  @override
  String lockedModeCollecting(Object mode) {
    return '$mode 모드로 고정 · 비주얼 코드 수집 중';
  }

  @override
  String get scanInstruction => '비주얼 코드 전체가 프레임 안에 들어오도록 하고 기기를 고정하세요.';

  @override
  String get scannerBytesUnavailable =>
      'QR 코드를 감지했지만 카메라가 데이터를 반환하지 않았습니다. 계속 스캔합니다.';

  @override
  String get scannerInvalidFrame => 'OneSend 데이터가 아닌 QR 코드를 감지했습니다. 계속 스캔합니다.';

  @override
  String get desktopCameraInstruction =>
      '데스크톱 카메라 디코딩은 스크린샷을 사용하므로 모바일보다 느립니다.';

  @override
  String get verifying => '확인 중…';

  @override
  String get paused => '일시중지됨';

  @override
  String get waitingFirstFrame => '첫 프레임을 기다리는 중';

  @override
  String fountainProgress(Object frames) {
    return '$frames개 프레임 · Fountain 복구';
  }

  @override
  String blockProgress(Object blocks, Object frames, Object solved) {
    return '$frames개 프레임 · $solved/$blocks개 블록';
  }

  @override
  String modeAndSize(Object mode, Object size) {
    return '$mode · $size';
  }

  @override
  String get resumeScan => '스캔 재개';

  @override
  String get pauseScan => '스캔 일시중지';

  @override
  String get restart => '다시 시작';

  @override
  String get receivedComplete => '받음';

  @override
  String get verifiedNotSaved => '파일을 확인했지만 아직 저장하지 못했습니다.';

  @override
  String get verifiedSaved => '파일을 확인하여 이 기기에 저장했습니다.';

  @override
  String get retrySave => '저장 재시도';

  @override
  String get continueReceiving => '하나 더 받기';

  @override
  String recordWriteError(Object error) {
    return '파일은 저장했지만 기록을 쓸 수 없습니다: $error';
  }

  @override
  String saveFailed(Object error) {
    return '저장 실패: $error';
  }

  @override
  String get fileActions => '파일 작업';

  @override
  String get saveLocation => '저장 위치';

  @override
  String get unrecordedLocation => '저장 위치가 기록되지 않았습니다.';

  @override
  String get fileMissing => '파일이 없습니다. 이동되었거나 삭제되었을 수 있습니다.';

  @override
  String savedTo(Object path) {
    return '저장 위치: $path';
  }

  @override
  String iosSavedLocation(Object name) {
    return '파일 > 나의 iPhone/iPad > OneSend > 받은 파일 > $name';
  }

  @override
  String androidSavedLocation(Object name) {
    return '앱 저장 공간에 저장됨: $name. 사본 저장을 사용해 표시되는 폴더를 선택하세요.';
  }

  @override
  String copyExported(Object name) {
    return '사본 내보냄: $name (시스템 파일 선택기에서 위치를 선택함)';
  }

  @override
  String copyExportedDesktop(Object path) {
    return '사본을 다음으로 내보냄: $path';
  }

  @override
  String get fileOperationError => '파일 작업에 실패했습니다. 다시 시도하세요.';

  @override
  String get fileNotFound => '파일이 존재하지 않습니다.';

  @override
  String get fileAccessDenied => '이 파일에 액세스할 권한이 없습니다.';

  @override
  String get operationCancelled => '작업이 취소되었습니다.';

  @override
  String get unsupportedOperation => '현재 기기에서는 이 작업을 지원하지 않습니다.';

  @override
  String get openFileError => '시스템에서 이 파일을 열지 못했습니다.';

  @override
  String get shareFileError => '이 파일을 공유하지 못했습니다. 다시 시도하세요.';

  @override
  String get revealFileError => '폴더에서 파일을 표시하지 못했습니다. 다시 시도하세요.';

  @override
  String get saveFileError => '파일을 내보내지 못했습니다. 다시 시도하세요.';

  @override
  String get locationPathUnknown => '저장 위치를 알 수 없습니다.';

  @override
  String get updateAppDescription => '화면과 카메라 사이의 오프라인 파일 전송';

  @override
  String get currentVersion => '현재 버전';

  @override
  String get automaticChecks => '업데이트 자동 확인';

  @override
  String get automaticChecksSubtitle => '하루에 한 번 조용히 확인하고 새 버전을 찾았을 때만 알립니다.';

  @override
  String get downloadPage => '다운로드 페이지';

  @override
  String get checking => '확인 중…';

  @override
  String get checkForUpdates => '업데이트 확인';

  @override
  String updateAvailable(Object version) {
    return 'OneSend $version을(를) 사용할 수 있습니다';
  }

  @override
  String get releaseNotes => '새로운 기능';

  @override
  String get downloading => '다운로드 및 확인 중…';

  @override
  String downloadingPercent(Object percent) {
    return '$percent% 다운로드 및 확인 중…';
  }

  @override
  String get viewRelease => '릴리스 페이지 보기';

  @override
  String get later => '나중에';

  @override
  String get downloadUpdate => '업데이트 다운로드';

  @override
  String get latestVersion => '최신 버전을 사용하고 있습니다.';

  @override
  String get updateCheckWindowOpened => '업데이트 확인 창이 열려 있습니다.';

  @override
  String get unsupportedUpdate => '이 플랫폼에서는 앱 내 업데이트를 지원하지 않습니다.';

  @override
  String get updateCheckFailed => '업데이트를 확인하지 못했습니다. 나중에 다시 시도하세요.';

  @override
  String get automaticUpdateError => '자동 업데이트 설정을 변경하지 못했습니다.';

  @override
  String get downloadPageError => '다운로드 페이지를 열지 못했습니다.';

  @override
  String get releasePageError => '릴리스 페이지를 열지 못했습니다.';

  @override
  String get downloadError => '업데이트 패키지를 다운로드하지 못했습니다. 나중에 다시 시도하세요.';

  @override
  String get cimbarSendTitle => 'CIMBAR 고속 보내기';

  @override
  String get cimbarReceiveTitle => 'CIMBAR 고속 받기';

  @override
  String get cimbarUnsupported => '실험적인 CIMBAR 전송은 Android와 iOS에서만 사용할 수 있습니다.';

  @override
  String get cimbarLoading => '실험 엔진을 불러오는 중…';

  @override
  String get cimbarPageReadySend => '실험 엔진을 불러왔습니다. 파일을 선택하세요.';

  @override
  String get cimbarPageReadyReceive => '실험 엔진을 불러왔습니다. 시작을 눌러 카메라 권한을 요청하세요.';

  @override
  String get cimbarEngineReady => '실험 엔진 준비 완료 · 모드 B';

  @override
  String get cimbarPreparingFile => '파일을 준비하는 중…';

  @override
  String get cimbarPaused => '재생 일시정지';

  @override
  String get cimbarPlaying => '재생 중';

  @override
  String get cimbarBroadcasting => '파일 준비 완료; 비주얼 코드를 표시하는 중';

  @override
  String get cimbarDecoderReady => '디코더 준비 완료. CIMBAR를 찾는 중입니다.';

  @override
  String get cimbarDecoderReadyStart => '디코더 준비 완료. 시작을 눌러 카메라 권한을 요청하세요.';

  @override
  String get cimbarCameraStarted => '카메라가 시작되었습니다. CIMBAR를 찾는 중입니다.';

  @override
  String get cimbarDecoding => '업스트림 worker로 디코딩하는 중';

  @override
  String get cimbarFileHeaderReceived => '파일 헤더 확인 완료. 청크를 받는 중입니다.';

  @override
  String get cimbarReceiving => '확인된 바이트를 받는 중';

  @override
  String get cimbarRecoveredSaving => '파일을 모두 복구했습니다. 저장하는 중…';

  @override
  String get cimbarRecoveredNotSaved => '파일을 모두 복구했지만 아직 저장하지 못했습니다.';

  @override
  String get cimbarReceiveComplete => '수신 완료';

  @override
  String get cimbarLoadFailed => '불러오지 못했습니다. 다시 시도하세요.';

  @override
  String get cimbarTransferFailed => 'CIMBAR 전송에 실패했습니다. 다시 시도하세요.';

  @override
  String get cimbarReloading => '실험 엔진을 다시 불러오는 중…';

  @override
  String get cimbarRequestingCamera => '카메라 권한을 요청하는 중…';

  @override
  String cimbarFileInfo(Object name, Object size) {
    return '파일: $name · $size';
  }

  @override
  String get cimbarSendRate => '업스트림 참고값: 106 KB/s · 모드 B';

  @override
  String cimbarReceiveRate(Object speed) {
    return '업스트림 참고값: 106 KB/s · 이번 수신 실측값: $speed KB/s';
  }

  @override
  String cimbarReceiveProgress(
    Object expected,
    Object received,
    Object seconds,
  ) {
    return '복구됨 $received / $expected · $seconds초';
  }

  @override
  String cimbarReceiveProgressNoTotal(Object received, Object seconds) {
    return '복구됨 $received · $seconds초';
  }

  @override
  String get cimbarStartReceive => '수신 시작(카메라 요청)';

  @override
  String cimbarFileTooLarge(Object maxSize) {
    return '모바일 CIMBAR 파일은 $maxSize보다 클 수 없습니다.';
  }

  @override
  String get cimbarPageLoadError => '오프라인 CIMBAR 페이지를 불러오지 못했습니다. 다시 시도하세요.';

  @override
  String get cimbarBridgeError => 'CIMBAR 전송에서 잘못된 이벤트를 보냈습니다. 다시 시도하세요.';

  @override
  String get cimbarEngineError => 'CIMBAR 엔진을 사용할 수 없습니다. 다시 시도하세요.';

  @override
  String get cimbarCameraError => '카메라 접근 또는 디코딩에 실패했습니다. 권한을 확인하고 다시 시도하세요.';

  @override
  String get cimbarSendError => 'CIMBAR 송신자가 파일을 준비하지 못했습니다. 다시 시도하세요.';

  @override
  String get cimbarReceiveError => 'CIMBAR 수신자가 파일을 디코딩하지 못했습니다. 다시 시도하세요.';

  @override
  String get cimbarVerificationError => '받은 파일을 확인하지 못했습니다. 다시 시도하세요.';

  @override
  String get cimbarSaveError => '복구한 파일을 저장하지 못했습니다. 다시 시도하세요.';

  @override
  String get cimbarHistoryError => '파일은 저장했지만 전송 기록을 작성하지 못했습니다.';

  @override
  String get cimbarAllFiles => '모든 파일';

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
    return '$hours시간 $minutes분';
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
