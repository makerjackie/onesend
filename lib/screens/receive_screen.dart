import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app.dart';
import '../core/envelope.dart';
import '../core/optical_transfer.dart';
import '../services/file_service.dart';
import '../services/transfer_store.dart';
import '../widgets/desktop_camera_receiver.dart';
import '../widgets/file_tile.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({required this.store, super.key});

  final TransferStore store;

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
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
  bool _completed = false;
  bool _saving = false;

  bool get _usesMobileScanner =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  void dispose() {
    unawaited(_mobileController.dispose());
    super.dispose();
  }

  void _onMobileCapture(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final bytes = _barcodeBytes(barcode);
      if (bytes != null) {
        _consume(bytes);
        return;
      }
    }
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
    if (_completed || _paused) return;
    final event = _receiver.consume(bytes);
    if (event == null || !mounted) return;
    setState(() {
      _snapshot = event.snapshot;
      _error = null;
    });
    final file = event.file;
    if (file != null && event.verified && !_completed) {
      _completed = true;
      _receivedFile = file;
      unawaited(_finishTransfer(file));
    }
  }

  Future<void> _finishTransfer(TransferFile file) async {
    setState(() => _saving = true);
    if (_usesMobileScanner) unawaited(_mobileController.stop());
    try {
      final stored = await saveReceivedFile(file);
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
      if (mounted) {
        setState(() {
          _storedFile = stored;
          _saving = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _togglePause() async {
    if (_completed) return;
    if (_paused) {
      setState(() => _paused = false);
      if (_usesMobileScanner) {
        try {
          await _mobileController.start();
        } catch (error) {
          if (mounted) setState(() => _error = error.toString());
        }
      }
    } else {
      if (_usesMobileScanner) await _mobileController.stop();
      if (mounted) setState(() => _paused = true);
    }
  }

  Future<void> _reset() async {
    if (_usesMobileScanner) unawaited(_mobileController.stop());
    _receiver.reset();
    setState(() {
      _snapshot = null;
      _receivedFile = null;
      _storedFile = null;
      _error = null;
      _completed = false;
      _saving = false;
      _paused = false;
    });
    if (_usesMobileScanner) {
      try {
        await _mobileController.start();
      } catch (error) {
        if (mounted) setState(() => _error = error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描接收'),
        actions: [
          if (_usesMobileScanner)
            IconButton(
              tooltip: '手电筒',
              onPressed: _completed
                  ? null
                  : () => unawaited(_mobileController.toggleTorch()),
              icon: const Icon(Icons.flashlight_on_outlined),
            ),
        ],
      ),
      body: SafeArea(child: _completed ? _buildCompleted() : _buildScanner()),
    );
  }

  Widget _buildScanner() {
    final snapshot = _snapshot;
    final progress = snapshot?.progress;
    final status = _paused
        ? '已暂停，点击继续即可保留当前进度'
        : snapshot == null
        ? '正在寻找发送端…'
        : '已锁定光传会话 · 正在收集二维码';
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
                  SizedBox(
                    height: cameraHeight,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildCamera(),
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _ScannerOverlayPainter(paused: _paused),
                            ),
                          ),
                          if (_paused)
                            Container(
                              color: oneSendInk.withValues(alpha: 0.55),
                              alignment: Alignment.center,
                              child: const Text(
                                '已暂停',
                                style: TextStyle(
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
                        ? '把二维码完整放进框内，保持设备稳定。'
                        : '桌面端使用摄像头截图解码，速度会比手机慢一些。',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                            value: progress,
                            backgroundColor: const Color(0xffe8ebe4),
                            color: oneSendInk,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                snapshot == null
                                    ? '等待第一帧'
                                    : '${snapshot.framesNew} 帧 · ${snapshot.solvedBlocks}/${snapshot.blockCount} 块',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (snapshot != null)
                                Text(
                                  formatBytes(snapshot.totalLength),
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _togglePause,
                          icon: Icon(
                            _paused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          label: Text(_paused ? '继续扫描' : '暂停扫描'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('重新开始'),
                        ),
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
    if (_usesMobileScanner) {
      return MobileScanner(
        controller: _mobileController,
        fit: BoxFit.cover,
        onDetect: _onMobileCapture,
      );
    }
    return DesktopCameraReceiver(enabled: !_paused, onFrame: _consume);
  }

  Widget _buildCompleted() {
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
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(Icons.check_rounded, size: 42),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '接收完成',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('文件已校验通过，并保存到本机。', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FileTile(
                    name: file.name,
                    bytes: file.bytes.length,
                    icon: Icons.south_west_rounded,
                  ),
                  if (_saving) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ReceiveError(message: _error!),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: stored == null
                              ? null
                              : () => unawaited(shareStoredFile(stored)),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('分享文件'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('继续接收'),
                        ),
                      ),
                    ],
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xff9e3025), fontSize: 13),
      ),
    );
  }
}
