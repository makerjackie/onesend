import 'dart:async';
import 'dart:math' as math;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app.dart';
import '../core/frame_pacer.dart';
import '../core/optical_transfer.dart';
import '../core/transfer_codec.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/file_service.dart';
import '../services/sample_file_service.dart';
import '../services/transfer_store.dart';
import '../widgets/file_tile.dart';
import '../widgets/optical_qr.dart';
import '../widgets/transfer_mode_selector.dart';
import 'cimbar_transfer_screen.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({required this.store, this.settings, super.key});

  final TransferStore store;
  final AppSettings? settings;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  _SendingFile? _file;
  OpticalSender? _sender;
  late final Ticker _playbackTicker;
  FramePacer? _framePacer;
  Uint8List? _frame;
  int _framesSent = 0;
  DateTime? _startedAt;
  String? _error;
  bool _preparing = false;
  bool _dragging = false;
  late TransferMode _mode;
  late TransferAlgorithm _algorithm;

  bool get _supportsDesktopDrop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  bool get _usesCimbar => _algorithm == TransferAlgorithm.cimbar;

  @override
  void initState() {
    super.initState();
    _mode = widget.settings?.defaultMode ?? AppSettings.defaultTransferMode;
    _algorithm =
        widget.settings?.transferAlgorithm ??
        AppSettings.defaultTransferAlgorithm;
    _playbackTicker = createTicker(_onPlaybackTick);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playbackTicker.dispose();
    _sender?.dispose();
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
    final sender = _sender;
    if (sender == null || sender.isPaused) return;
    _playbackTicker.stop();
    sender.pause();
    unawaited(_disableWakelock());
    if (mounted) setState(() {});
  }

  Future<void> _pickFile() async {
    if (_preparing) return;
    await _preparePickedFile(pickTransferFile);
  }

  Future<void> _sendSampleVideo() async {
    if (_preparing) return;
    await _preparePickedFile(loadSampleVideo);
  }

  Future<void> _handleDroppedFiles(DropDoneDetails details) async {
    if (_preparing || _file != null) return;
    setState(() => _dragging = false);
    final paths = details.files
        .map((file) => file.path)
        .where((path) => path.isNotEmpty)
        .toList(growable: false);
    if (paths.isEmpty) return;
    await _preparePickedFile(() => loadTransferFileFromPath(paths.first));
  }

  Future<void> _selectMode(TransferMode mode) async {
    if (_preparing || _file != null) return;
    if (_algorithm == TransferAlgorithm.qr && _mode == mode) return;
    setState(() {
      _algorithm = TransferAlgorithm.qr;
      _mode = mode;
    });
    final settings = widget.settings;
    if (settings == null) return;
    try {
      if (settings.transferAlgorithm != TransferAlgorithm.qr) {
        await settings.setDefaultAlgorithm(TransferAlgorithm.qr);
      }
      if (settings.defaultMode != mode) {
        await settings.setDefaultMode(mode);
      }
    } catch (_) {
      // Mode still applies to this send even if persistence fails.
    }
  }

  Future<void> _selectCimbar() async {
    if (_preparing || _file != null) return;
    if (_algorithm == TransferAlgorithm.cimbar) return;
    setState(() => _algorithm = TransferAlgorithm.cimbar);
    final settings = widget.settings;
    if (settings == null) return;
    try {
      if (settings.transferAlgorithm != TransferAlgorithm.cimbar) {
        await settings.setDefaultAlgorithm(TransferAlgorithm.cimbar);
      }
    } catch (_) {
      // Preference persistence is best effort.
    }
  }

  Widget _buildModeChips({required bool enabled}) {
    return TransferModeSelector(
      algorithm: _algorithm,
      mode: _mode,
      enabled: enabled,
      keyPrefix: 'send-mode',
      onQrModeSelected: (mode) => unawaited(_selectMode(mode)),
      onCimbarSelected: () => unawaited(_selectCimbar()),
    );
  }

  Future<void> _preparePickedFile(
    Future<PickedTransfer?> Function() loader,
  ) async {
    setState(() {
      _preparing = true;
      _error = null;
    });
    try {
      final file = await loader();
      if (file == null || !mounted) return;
      await _prepareAndStart(file);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  /// The picker and bundled sample both enter this single preparation path.
  /// Only plain strings and [Uint8List] are passed to the top-level isolate
  /// callback, so plugin objects and widget state cannot become unsendable.
  Future<void> _prepareAndStart(PickedTransfer file) async {
    final payload = await encodeTransferFileInBackground(
      name: file.name,
      mimeType: file.mimeType,
      bytes: file.bytes,
    );
    if (!mounted) return;
    if (payload.length > maxOpticalPayloadBytes) {
      throw StateError('文件编码后超过光传协议上限。');
    }

    _stopPlayback();
    final selected = _SendingFile(
      name: file.name,
      mimeType: file.mimeType,
      bytes: file.bytes.length,
    );
    setState(() {
      _file = selected;
      _frame = null;
      _framesSent = 0;
      _startedAt = DateTime.now();
    });
    _startSender(payload, selected);
  }

  void _stopPlayback() {
    _playbackTicker.stop();
    _sender?.dispose();
    _sender = null;
    _framePacer = null;
    unawaited(_disableWakelock());
  }

  void _startSender(Uint8List payload, _SendingFile file) {
    late final OpticalSender sender;
    sender = OpticalSender(
      payload: payload,
      fileName: file.name,
      mimeType: file.mimeType,
      mode: _mode,
      useInternalClock: false,
      onFrame: (frame, _) {
        if (!mounted) return;
        setState(() {
          _frame = frame;
          _framesSent = sender.framesEmitted;
        });
      },
      onError: (error) {
        if (!mounted) return;
        _playbackTicker.stop();
        setState(() => _error = _friendlyError(error));
      },
    );
    _sender = sender;
    _framePacer = FramePacer(sender.frameInterval);
    sender.start();
    _playbackTicker.start();
    unawaited(_enableWakelock());
  }

  void _onPlaybackTick(Duration elapsed) {
    final sender = _sender;
    final pacer = _framePacer;
    if (sender == null || pacer == null || sender.isPaused) return;
    if (pacer.shouldEmit(elapsed)) sender.emitNext();
  }

  Future<void> _togglePause() async {
    final sender = _sender;
    if (sender == null) return;
    try {
      if (sender.isPaused) {
        _framePacer?.reset();
        sender.resume();
        _playbackTicker.start();
        await _enableWakelock();
      } else {
        _playbackTicker.stop();
        sender.pause();
        await _disableWakelock();
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    }
  }

  Future<void> _endTransfer() async {
    final file = _file;
    _stopPlayback();
    try {
      await _disableWakelock();
      if (file != null && _framesSent > 0) {
        await widget.store.add(
          TransferRecord(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            direction: TransferDirection.sent,
            fileName: file.name,
            bytes: file.bytes,
            createdAt: DateTime.now(),
            status: 'broadcast-ended',
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_usesCimbar) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sendFile)),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildModeChips(enabled: true)],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CimbarTransferScreen(
                  key: const ValueKey<String>('send-cimbar-panel'),
                  direction: CimbarDirection.send,
                  store: widget.store,
                  embedded: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendFile),
        actions: [
          IconButton(
            tooltip: l10n.chooseOtherFile,
            onPressed: _preparing || _file != null ? null : _pickFile,
            icon: const Icon(Icons.attach_file_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _file == null ? _buildPicker() : _buildActiveTransfer(),
      ),
    );
  }

  Widget _buildPicker() {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final workbench = constraints.maxWidth >= oneSendWorkbenchBreakpoint;
        final panel = AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: workbench
                ? math.max(420.0, constraints.maxHeight - 32)
                : 0,
          ),
          decoration: BoxDecoration(
            color: _dragging
                ? oneSendLime.withValues(alpha: 0.28)
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(oneSendRadiusCard),
            border: Border.all(
              color: _dragging ? oneSendInk : scheme.outlineVariant,
              width: _dragging ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: workbench ? 36 : 24,
              vertical: workbench ? 32 : 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: workbench ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Container(
                  width: workbench ? 84 : 72,
                  height: workbench ? 84 : 72,
                  decoration: BoxDecoration(
                    color: oneSendLime,
                    border: Border.all(color: oneSendInk, width: 2),
                    borderRadius: BorderRadius.circular(oneSendRadiusBadge),
                  ),
                  child: Icon(
                    _dragging
                        ? Icons.file_download_rounded
                        : Icons.upload_file_rounded,
                    size: workbench ? 38 : 34,
                  ),
                ),
                SizedBox(height: workbench ? 22 : 18),
                Text(
                  l10n.chooseAFile,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    l10n.sendFileDescription(formatBytes(maxTransferBytes)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                _buildModeChips(enabled: !_preparing),
                if (_supportsDesktopDrop) ...[
                  const SizedBox(height: 14),
                  Text(
                    _dragging ? l10n.dropFilesActive : l10n.dropFilesHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: oneSendMuted),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _ErrorText(message: _error!),
                  ),
                ],
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: workbench ? 360 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey<String>('send-pick-file'),
                          onPressed: _preparing ? null : _pickFile,
                          icon: _preparing
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.folder_open_rounded),
                          label: Text(
                            _preparing ? l10n.reading : l10n.chooseFile,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey<String>('send-sample-video'),
                          onPressed: _preparing ? null : _sendSampleVideo,
                          icon: const Icon(Icons.movie_outlined),
                          label: Text(l10n.sampleVideo),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        if (workbench) {
          return Padding(padding: const EdgeInsets.all(16), child: panel);
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: panel,
            ),
          ),
        );
      },
    );

    if (!_supportsDesktopDrop) return body;

    return DropTarget(
      enable: !_preparing && _file == null,
      onDragEntered: (_) {
        if (mounted) setState(() => _dragging = true);
      },
      onDragExited: (_) {
        if (mounted) setState(() => _dragging = false);
      },
      onDragDone: (details) => unawaited(_handleDroppedFiles(details)),
      child: body,
    );
  }

  Widget _buildActiveTransfer() {
    final l10n = AppLocalizations.of(context)!;
    final file = _file!;
    final sender = _sender;
    final progress = sender?.passProgress ?? 0;
    final pass = sender?.passNumber ?? 1;
    final elapsed = _startedAt == null
        ? '—'
        : _formatDuration(DateTime.now().difference(_startedAt!));
    final currentRate = _currentBytesPerSecond();
    final scheme = Theme.of(context).colorScheme;

    Widget qrStage(double qrSize) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: qrSize,
                child: _frame == null
                    ? const Center(child: CircularProgressIndicator())
                    : OpticalQr(
                        bytes: _frame!,
                        size: qrSize,
                        robust: _mode == TransferMode.reliable,
                      ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: oneSendLime,
                  border: Border.all(color: oneSendInk, width: 2),
                  borderRadius: BorderRadius.circular(oneSendRadiusBadge),
                ),
                child: Text(
                  l10n.modeBadge(_localizedModeLabel(l10n, _mode)),
                  style: const TextStyle(
                    color: oneSendInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                sender?.isPaused == true
                    ? l10n.pausedPlayback
                    : l10n.broadcasting,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                l10n.cameraAim,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    Widget controlPanel({required bool dense}) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(dense ? 16 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FileTile(
                name: file.name,
                bytes: file.bytes,
                icon: Icons.north_east_rounded,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: scheme.outlineVariant,
                color: scheme.primary,
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 4,
                spacing: 18,
                children: [
                  Text(
                    l10n.passAndFrames(_framesSent, pass),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    l10n.runningTime(elapsed),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.currentRate(formatTransferSpeed(currentRate)),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: dense ? 16 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.theoreticalRate(
                  formatTransferSpeed(_mode.usefulBytesPerSecond),
                ),
                style: const TextStyle(
                  color: oneSendMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorText(message: _error!),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (sender != null && _error == null)
                    OutlinedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(
                        sender.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                      label: Text(sender.isPaused ? l10n.resume : l10n.pause),
                    ),
                  FilledButton.icon(
                    onPressed: _endTransfer,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(l10n.endTransfer),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _preparing ? null : _pickFile,
                  child: Text(l10n.sendAnother),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final workbench = constraints.maxWidth >= oneSendWorkbenchBreakpoint;
        if (workbench) {
          final qrSize = math.min(
            400.0,
            math.max(260.0, constraints.maxHeight - 120),
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(child: controlPanel(dense: true)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: qrStage(qrSize),
                  ),
                ),
              ],
            ),
          );
        }

        final qrSize = math.min(
          500.0,
          math.max(220.0, constraints.maxWidth - 40),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  qrStage(qrSize),
                  const SizedBox(height: 14),
                  controlPanel(dense: false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _currentBytesPerSecond() {
    final sender = _sender;
    final startedAt = _startedAt;
    if (sender == null || startedAt == null) return 0;
    final elapsed = DateTime.now().difference(startedAt).inMicroseconds;
    if (elapsed <= 0) return 0;
    final seconds = elapsed / Duration.microsecondsPerSecond;
    return sender.framesEmitted *
        (_mode.usefulBytesPerSecond / _mode.framesPerSecond) /
        seconds;
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Wakelock is a convenience and is unavailable in widget tests and
      // some desktop environments.
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // A failed cleanup must not interrupt the transfer flow.
    }
  }

  String _friendlyError(Object error) {
    return localizedTransferError(context, error);
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${(duration.inMinutes % 60).toString().padLeft(2, '0')}m';
    }
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

String _localizedModeLabel(AppLocalizations l10n, TransferMode mode) {
  return switch (mode) {
    TransferMode.reliable => l10n.modeReliable,
    TransferMode.fast => l10n.modeFast,
    TransferMode.turbo => l10n.modeTurboQr,
  };
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

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

class _SendingFile {
  const _SendingFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final int bytes;
}
