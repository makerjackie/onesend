import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app.dart';
import '../core/barcode_payload_adapter.dart';
import '../core/envelope.dart';
import '../core/optical_transfer.dart';
import '../core/transfer_codec.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/file_service.dart';
import '../services/transfer_store.dart';
import '../widgets/desktop_camera_receiver.dart';
import '../widgets/file_tile.dart';
import '../widgets/stored_file_actions.dart';
import '../widgets/transfer_mode_selector.dart';
import 'cimbar_transfer_screen.dart';

typedef ReceivePayloadDecoder =
    Future<TransferFile> Function(Uint8List payload);
typedef ReceivedFileSaver = Future<StoredTransfer> Function(TransferFile file);

enum _ReceiveSavePhase {
  scanning,
  recovering,
  decoding,
  readyToSave,
  saving,
  saved,
  saveFailed,
}

enum _BarcodeObservation { bytesUnavailable, invalidFrame }

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({
    required this.store,
    this.settings,
    this.payloadDecoder,
    this.receivedFileSaver,
    @visibleForTesting this.cameraBuilder,
    super.key,
  });

  final TransferStore store;
  final AppSettings? settings;
  final ReceivePayloadDecoder? payloadDecoder;
  final ReceivedFileSaver? receivedFileSaver;

  /// Test seam that avoids constructing a native camera preview.
  @visibleForTesting
  final WidgetBuilder? cameraBuilder;

  @override
  State<ReceiveScreen> createState() => ReceiveScreenState();
}

@visibleForTesting
class ReceiveScreenState extends State<ReceiveScreen>
    with WidgetsBindingObserver {
  final OpticalReceiver _receiver = OpticalReceiver();
  final MobileScannerController _mobileController = MobileScannerController(
    // ReceiveScreen owns the controller lifecycle. Keeping autoStart off
    // avoids a race with the persisted CIMBAR/QR selection and with our
    // explicit stop/start transitions.
    autoStart: false,
    detectionSpeed: DetectionSpeed.unrestricted,
    formats: <BarcodeFormat>[BarcodeFormat.qrCode],
    torchEnabled: false,
  );

  ReceiverSnapshot? _snapshot;
  TransferFile? _receivedFile;
  StoredTransfer? _storedFile;
  String? _error;
  _BarcodeObservation? _barcodeObservation;
  bool _paused = false;
  bool _pausedByLifecycle = false;
  bool _isDisposing = false;
  _ReceiveSavePhase _savePhase = _ReceiveSavePhase.scanning;
  DateTime? _receiveStartedAt;
  Timer? _speedTicker;
  Future<void> _mobileOperationTail = Future<void>.value();
  late TransferAlgorithm _algorithm;
  late TransferMode _mode;

  bool get _usesMobileScanner =>
      widget.cameraBuilder == null &&
      (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  bool get _usesCimbar => _algorithm == TransferAlgorithm.cimbar;

  bool get _processing =>
      _savePhase == _ReceiveSavePhase.recovering ||
      _savePhase == _ReceiveSavePhase.decoding ||
      _savePhase == _ReceiveSavePhase.saving;

  bool get _saving => _savePhase == _ReceiveSavePhase.saving;

  bool get _completed =>
      _savePhase == _ReceiveSavePhase.readyToSave ||
      _savePhase == _ReceiveSavePhase.saving ||
      _savePhase == _ReceiveSavePhase.saved ||
      _savePhase == _ReceiveSavePhase.saveFailed;

  @override
  void initState() {
    super.initState();
    _algorithm =
        widget.settings?.transferAlgorithm ??
        AppSettings.defaultTransferAlgorithm;
    _mode = widget.settings?.defaultMode ?? AppSettings.defaultTransferMode;
    WidgetsBinding.instance.addObserver(this);
    // QR and CIMBAR both keep the screen awake while the receive route is open.
    unawaited(_enableWakelock());
    if (_usesMobileScanner && !_usesCimbar) {
      _scheduleMobileScannerStart();
    }
    _speedTicker = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted || _completed || _snapshot == null || _paused) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    _speedTicker?.cancel();
    unawaited(_disposeMobileController());
    unawaited(_disableWakelock());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_pauseForLifecycle());
      case AppLifecycleState.resumed:
        unawaited(_resumeAfterLifecycle());
    }
  }

  Future<void> _pauseForLifecycle() async {
    if (!_usesMobileScanner ||
        _usesCimbar ||
        _completed ||
        _processing ||
        _paused ||
        _isDisposing) {
      return;
    }
    final controllerState = _mobileController.value;
    // Permission prompts can emit inactive before the controller is attached
    // or started. Do not turn that transient state into a dead scanner.
    if (!controllerState.isRunning && !controllerState.isStarting) return;
    _paused = true;
    _pausedByLifecycle = true;
    try {
      await _stopMobileScanner();
    } catch (_) {}
    await _disableWakelock();
    if (mounted) setState(() {});
  }

  Future<void> _resumeAfterLifecycle() async {
    if (!_pausedByLifecycle ||
        !_usesMobileScanner ||
        _usesCimbar ||
        _completed ||
        _processing ||
        _isDisposing ||
        !mounted) {
      return;
    }
    setState(() {
      _paused = false;
      _pausedByLifecycle = false;
    });
    await _enableWakelock();
    final started = await _startMobileScanner();
    if (!started && mounted && !_completed && !_processing) {
      setState(() {
        _paused = true;
        _pausedByLifecycle = true;
      });
    }
  }

  void _scheduleMobileScannerStart() {
    if (!_usesMobileScanner ||
        _usesCimbar ||
        _paused ||
        _completed ||
        _processing ||
        _isDisposing) {
      return;
    }
    // The MobileScanner child attaches the external controller during its
    // initState. Start only after that attachment, never in the same turn as
    // a QR/CIMBAR mode transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startMobileScanner());
    });
  }

  Future<bool> _startMobileScanner() async {
    if (!_usesMobileScanner ||
        _usesCimbar ||
        _paused ||
        _completed ||
        _processing ||
        _isDisposing ||
        !mounted) {
      return false;
    }
    try {
      await _enqueueMobileOperation(() async {
        if (!_usesMobileScanner ||
            _usesCimbar ||
            _paused ||
            _completed ||
            _processing ||
            _isDisposing ||
            !mounted) {
          return;
        }
        await _mobileController.start();
      });
      final started = _mobileController.value.isRunning;
      if (!started && mounted && _mobileController.value.error != null) {
        setState(
          () => _error = _friendlyReceiveError(_mobileController.value.error!),
        );
      }
      return started;
    } catch (error) {
      if (mounted && !_isDisposing) {
        setState(() => _error = _friendlyReceiveError(error));
      }
      return false;
    }
  }

  Future<void> _stopMobileScanner() async {
    if (!_usesMobileScanner) return;
    try {
      await _enqueueMobileOperation(_mobileController.stop);
    } catch (_) {
      // The controller may already be stopped or still uninitialized.
    }
  }

  Future<void> _enqueueMobileOperation(Future<void> Function() operation) {
    final scheduled = _mobileOperationTail.then<void>((_) => operation());
    _mobileOperationTail = scheduled.then<void>((_) {}, onError: (_, _) {});
    return scheduled;
  }

  Future<void> _selectQrMode(TransferMode mode) async {
    if (_processing || _completed) return;
    if (_algorithm == TransferAlgorithm.qr && _mode == mode) return;
    setState(() {
      _algorithm = TransferAlgorithm.qr;
      _mode = mode;
      _snapshot = null;
      _error = null;
      _receiveStartedAt = null;
      _paused = false;
      _pausedByLifecycle = false;
      _barcodeObservation = null;
    });
    if (_usesMobileScanner) {
      _scheduleMobileScannerStart();
    }
    final settings = widget.settings;
    if (settings == null) return;
    try {
      await settings.setDefaultAlgorithm(TransferAlgorithm.qr);
      await settings.setDefaultMode(mode);
    } catch (_) {}
  }

  Future<void> _selectCimbar() async {
    if (_processing || _completed) return;
    if (_algorithm == TransferAlgorithm.cimbar) return;
    // Native QR scanner and the CIMBAR WebView cannot share one camera
    // session. Stop the QR pipeline first so only one capture path is live;
    // the OS camera permission is app-level and should not re-prompt.
    if (_usesMobileScanner) {
      try {
        await _stopMobileScanner();
      } catch (_) {}
    }
    _receiver.reset();
    setState(() {
      _algorithm = TransferAlgorithm.cimbar;
      _snapshot = null;
      _error = null;
      _receiveStartedAt = null;
      _paused = false;
      _pausedByLifecycle = false;
      _barcodeObservation = null;
    });
    final settings = widget.settings;
    if (settings == null) return;
    try {
      await settings.setDefaultAlgorithm(TransferAlgorithm.cimbar);
    } catch (_) {}
  }

  int _approxReceivedBytes(ReceiverSnapshot snapshot) {
    if (snapshot.totalLength <= 0) return 0;
    if (snapshot.usesRatelessFountain) {
      return (snapshot.progress * snapshot.totalLength).round().clamp(
        0,
        snapshot.totalLength,
      );
    }
    final fromBlocks = snapshot.solvedBlocks * snapshot.blockLength;
    return fromBlocks.clamp(0, snapshot.totalLength);
  }

  double _currentReceiveBytesPerSecond() {
    final snapshot = _snapshot;
    final startedAt = _receiveStartedAt;
    if (snapshot == null || startedAt == null) return 0;
    final elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    if (elapsed <= 0) return 0;
    return _approxReceivedBytes(snapshot) * 1000 / elapsed;
  }

  Widget _buildModeChips({required bool enabled}) {
    return TransferModeSelector(
      algorithm: _algorithm,
      mode: _mode,
      enabled: enabled,
      showQrProfiles: false,
      dense: true,
      keyPrefix: 'receive-mode',
      onQrModeSelected: (mode) => unawaited(_selectQrMode(mode)),
      onCimbarSelected: () => unawaited(_selectCimbar()),
    );
  }

  void _onMobileDetectError(Object error, StackTrace stackTrace) {
    if (error is! MobileScannerException || !mounted) return;
    setState(() {
      _paused = true;
      _pausedByLifecycle = false;
      _error = AppLocalizations.of(context)!.cimbarCameraError;
    });
    unawaited(_stopMobileScanner());
    unawaited(_disableWakelock());
  }

  void _onMobileCapture(BarcodeCapture capture) {
    if (_completed || _paused || _processing) return;
    ReceiverEvent? latest;
    _BarcodeObservation? observation;
    var sawUsableFrame = false;
    for (final barcode in capture.barcodes) {
      final payload = adaptBarcodePayload(barcode);
      final bytes = payload.bytes;
      if (bytes == null) {
        observation ??= _BarcodeObservation.bytesUnavailable;
        continue;
      }
      final event = _receiver.consume(bytes);
      if (event == null) {
        observation = _BarcodeObservation.invalidFrame;
        continue;
      }
      sawUsableFrame = true;
      latest = event;
      if (event.error != null || event.payload != null) break;
    }
    _setBarcodeObservation(sawUsableFrame ? null : observation);
    _handleReceiverEvent(latest);
  }

  void _setBarcodeObservation(_BarcodeObservation? observation) {
    if (_barcodeObservation == observation || !mounted) return;
    setState(() => _barcodeObservation = observation);
    if (observation != null) {
      debugPrint('[OneSend QR scanner] ${observation.name}; continuing scan');
    }
  }

  String _barcodeObservationMessage(AppLocalizations l10n) {
    return switch (_barcodeObservation) {
      _BarcodeObservation.bytesUnavailable => l10n.scannerBytesUnavailable,
      _BarcodeObservation.invalidFrame => l10n.scannerInvalidFrame,
      null => '',
    };
  }

  void _consume(Uint8List bytes) {
    if (_completed || _paused || _processing) return;
    _handleReceiverEvent(_receiver.consume(bytes));
  }

  void _handleReceiverEvent(ReceiverEvent? event) {
    if (event == null || !mounted) return;
    setState(() {
      _snapshot = event.snapshot;
      _error = event.error;
      _receiveStartedAt ??= DateTime.now();
    });
    if (event.error != null) {
      setState(() => _savePhase = _ReceiveSavePhase.recovering);
      unawaited(_recoverFromFailure(event.error!));
      return;
    }
    final payload = event.payload;
    if (payload != null && event.verified) {
      unawaited(_acceptVerifiedPayload(payload));
    }
  }

  /// Direct state-machine entry for widget tests. Production enters through
  /// [_handleReceiverEvent] after the optical receiver verifies a payload.
  @visibleForTesting
  Future<void> acceptVerifiedPayloadForTesting(Uint8List payload) =>
      _acceptVerifiedPayload(payload);

  /// Sends a deterministic native scanner capture through the production
  /// adapter/receiver path without constructing a platform camera.
  @visibleForTesting
  void handleMobileCaptureForTesting(BarcodeCapture capture) =>
      _onMobileCapture(capture);

  @visibleForTesting
  String? get barcodeObservationForTesting => _barcodeObservation?.name;

  @visibleForTesting
  bool get pausedForTesting => _paused;

  Future<void> _acceptVerifiedPayload(Uint8List payload) async {
    if (!mounted || _savePhase != _ReceiveSavePhase.scanning) return;
    setState(() {
      _savePhase = _ReceiveSavePhase.decoding;
      _error = null;
    });
    await _finishTransfer(payload);
  }

  Future<void> _finishTransfer(Uint8List payload) async {
    try {
      if (_usesMobileScanner) {
        await _stopMobileScanner();
      }
      final file =
          await (widget.payloadDecoder ?? decodeTransferFileInBackground)(
            payload,
          );
      if (!mounted || _savePhase != _ReceiveSavePhase.decoding) return;
      setState(() {
        _receivedFile = file;
        _savePhase = _ReceiveSavePhase.readyToSave;
        _error = null;
      });
      await _saveDecodedFile();
    } catch (error) {
      await _recoverFromFailure(_friendlyReceiveError(error));
    }
  }

  /// Saves the decoded file independently from decoding so a storage failure
  /// can be retried without asking the sender to replay the whole transfer.
  Future<void> _saveDecodedFile() async {
    final file = _receivedFile;
    final canSave =
        _savePhase == _ReceiveSavePhase.readyToSave ||
        _savePhase == _ReceiveSavePhase.saveFailed;
    if (!mounted || file == null || !canSave || _storedFile != null) return;
    setState(() {
      _savePhase = _ReceiveSavePhase.saving;
      _error = null;
    });
    try {
      final stored = await (widget.receivedFileSaver ?? saveReceivedFile)(file);
      if (!mounted || _savePhase != _ReceiveSavePhase.saving) return;
      setState(() {
        _storedFile = stored;
        _savePhase = _ReceiveSavePhase.saved;
        _error = null;
      });
      try {
        await widget.store.add(
          TransferRecord(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            direction: TransferDirection.received,
            fileName: stored.name,
            bytes: stored.bytes,
            createdAt: DateTime.now(),
            status: 'received',
            path: stored.path,
            verified: true,
          ),
        );
      } catch (error) {
        if (mounted) {
          setState(
            () => _error = AppLocalizations.of(
              context,
            )!.recordWriteError(_friendlyReceiveError(error)),
          );
        }
      }
      // Cleanup is best effort and must not delay a successfully saved file.
      unawaited(_disableWakelock());
    } catch (error) {
      if (!mounted || _savePhase != _ReceiveSavePhase.saving) return;
      setState(() {
        _storedFile = null;
        _savePhase = _ReceiveSavePhase.saveFailed;
        _error = AppLocalizations.of(
          context,
        )!.saveFailed(_friendlyReceiveError(error));
      });
    }
  }

  Future<void> _retrySave() async {
    if (_savePhase != _ReceiveSavePhase.saveFailed || _receivedFile == null) {
      return;
    }
    await _saveDecodedFile();
  }

  Future<void> _recoverFromFailure(String message) async {
    final stableMessage = _friendlyReceiveError(message);
    if (_usesMobileScanner) {
      await _stopMobileScanner();
    }
    _receiver.reset();
    if (!mounted) return;
    setState(() {
      _snapshot = null;
      _receivedFile = null;
      _storedFile = null;
      _savePhase = _ReceiveSavePhase.scanning;
      _error = stableMessage;
      _receiveStartedAt = null;
      _barcodeObservation = null;
      _pausedByLifecycle = false;
    });
    try {
      await _enableWakelock();
    } catch (_) {
      // Camera progress remains usable if wakelock is unavailable.
    }
    if (_usesMobileScanner) {
      _scheduleMobileScannerStart();
    }
  }

  Future<void> _togglePause() async {
    if (_completed || _processing) return;
    try {
      if (_paused) {
        setState(() {
          _paused = false;
          _pausedByLifecycle = false;
        });
        await _enableWakelock();
        if (_usesMobileScanner && !_usesCimbar) {
          final started = await _startMobileScanner();
          if (!started && mounted) {
            setState(() => _paused = true);
          }
        }
      } else {
        if (_usesMobileScanner) await _stopMobileScanner();
        await _disableWakelock();
        if (mounted) {
          setState(() {
            _paused = true;
            _pausedByLifecycle = false;
          });
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyReceiveError(error));
    }
  }

  Future<void> _reset() async {
    if (_usesMobileScanner) {
      await _stopMobileScanner();
    }
    _receiver.reset();
    if (!mounted) return;
    setState(() {
      _snapshot = null;
      _receivedFile = null;
      _storedFile = null;
      _error = null;
      _savePhase = _ReceiveSavePhase.scanning;
      _paused = false;
      _pausedByLifecycle = false;
      _barcodeObservation = null;
      _receiveStartedAt = null;
    });
    await _enableWakelock();
    if (_usesMobileScanner) {
      _scheduleMobileScannerStart();
    }
  }

  String _friendlyReceiveError(Object error) {
    final l10n = AppLocalizations.of(context)!;
    final raw = error
        .toString()
        .replaceFirst('FormatException: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceFirst('StateError: ', '');
    final lower = raw.toLowerCase();
    if (lower.contains('camera') ||
        lower.contains('permission') ||
        raw.contains('相机') ||
        raw.contains('权限')) {
      return l10n.cimbarCameraError;
    }
    if (lower.contains('checksum') ||
        lower.contains('crc') ||
        lower.contains('verify') ||
        raw.contains('校验')) {
      return l10n.cimbarVerificationError;
    }
    return localizedTransferError(
      context,
      error,
      fallback: l10n.genericTransferError,
    );
  }

  Future<void> _toggleTorch() async {
    try {
      await _mobileController.toggleTorch();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyReceiveError(error));
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Wakelock is unavailable in widget tests and some desktop builds.
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Keep file actions usable even when the platform cleanup fails.
    }
  }

  Future<void> _disposeMobileController() async {
    try {
      await _stopMobileScanner();
      await _mobileController.dispose();
    } catch (_) {
      // Disposal is best effort during route teardown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Same shell as send: top mode chips stay visible; only the body swaps
    // between QR scanner and color-code panel.
    return Scaffold(
      appBar: _buildReceiveAppBar(l10n),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_completed) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: _buildModeChips(enabled: !_processing),
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: _completed
                  ? _buildCompleted()
                  : _usesCimbar
                  ? CimbarTransferScreen(
                      key: const ValueKey<String>('receive-cimbar-panel'),
                      direction: CimbarDirection.receive,
                      store: widget.store,
                      embedded: true,
                      // Reuse the app-level camera grant; WebView still has to
                      // open its own stream, but we should not sound like a
                      // second permission prompt.
                      autoStartReceive: true,
                    )
                  : _buildScanner(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildReceiveAppBar(AppLocalizations l10n) {
    return AppBar(
      toolbarHeight: 52,
      titleSpacing: 16,
      title: Text(
        l10n.scanReceive,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (_usesMobileScanner && !_usesCimbar && !_completed)
          IconButton(
            tooltip: l10n.torch,
            onPressed: _processing ? null : _toggleTorch,
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
      ],
    );
  }

  Widget _buildScanner() {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _snapshot;
    final progress = snapshot?.progress;
    final currentRate = _currentReceiveBytesPerSecond();
    final status = _processing
        ? l10n.checkingAndSaving
        : _paused
        ? l10n.pausedKeepProgress
        : snapshot == null
        ? l10n.lookingForSender
        : l10n.lockedModeCollecting(
            _localizedReceiveModeLabel(l10n, snapshot.mode),
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < oneSendWideBreakpoint;
        final workbench = constraints.maxWidth >= oneSendWorkbenchBreakpoint;
        final contentWidth = constraints.maxWidth < 1100
            ? constraints.maxWidth
            : 1100.0;
        final horizontalPadding = compact ? 16.0 : 20.0;
        final verticalPadding = compact ? 8.0 : 14.0;

        final readout = _buildScanReadout(
          l10n: l10n,
          status: status,
          progress: progress,
          currentRate: currentRate,
          snapshot: snapshot,
          compact: compact,
        );
        final controls = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            readout,
            if (_error != null) ...[
              const SizedBox(height: 6),
              _ReceiveError(message: _error!, compact: true),
            ],
            SizedBox(height: compact ? 8 : 12),
            _buildScannerControl(l10n: l10n, compact: compact),
          ],
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Center(
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  verticalPadding,
                ),
                // One viewport only — never scroll. Camera fills leftover
                // height; readout + control stay pinned below (or beside).
                child: workbench
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 7,
                            child: KeyedSubtree(
                              key: const ValueKey<String>(
                                'receive-camera-frame',
                              ),
                              child: _buildCameraFrame(l10n),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 4,
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: readout,
                                      ),
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 8),
                                      _ReceiveError(
                                        message: _error!,
                                        compact: true,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    _buildScannerControl(
                                      l10n: l10n,
                                      compact: false,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: KeyedSubtree(
                              key: const ValueKey<String>(
                                'receive-camera-frame',
                              ),
                              child: _buildCameraFrame(l10n),
                            ),
                          ),
                          SizedBox(height: compact ? 8 : 10),
                          controls,
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraFrame(AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(oneSendRadiusCard),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildCamera(),
          IgnorePointer(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(paused: _paused),
            ),
          ),
          if (_paused || _processing)
            Container(
              color: oneSendInk.withValues(alpha: 0.86),
              alignment: Alignment.center,
              child: Text(
                _processing ? l10n.verifying : l10n.paused,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanReadout({
    required AppLocalizations l10n,
    required String status,
    required double? progress,
    required double currentRate,
    required ReceiverSnapshot? snapshot,
    required bool compact,
  }) {
    final progressValue = progress?.clamp(0.0, 1.0).toDouble();
    final progressPercent = ((progressValue ?? 0) * 100).round();
    final detail = snapshot == null
        ? l10n.waitingFirstFrame
        : snapshot.usesRatelessFountain
        ? l10n.fountainProgress(snapshot.framesNew)
        : l10n.blockProgress(
            snapshot.blockCount,
            snapshot.framesNew,
            snapshot.solvedBlocks,
          );
    final modeAndSize = snapshot == null
        ? null
        : l10n.modeAndSize(
            _localizedReceiveModeLabel(l10n, snapshot.mode),
            formatBytes(snapshot.totalLength),
          );

    return Column(
      key: const ValueKey<String>('receive-scan-readout'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                status,
                key: const ValueKey<String>('receive-scan-status'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$progressPercent%',
              key: const ValueKey<String>('receive-progress-percent'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            key: const ValueKey<String>('receive-progress'),
            minHeight: 6,
            value: progressValue ?? 0,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.12),
            color: oneSendLime,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.currentRate(formatTransferSpeed(currentRate)),
                key: const ValueKey<String>('receive-current-rate'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!compact && snapshot?.mode != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  l10n.theoreticalRate(
                    formatTransferSpeed(snapshot!.mode!.usefulBytesPerSecond),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: oneSendMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(
              child: Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (modeAndSize != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  modeAndSize,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          _usesMobileScanner
              ? l10n.scanInstruction
              : l10n.desktopCameraInstruction,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: oneSendMuted, fontSize: 11),
        ),
        if (_barcodeObservation != null) ...[
          const SizedBox(height: 3),
          Text(
            _barcodeObservationMessage(l10n),
            key: const ValueKey<String>('receive-barcode-observation'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: oneSendMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildScannerControl({
    required AppLocalizations l10n,
    required bool compact,
  }) {
    // One control only: 暂停扫描 ↔ 继续扫描. No dropdown / no second button.
    final toggleLabel = _paused ? l10n.resumeScan : l10n.pauseScan;
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: compact ? double.infinity : 320,
        height: 48,
        child: FilledButton.icon(
          key: const ValueKey<String>('receive-scan-control'),
          onPressed: _processing ? null : () => unawaited(_togglePause()),
          icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
          label: Text(toggleLabel),
          style: FilledButton.styleFrom(
            backgroundColor: _paused ? oneSendLime : oneSendInk,
            foregroundColor: _paused ? oneSendInk : Colors.white,
            disabledBackgroundColor: oneSendInk.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: oneSendInk, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCamera() {
    final cameraBuilder = widget.cameraBuilder;
    if (cameraBuilder != null) return cameraBuilder(context);
    if (_usesMobileScanner) {
      return MobileScanner(
        controller: _mobileController,
        fit: BoxFit.cover,
        onDetect: _onMobileCapture,
        onDetectError: _onMobileDetectError,
        errorBuilder: (context, _) => ColoredBox(
          color: oneSendInk,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context)!.cimbarCameraError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }
    return DesktopCameraReceiver(
      enabled: !_paused && !_processing,
      onFrame: _consume,
    );
  }

  Widget _buildCompleted() {
    final l10n = AppLocalizations.of(context)!;
    final file = _receivedFile!;
    final stored = _storedFile;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: constraints.maxHeight,
            ),
            child: Card(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: oneSendLime,
                        border: Border.all(color: oneSendInk, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.check_rounded, size: 36),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.receivedComplete,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stored == null
                          ? l10n.verifiedNotSaved
                          : l10n.verifiedSaved,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    FileTile(
                      name: file.name,
                      bytes: file.bytes.length,
                      icon: Icons.south_west_rounded,
                    ),
                    if (_saving) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 4),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      _ReceiveError(message: _error!, compact: true),
                    ],
                    const SizedBox(height: 12),
                    if (stored != null)
                      StoredFileActions(file: stored)
                    else if (!_saving)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey<String>('receive-retry-save'),
                          onPressed: _retrySave,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(l10n.retrySave),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _reset,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text(l10n.continueReceiving),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _localizedReceiveModeLabel(AppLocalizations l10n, TransferMode? mode) {
  return switch (mode) {
    TransferMode.reliable => l10n.modeReliable,
    TransferMode.fast => l10n.modeFast,
    TransferMode.turbo => l10n.modeTurboQr,
    null => l10n.compatibilityMode,
  };
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.paused});

  final bool paused;

  @override
  void paint(Canvas canvas, Size size) {
    final frameSize = size.shortestSide * 0.62;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: frameSize,
      height: frameSize,
    );
    final paint = Paint()
      ..color = paused ? Colors.white54 : oneSendLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const corner = 28.0;
    final path = Path()
      ..moveTo(rect.left, rect.top + corner)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + corner, rect.top)
      ..moveTo(rect.right - corner, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + corner)
      ..moveTo(rect.right, rect.bottom - corner)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right - corner, rect.bottom)
      ..moveTo(rect.left + corner, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.bottom - corner);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.paused != paused;
}

class _ReceiveError extends StatelessWidget {
  const _ReceiveError({required this.message, this.compact = false});

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xffffe5e1),
        border: Border.all(
          color: const Color(0xffa32820),
          width: compact ? 1 : 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message,
        maxLines: compact ? 2 : null,
        overflow: compact ? TextOverflow.ellipsis : null,
        style: TextStyle(
          color: const Color(0xff9e3025),
          fontSize: compact ? 12 : 13,
        ),
      ),
    );
  }
}
