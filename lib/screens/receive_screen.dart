import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app.dart';
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
    autoStart: true,
    detectionSpeed: DetectionSpeed.unrestricted,
    formats: <BarcodeFormat>[BarcodeFormat.qrCode],
    torchEnabled: false,
  );

  ReceiverSnapshot? _snapshot;
  TransferFile? _receivedFile;
  StoredTransfer? _storedFile;
  String? _error;
  bool _paused = false;
  _ReceiveSavePhase _savePhase = _ReceiveSavePhase.scanning;
  DateTime? _receiveStartedAt;
  Timer? _speedTicker;
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
    if (!_usesCimbar) unawaited(_enableWakelock());
    if (_algorithm == TransferAlgorithm.cimbar && _usesMobileScanner) {
      unawaited(_mobileController.stop());
    }
    _speedTicker = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted || _completed || _snapshot == null || _paused) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speedTicker?.cancel();
    unawaited(_disposeMobileController());
    unawaited(_disableWakelock());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused &&
        state != AppLifecycleState.detached &&
        state != AppLifecycleState.hidden) {
      return;
    }
    unawaited(_pauseForLifecycle());
  }

  Future<void> _pauseForLifecycle() async {
    if (_completed || _processing || _paused) return;
    _paused = true;
    if (_usesMobileScanner) {
      try {
        await _mobileController.stop();
      } catch (_) {}
    }
    await _disableWakelock();
    if (mounted) setState(() {});
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
    });
    if (_usesMobileScanner) {
      try {
        await _mobileController.start();
      } catch (_) {}
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
    if (_usesMobileScanner) {
      try {
        await _mobileController.stop();
      } catch (_) {}
    }
    setState(() {
      _algorithm = TransferAlgorithm.cimbar;
      _snapshot = null;
      _error = null;
      _receiveStartedAt = null;
      _paused = false;
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
      keyPrefix: 'receive-mode',
      onQrModeSelected: (mode) => unawaited(_selectQrMode(mode)),
      onCimbarSelected: () => unawaited(_selectCimbar()),
    );
  }

  void _onMobileDetectError(Object error, StackTrace stackTrace) {
    if (error is! MobileScannerException || !mounted) return;
    setState(() {
      _paused = true;
      _error = AppLocalizations.of(context)!.cimbarCameraError;
    });
    unawaited(_disableWakelock());
  }

  void _onMobileCapture(BarcodeCapture capture) {
    if (_completed || _paused || _processing) return;
    ReceiverEvent? latest;
    for (final barcode in capture.barcodes) {
      final bytes = _barcodeBytes(barcode);
      if (bytes == null) continue;
      latest = _receiver.consume(bytes) ?? latest;
      if (latest?.error != null || latest?.payload != null) break;
    }
    _handleReceiverEvent(latest);
  }

  Uint8List? _barcodeBytes(Barcode barcode) {
    final decoded = barcode.rawDecodedBytes;
    if (decoded is DecodedBarcodeBytes) return decoded.bytes;
    if (decoded is DecodedVisionBarcodeBytes) {
      return decoded.bytes ?? decoded.rawBytes;
    }
    return null;
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
        try {
          await _mobileController.stop();
        } catch (_) {
          // Camera cleanup must not prevent decoding an already verified file.
        }
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
      try {
        await _mobileController.stop();
      } catch (_) {
        // The scanner may already be stopped after a completed decode.
      }
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
    });
    try {
      await _enableWakelock();
    } catch (_) {
      // Camera progress remains usable if wakelock is unavailable.
    }
    if (_usesMobileScanner) {
      try {
        await _mobileController.start();
      } catch (error) {
        if (mounted) setState(() => _error = _friendlyReceiveError(error));
      }
    }
  }

  Future<void> _togglePause() async {
    if (_completed || _processing) return;
    try {
      if (_paused) {
        setState(() => _paused = false);
        await _enableWakelock();
        if (_usesMobileScanner) {
          await _mobileController.start();
        }
      } else {
        if (_usesMobileScanner) await _mobileController.stop();
        await _disableWakelock();
        if (mounted) setState(() => _paused = true);
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyReceiveError(error));
    }
  }

  Future<void> _reset() async {
    if (_usesMobileScanner) {
      try {
        await _mobileController.stop();
      } catch (_) {
        // A stopped controller is already in the state needed for reset.
      }
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
      _receiveStartedAt = null;
    });
    await _enableWakelock();
    if (_usesMobileScanner) {
      try {
        await _mobileController.start();
      } catch (error) {
        if (mounted) setState(() => _error = error.toString());
      }
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
      await _mobileController.dispose();
    } catch (_) {
      // Disposal is best effort during route teardown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_usesCimbar && !_completed) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.scanReceive)),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildModeChips(enabled: !_processing)],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CimbarTransferScreen(
                  key: const ValueKey<String>('receive-cimbar-panel'),
                  direction: CimbarDirection.receive,
                  store: widget.store,
                  embedded: true,
                  autoStartReceive: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scanReceive),
        actions: [
          if (_usesMobileScanner && !_usesCimbar)
            IconButton(
              tooltip: l10n.torch,
              onPressed: _completed || _processing ? null : _toggleTorch,
              icon: const Icon(Icons.flashlight_on_outlined),
            ),
        ],
      ),
      body: SafeArea(child: _completed ? _buildCompleted() : _buildScanner()),
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
        final cameraHeight = constraints.maxWidth >= 760
            ? 440.0
            : (constraints.maxWidth * 0.88).clamp(280.0, 520.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildModeChips(
                      enabled: !_processing && snapshot == null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: cameraHeight,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(status, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 5),
                  Text(
                    _usesMobileScanner
                        ? l10n.scanInstruction
                        : l10n.desktopCameraInstruction,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(
                            minHeight: 8,
                            value: progress,
                            backgroundColor: const Color(0xffe8ebe4),
                            color: oneSendInk,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.currentRate(formatTransferSpeed(currentRate)),
                            style: const TextStyle(
                              color: oneSendInk,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (snapshot?.mode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.theoreticalRate(
                                formatTransferSpeed(
                                  snapshot!.mode!.usefulBytesPerSecond,
                                ),
                              ),
                              style: const TextStyle(
                                color: oneSendMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  snapshot == null
                                      ? l10n.waitingFirstFrame
                                      : snapshot.usesRatelessFountain
                                      ? l10n.fountainProgress(
                                          snapshot.framesNew,
                                        )
                                      : l10n.blockProgress(
                                          snapshot.blockCount,
                                          snapshot.framesNew,
                                          snapshot.solvedBlocks,
                                        ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              if (snapshot != null)
                                Text(
                                  l10n.modeAndSize(
                                    _localizedReceiveModeLabel(
                                      l10n,
                                      snapshot.mode,
                                    ),
                                    formatBytes(snapshot.totalLength),
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ReceiveError(message: _error!),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (_paused || snapshot != null)
                        OutlinedButton.icon(
                          onPressed: _processing ? null : _togglePause,
                          icon: Icon(
                            _paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          label: Text(
                            _paused ? l10n.resumeScan : l10n.pauseScan,
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _processing ? null : _reset,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.restart),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: oneSendLime,
                      border: Border.all(color: oneSendInk, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.check_rounded, size: 42),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.receivedComplete,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stored == null ? l10n.verifiedNotSaved : l10n.verifiedSaved,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FileTile(
                    name: file.name,
                    bytes: file.bytes.length,
                    icon: Icons.south_west_rounded,
                  ),
                  if (_saving) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(minHeight: 4),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ReceiveError(message: _error!),
                  ],
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 12),
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
      ),
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
  const _ReceiveError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffffe5e1),
        border: Border.all(color: const Color(0xffa32820), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xff9e3025), fontSize: 13),
      ),
    );
  }
}
