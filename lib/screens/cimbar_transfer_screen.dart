import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../app.dart';
import '../core/envelope.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/cimbar_bridge.dart';
import '../services/file_service.dart';
import '../services/transfer_store.dart';
import '../widgets/stored_file_actions.dart';

enum CimbarDirection { send, receive }

/// Peak experimental ceiling aligned with libcimbar / web envelope (33 MiB).
const int cimbarMobileMaxFileBytes = 33 * 1024 * 1024;

/// Whether a WebView media-capture permission should be granted for CIMBAR.
///
/// Exposed for unit tests. Receive must allow camera; send never needs it.
/// iOS may include microphone in the type set even when only video is used.
@visibleForTesting
bool shouldGrantCimbarWebViewMediaPermission({
  required bool isSending,
  required Set<WebViewPermissionResourceType> types,
}) {
  if (isSending) return false;
  // Prefer an explicit camera grant. If the platform reports an empty type
  // set (seen on some WebView builds), still allow — receive only ever asks
  // for capture while scanning color codes.
  if (types.isEmpty) return true;
  return types.contains(WebViewPermissionResourceType.camera);
}

enum _CimbarStatus {
  loading,
  pageReadySend,
  pageReadyReceive,
  engineReadySend,
  preparing,
  paused,
  playing,
  broadcasting,
  decoderReady,
  decoderReadyStart,
  cameraStarted,
  decoding,
  fileHeaderReceived,
  receiving,
  recoveredSaving,
  recoveredNotSaved,
  receiveComplete,
  loadFailed,
  transferFailed,
  reloading,
  requestingCamera,
}

/// libcimbar 0.6.7c experiment embedded in the shared send/receive flow.
///
/// When [embedded] is true the parent route owns the app bar / mode switcher
/// and this widget only renders the WebView + status panel.
class CimbarTransferScreen extends StatefulWidget {
  const CimbarTransferScreen({
    required this.direction,
    required this.store,
    this.embedded = false,
    this.autoStartReceive = true,
    super.key,
  });

  final CimbarDirection direction;
  final TransferStore store;

  /// Hide the standalone scaffold so send/receive can host this panel.
  final bool embedded;

  /// Start the camera as soon as the receive engine is ready (no extra tap).
  final bool autoStartReceive;

  @override
  State<CimbarTransferScreen> createState() => _CimbarTransferScreenState();
}

class _CimbarTransferScreenState extends State<CimbarTransferScreen>
    with WidgetsBindingObserver {
  final CimbarBridge _bridge = CimbarBridge();
  WebViewController? _controller;
  Stopwatch? _receiveStopwatch;
  Timer? _statusTimer;

  String? _error;
  _CimbarStatus _status = _CimbarStatus.loading;
  String? _fileName;
  int _fileSize = 0;
  int _sendBytesRead = 0;
  bool _pageReady = false;
  bool _engineReady = false;
  bool _autoStartInFlight = false;
  bool _sendPaused = false;
  bool _receiveStarted = false;
  bool _receivePaused = false;
  bool _saving = false;
  bool _sendHistoryWritten = false;
  double? _decodeProgress;
  int _receivedBytes = 0;
  int? _expectedBytes;
  TransferFile? _receivedFile;
  StoredTransfer? _storedFile;

  bool get _supportedPlatform => Platform.isAndroid || Platform.isIOS;
  bool get _isSending => widget.direction == CimbarDirection.send;
  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_enableWakelock());
    if (_supportedPlatform) {
      unawaited(_initializeWebView());
    }
  }

  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Convenience only; unavailable in some test hosts.
    }
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disableWakelock());
    // Do not call a state-updating async helper from dispose. The JavaScript
    // cleanup is deliberately fire-and-forget and does not touch Flutter
    // state, so camera tracks and workers are still stopped during teardown.
    _cancelReceiveResources();
    _bridge.reset();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(_cleanupWebView(controller, stopAll: true));
    }
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
    if (_isSending) {
      if (!_sendPaused &&
          (_status == _CimbarStatus.playing ||
              _status == _CimbarStatus.broadcasting)) {
        _toggleSendPause(true);
      }
    } else if (_receiveStarted && !_saving) {
      unawaited(_pauseReceive());
    }
  }

  Future<void> _initializeWebView() async {
    try {
      // Offline-only: load bundled assets (no local HTTP server / no INTERNET
      // permission). WebView camera remains experimental on some iOS builds.
      PlatformWebViewControllerCreationParams params =
          const PlatformWebViewControllerCreationParams();
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params =
            WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
              params,
              allowsInlineMediaPlayback: true,
              // Muted video may autoplay; audio must remain user-action-only.
              mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{
                PlaybackMediaTypes.audio,
              },
            );
      }

      final controller = WebViewController.fromPlatformCreationParams(
        params,
        onPermissionRequest: _handlePermissionRequest,
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(oneSendInk);
      await controller.addJavaScriptChannel(
        cimbarBridgeChannelName,
        onMessageReceived: _handleJavaScriptMessage,
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _pageReady = true;
              if (_error == null) {
                _status = _isSending
                    ? _CimbarStatus.pageReadySend
                    : widget.autoStartReceive
                    ? _CimbarStatus.requestingCamera
                    : _CimbarStatus.pageReadyReceive;
              }
            });
            if (!_isSending) {
              unawaited(_tryAutoStartReceive());
            }
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            debugPrint(
              '[OneSend CIMBAR] web resource error: ${error.errorCode} ${error.description}',
            );
            setState(() {
              _error = _l10n.cimbarPageLoadError;
              _status = _CimbarStatus.loadFailed;
            });
          },
        ),
      );

      if (controller.platform is AndroidWebViewController) {
        final androidController =
            controller.platform as AndroidWebViewController;
        await androidController.setMediaPlaybackRequiresUserGesture(false);
        if (_isSending) {
          await androidController.setOnShowFileSelector(_showAndroidFileSelector);
        }
      }

      if (!mounted) {
        unawaited(_cleanupWebView(controller, stopAll: true));
        return;
      }
      setState(() => _controller = controller);
      await controller.loadFlutterAsset(
        _isSending ? 'assets/cimbar/send.html' : 'assets/cimbar/receive.html',
      );
    } catch (error, stack) {
      debugPrint('[OneSend CIMBAR] webview init failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _error = _l10n.cimbarPageLoadError;
        _status = _CimbarStatus.loadFailed;
      });
    }
  }

  void _handlePermissionRequest(WebViewPermissionRequest request) {
    // Receive WebView only asks for capture while scanning. Grant anything it
    // requests (iOS may list camera, mic, or empty type sets).
    if (_isSending) {
      unawaited(request.deny());
      return;
    }
    debugPrint(
      '[OneSend CIMBAR] granting WebView media types: ${request.types}',
    );
    unawaited(request.grant());
  }

  Future<List<String>> _showAndroidFileSelector(
    FileSelectorParams params,
  ) async {
    if (params.mode != FileSelectorMode.open &&
        params.mode != FileSelectorMode.openMultiple) {
      return <String>[];
    }
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(label: _l10n.cimbarAllFiles, extensions: <String>[]),
      ],
    );
    if (file == null || file.path.trim().isEmpty) return <String>[];
    return <String>[file.path];
  }

  void _handleJavaScriptMessage(JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final event = _bridge.parse(message.message);
      _handleEvent(event);
    } on Object catch (_) {
      _handleBridgeFailure(_l10n.cimbarBridgeError);
    }
  }

  void _handleEvent(CimbarBridgeEvent event) {
    switch (event.type) {
      case 'send-ready':
        if (!_isSending) return;
        _setState(() => _status = _CimbarStatus.engineReadySend);
      case 'send-prepared':
        if (!_isSending) return;
        final size = event.integerValue('size') ?? -1;
        if (size < 0 || size > cimbarMobileMaxFileBytes) {
          _handleTransferTooLarge();
          return;
        }
        _setState(() {
          _fileName = event.stringValue('name') ?? _l10n.cimbarSelectedFileName;
          _fileSize = size;
          _sendBytesRead = 0;
          _status = _CimbarStatus.preparing;
          _error = null;
        });
      case 'send-progress':
        if (!_isSending) return;
        final bytesRead = event.integerValue('bytesRead') ?? _sendBytesRead;
        _setState(() {
          _sendBytesRead = bytesRead.clamp(0, _fileSize).toInt();
          _status = _CimbarStatus.preparing;
        });
      case 'send-paused':
        if (!_isSending) return;
        _setState(() {
          _sendPaused = event.booleanValue('paused') ?? _sendPaused;
          _status = _sendPaused ? _CimbarStatus.paused : _CimbarStatus.playing;
        });
      case 'send-complete':
        if (!_isSending) return;
        _setState(() {
          _status = _CimbarStatus.broadcasting;
          _sendBytesRead = _fileSize;
          _error = null;
        });
        unawaited(_recordSendHistory());
      case 'receive-ready':
        if (_isSending) return;
        _engineReady = true;
        _setState(() {
          if (_receiveStarted) {
            _status = _CimbarStatus.decoderReady;
          } else if (widget.autoStartReceive) {
            // Never tell the user to "tap start" when auto-start is on.
            _status = _CimbarStatus.requestingCamera;
          } else {
            _status = _CimbarStatus.decoderReadyStart;
          }
        });
        unawaited(_tryAutoStartReceive());
      case 'receive-camera-live':
        if (_isSending) return;
        _setState(() {
          _error = null;
          _status = _CimbarStatus.cameraStarted;
        });
      case 'receive-started':
        if (_isSending) return;
        _receiveStopwatch?.stop();
        _receiveStopwatch = Stopwatch()..start();
        _statusTimer?.cancel();
        _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          if (mounted && _receiveStarted) setState(() {});
        });
        _setState(() {
          _receiveStarted = true;
          _error = null;
          _decodeProgress = null;
          _status = _CimbarStatus.cameraStarted;
        });
      case 'decode-progress':
        if (_isSending) return;
        final values = event.progressValues();
        final progress = values == null || values.isEmpty
            ? null
            : values.reduce((a, b) => a + b) / values.length;
        _setState(() {
          _decodeProgress = progress?.clamp(0, 1).toDouble();
          _status = _CimbarStatus.decoding;
        });
      case 'receive-file-start':
        if (_isSending) return;
        final size = event.integerValue('size') ?? -1;
        if (size < 0 || size > cimbarMobileMaxFileBytes) {
          _handleTransferTooLarge();
          return;
        }
        _bridge.accept(_encodeEventAgain(event));
        _setState(() {
          _fileName = event.stringValue('name') ?? _l10n.cimbarReceivedFileName;
          _fileSize = size;
          _receivedBytes = 0;
          _expectedBytes = size;
          _status = _CimbarStatus.fileHeaderReceived;
        });
      case 'receive-file-chunk':
        if (_isSending) return;
        _bridge.accept(_encodeEventAgain(event));
        _setState(() {
          _receivedBytes = _bridge.assembler.receivedBytes;
          _expectedBytes = _bridge.assembler.expectedBytes;
          _status = _CimbarStatus.receiving;
        });
      case 'receive-file-complete':
        if (_isSending) return;
        final file = _bridge.accept(_encodeEventAgain(event));
        if (file == null) {
          _handleBridgeFailure(_l10n.cimbarVerificationError);
          return;
        }
        if (file.bytes.length > cimbarMobileMaxFileBytes) {
          _handleTransferTooLarge();
          return;
        }
        _receiveStopwatch?.stop();
        _statusTimer?.cancel();
        _setState(() {
          _receivedFile = file;
          _receivedBytes = file.bytes.length;
          _expectedBytes = file.bytes.length;
          _fileName = file.name;
          _fileSize = file.bytes.length;
          _receiveStarted = false;
          _status = _CimbarStatus.recoveredSaving;
          _error = null;
        });
        unawaited(_completeReceive(file));
      case 'receive-complete':
        if (_isSending) return;
        unawaited(_stopReceiveResources());
        if (_storedFile == null && !_saving) {
          _setState(() => _status = _CimbarStatus.recoveredSaving);
        }
      case 'error':
        final phase = event.stringValue('phase');
        final detail = event.stringValue('message') ?? 'unknown error';
        debugPrint('[OneSend CIMBAR] ${phase ?? 'engine'}: $detail');
        final userMessage = _localizedBridgeError(phase);
        _handleBridgeFailure(userMessage);
    }
  }

  // CimbarBridgeEvent intentionally exposes immutable fields. Re-encoding
  // here keeps the assembler's single public entry point strict and testable.
  String _encodeEventAgain(CimbarBridgeEvent event) => jsonEncode(event.fields);

  String _localizedBridgeError(String? phase) {
    return switch (phase) {
      'camera' => _l10n.cimbarCameraError,
      'send' || 'send-init' || 'send-pause' => _l10n.cimbarSendError,
      'receive' || 'decode' => _l10n.cimbarReceiveError,
      _ => _l10n.cimbarEngineError,
    };
  }

  void _handleTransferTooLarge() {
    _bridge.reset();
    unawaited(_releaseResources(clearProgress: true));
    _setState(() {
      _error = _l10n.cimbarFileTooLarge(_maxSizeLabel(_l10n));
      _status = _CimbarStatus.transferFailed;
      _receiveStarted = false;
      _receivePaused = false;
      _saving = false;
      _receivedBytes = 0;
      _expectedBytes = null;
      _fileName = null;
      _fileSize = 0;
      _sendBytesRead = 0;
    });
  }

  void _handleBridgeFailure(String message) {
    _bridge.reset();
    unawaited(_releaseResources(clearProgress: true));
    _setState(() {
      _error = message;
      _status = _CimbarStatus.transferFailed;
      _receiveStarted = false;
      _receivePaused = false;
      _saving = false;
      _receivedBytes = 0;
      _expectedBytes = null;
    });
  }

  void _cancelReceiveResources() {
    _receiveStopwatch?.stop();
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<void> _cleanupWebView(
    WebViewController controller, {
    required bool stopAll,
  }) async {
    try {
      await controller.runJavaScript(
        stopAll ? 'OneSendCimbar.stop();' : 'OneSendCimbar.stopReceive();',
      );
    } catch (_) {
      // The WebView can already be tearing down. Native state is cleaned up
      // synchronously before this call, and JavaScript cleanup is best effort.
    }
  }

  Future<void> _releaseResources({bool clearProgress = false}) async {
    _cancelReceiveResources();
    if (clearProgress) _receiveStopwatch = null;
    final controller = _controller;
    if (controller == null) return;
    await _cleanupWebView(controller, stopAll: true);
  }

  Future<void> _stopReceiveResources({bool clearProgress = false}) async {
    if (_isSending) return;
    _cancelReceiveResources();
    if (clearProgress) _receiveStopwatch = null;
    _setState(() {
      _receiveStarted = false;
      if (clearProgress) {
        _receivedBytes = 0;
        _expectedBytes = null;
        _decodeProgress = null;
      }
    });

    final controller = _controller;
    if (controller == null) return;
    await _cleanupWebView(controller, stopAll: false);
  }

  Future<void> _completeReceive(TransferFile file) async {
    await _stopReceiveResources();
    if (!mounted) return;
    await _saveReceivedFile(file);
  }

  Future<void> _saveReceivedFile(TransferFile file) async {
    if (_saving || _storedFile != null) return;
    _setState(() {
      _saving = true;
      _status = _CimbarStatus.recoveredSaving;
    });
    try {
      final stored = await saveReceivedFile(file);
      if (!mounted) return;
      _setState(() {
        _storedFile = stored;
        _saving = false;
        _status = _CimbarStatus.receiveComplete;
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
            status: 'cimbar-received',
            path: stored.path,
            verified: true,
          ),
        );
      } on Object catch (_) {
        if (mounted) _setState(() => _error = _l10n.cimbarHistoryError);
      }
    } on Object catch (_) {
      unawaited(_releaseResources());
      if (!mounted) return;
      _setState(() {
        _saving = false;
        _error = _l10n.cimbarSaveError;
        _status = _CimbarStatus.recoveredNotSaved;
      });
    }
  }

  Future<void> _recordSendHistory() async {
    if (_sendHistoryWritten || _fileName == null) return;
    _sendHistoryWritten = true;
    try {
      await widget.store.add(
        TransferRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          direction: TransferDirection.sent,
          fileName: safeStorageFileName(_fileName!),
          bytes: _fileSize,
          createdAt: DateTime.now(),
          status: 'cimbar-broadcasting',
        ),
      );
    } on Object catch (_) {
      if (mounted) _setState(() => _error = _l10n.cimbarHistoryError);
    }
  }

  /// Auto-start must wait for both page load and WASM ready. Previously
  /// `receive-ready` could fire before `_pageReady`, `_startReceive` no-op'd,
  /// the start button was hidden, and the UI stuck on "点击开始…".
  Future<void> _tryAutoStartReceive() async {
    if (!widget.autoStartReceive || _isSending || _saving) return;
    if (_receiveStarted || _autoStartInFlight) return;
    if (!_pageReady || !_engineReady || _controller == null) return;

    _autoStartInFlight = true;
    try {
      await _startReceive();
    } finally {
      _autoStartInFlight = false;
    }
  }

  Future<void> _startReceive() async {
    if (_controller == null || _isSending) return;
    if (!_pageReady) {
      debugPrint('[OneSend CIMBAR] startReceive skipped: page not ready');
      return;
    }
    // Only stop an already-running receive. Calling stopReceive on a cold
    // engine clears wasm worker state and leaves a black camera session.
    if (_receiveStarted || _receivePaused) {
      await _stopReceiveResources();
    }
    _setState(() {
      _receiveStarted = true;
      _receivePaused = false;
      _status = _CimbarStatus.requestingCamera;
      _error = null;
    });
    try {
      await _runWebViewScript('OneSendCimbar.startReceive();');
    } on Object catch (error) {
      debugPrint('[OneSend CIMBAR] startReceive script failed: $error');
      if (!mounted) return;
      _setState(() {
        _receiveStarted = false;
        _error = _l10n.cimbarCameraError;
        _status = _CimbarStatus.transferFailed;
      });
    }
  }

  Future<void> _pauseReceive() async {
    if (_isSending || !_receiveStarted || _saving) return;
    await _stopReceiveResources();
    _setState(() {
      _receiveStarted = false;
      _receivePaused = true;
      _status = _CimbarStatus.decoderReady;
    });
  }

  void _chooseSendFile() {
    if (!_pageReady || _controller == null || !_isSending) return;
    unawaited(_runWebViewScript('OneSendCimbar.chooseFile();'));
  }

  void _toggleSendPause(bool paused) {
    if (!_pageReady || _controller == null || !_isSending) return;
    _setState(() => _sendPaused = paused);
    unawaited(
      _runWebViewScript(
        'OneSendCimbar.togglePause(${paused ? 'true' : 'false'});',
      ),
    );
  }

  Future<void> _runWebViewScript(String script) async {
    final controller = _controller;
    if (controller == null) {
      throw StateError('CIMBAR WebView is not ready');
    }
    await controller.runJavaScript(script);
  }

  Future<void> _retry() async {
    await _releaseResources(clearProgress: true);
    if (_saving) return;
    final file = _receivedFile;
    if (!_isSending && file != null && _storedFile == null) {
      await _saveReceivedFile(file);
      return;
    }
    _bridge.reset();
    final controller = _controller;
    if (controller == null) {
      _setState(() {
        _error = null;
        _status = _CimbarStatus.reloading;
      });
      unawaited(_initializeWebView());
      return;
    }
    _setState(() {
      _error = null;
      _fileName = null;
      _fileSize = 0;
      _sendBytesRead = 0;
      _receivedBytes = 0;
      _expectedBytes = null;
      _receivedFile = null;
      _storedFile = null;
      _receiveStarted = false;
      _receivePaused = false;
      _sendPaused = false;
      _pageReady = false;
      _engineReady = false;
      _autoStartInFlight = false;
      _status = _CimbarStatus.reloading;
    });
    await controller.reload();
  }

  void _setState(VoidCallback callback) {
    if (mounted) setState(callback);
  }

  String _maxSizeLabel(AppLocalizations l10n) => l10n.cimbarMebibytes('16');

  String _statusText(AppLocalizations l10n) {
    return switch (_status) {
      _CimbarStatus.loading => l10n.cimbarLoading,
      _CimbarStatus.pageReadySend => l10n.cimbarPageReadySend,
      _CimbarStatus.pageReadyReceive => l10n.cimbarPageReadyReceive,
      _CimbarStatus.engineReadySend => l10n.cimbarEngineReady,
      _CimbarStatus.preparing => l10n.cimbarPreparingFile,
      _CimbarStatus.paused => l10n.cimbarPaused,
      _CimbarStatus.playing => l10n.cimbarPlaying,
      _CimbarStatus.broadcasting => l10n.cimbarBroadcasting,
      _CimbarStatus.decoderReady => l10n.cimbarDecoderReady,
      _CimbarStatus.decoderReadyStart => l10n.cimbarDecoderReadyStart,
      _CimbarStatus.cameraStarted => l10n.cimbarCameraStarted,
      _CimbarStatus.decoding => l10n.cimbarDecoding,
      _CimbarStatus.fileHeaderReceived => l10n.cimbarFileHeaderReceived,
      _CimbarStatus.receiving => l10n.cimbarReceiving,
      _CimbarStatus.recoveredSaving => l10n.cimbarRecoveredSaving,
      _CimbarStatus.recoveredNotSaved => l10n.cimbarRecoveredNotSaved,
      _CimbarStatus.receiveComplete => l10n.cimbarReceiveComplete,
      _CimbarStatus.loadFailed => l10n.cimbarLoadFailed,
      _CimbarStatus.transferFailed => l10n.cimbarTransferFailed,
      _CimbarStatus.reloading => l10n.cimbarReloading,
      _CimbarStatus.requestingCamera => l10n.cimbarRequestingCamera,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final body = !_supportedPlatform
        ? _buildUnsupported(l10n)
        : Column(
            children: [
              Expanded(child: _buildWebView()),
              _buildStatusPanel(l10n),
            ],
          );
    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSending ? l10n.cimbarSendTitle : l10n.cimbarReceiveTitle,
        ),
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _buildUnsupported(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.cimbarUnsupported,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ColoredBox(
      color: oneSendInk,
      child: WebViewWidget(controller: controller),
    );
  }

  Widget _buildStatusPanel(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final elapsed = _receiveStopwatch?.elapsed ?? Duration.zero;
    final measuredSpeed = elapsed.inMilliseconds <= 0
        ? 0.0
        : _receivedBytes / 1000 / (elapsed.inMilliseconds / 1000);
    final progress = _expectedBytes == null || _expectedBytes == 0
        ? null
        : (_receivedBytes / _expectedBytes!).clamp(0, 1).toDouble();

    // Compact fixed footer — never scroll; stage above takes remaining height.
    return Material(
      color: oneSendPaper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _statusText(l10n),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (_fileName != null) ...[
              const SizedBox(height: 2),
              Text(
                l10n.cimbarFileInfo(
                  _fileName!,
                  _formatBytes(l10n, _fileSize),
                ),
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (_isSending && _fileSize > 0) ...[
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _fileSize == 0 ? null : _sendBytesRead / _fileSize,
                minHeight: 4,
              ),
            ],
            if (!_isSending) ...[
              const SizedBox(height: 6),
              if (progress != null) LinearProgressIndicator(value: progress),
              if (_decodeProgress != null && progress == null)
                LinearProgressIndicator(value: _decodeProgress),
              const SizedBox(height: 4),
              Text(
                '${l10n.currentRate(formatTransferSpeed(measuredSpeed * 1000))}'
                '${_expectedBytes == null ? '' : ' · ${((progress ?? 0) * 100).round()}%'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (!_isSending && _storedFile != null) ...[
              const SizedBox(height: 6),
              StoredFileActions(file: _storedFile!),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                  if (_isSending) ...[
                    OutlinedButton.icon(
                      onPressed: _pageReady ? _chooseSendFile : null,
                      icon: const Icon(Icons.attach_file_rounded),
                      label: Text(l10n.chooseFile),
                    ),
                    if (_error == null &&
                        (_status == _CimbarStatus.playing ||
                            _status == _CimbarStatus.broadcasting ||
                            _status == _CimbarStatus.paused))
                      OutlinedButton.icon(
                        onPressed: _pageReady
                            ? () => _toggleSendPause(!_sendPaused)
                            : null,
                        icon: Icon(
                          _sendPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                        label: Text(_sendPaused ? l10n.resume : l10n.pause),
                      ),
                  ] else ...[
                    // One primary control only (same idea as QR receive):
                    // 暂停 ↔ 继续 / 失败时一个重试，不要并列两个按钮。
                    if (_storedFile == null && !_saving)
                      if (_error != null)
                        FilledButton.icon(
                          onPressed: _saving ? null : _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(
                            _receivedFile != null
                                ? l10n.retrySave
                                : l10n.restart,
                          ),
                        )
                      else if (_receiveStarted)
                        FilledButton.icon(
                          onPressed: _pageReady ? _pauseReceive : null,
                          icon: const Icon(Icons.pause_rounded),
                          label: Text(l10n.pauseScan),
                        )
                      else if (_receivePaused || !widget.autoStartReceive)
                        FilledButton.icon(
                          onPressed: _pageReady ? _startReceive : null,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            _receivePaused
                                ? l10n.resumeScan
                                : l10n.cimbarStartReceive,
                          ),
                        ),
                  ],
                  if (_isSending && _error != null)
                    OutlinedButton(
                      onPressed: _saving ? null : _retry,
                      child: Text(l10n.restart),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(AppLocalizations l10n, int bytes) {
  if (bytes < 1024) return l10n.cimbarBytes(bytes.toString());
  if (bytes < 1024 * 1024) {
    return l10n.cimbarKibibytes((bytes / 1024).toStringAsFixed(1));
  }
  return l10n.cimbarMebibytes((bytes / (1024 * 1024)).toStringAsFixed(2));
}
