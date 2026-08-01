import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app.dart';
import '../core/envelope.dart';
import '../core/optical_transfer.dart';
import '../services/file_service.dart';
import '../services/transfer_store.dart';
import '../widgets/file_tile.dart';
import '../widgets/optical_qr.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({required this.store, super.key});

  final TransferStore store;

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  PickedTransfer? _file;
  OpticalSender? _sender;
  Uint8List? _frame;
  int _framesSent = 0;
  DateTime? _startedAt;
  String? _error;
  bool _picking = false;

  @override
  void dispose() {
    _sender?.dispose();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await pickTransferFile();
      if (file == null || !mounted) return;
      _sender?.dispose();
      _sender = null;
      final payload = encodeTransferFile(
        TransferFile(
          name: file.name,
          mimeType: file.mimeType,
          bytes: file.bytes,
        ),
      );
      if (payload.length > maxTransferBytes) {
        throw StateError('文件元数据过长，无法开始传输。');
      }
      setState(() {
        _file = file;
        _frame = null;
        _framesSent = 0;
        _startedAt = DateTime.now();
      });
      _startSender(payload, file);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _startSender(Uint8List payload, PickedTransfer file) {
    final sender = OpticalSender(
      payload: payload,
      fileName: file.name,
      mimeType: file.mimeType,
      onFrame: (frame, _) {
        if (!mounted) return;
        setState(() {
          _frame = frame;
          _framesSent = _sender?.framesEmitted ?? (_framesSent + 1);
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _error = _friendlyError(error));
      },
    );
    _sender = sender;
    sender.start();
    unawaited(WakelockPlus.enable());
  }

  Future<void> _togglePause() async {
    final sender = _sender;
    if (sender == null) return;
    if (sender.isPaused) {
      sender.resume();
      await WakelockPlus.enable();
    } else {
      sender.pause();
      await WakelockPlus.disable();
    }
    if (mounted) setState(() {});
  }

  Future<void> _endTransfer() async {
    final file = _file;
    final sender = _sender;
    sender?.stop();
    await WakelockPlus.disable();
    if (file != null && _framesSent > 0) {
      await widget.store.add(
        TransferRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          direction: TransferDirection.sent,
          fileName: file.name,
          bytes: file.bytes.length,
          createdAt: DateTime.now(),
          status: 'sent',
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发送文件'),
        actions: [
          IconButton(
            tooltip: '选择其他文件',
            onPressed: _picking ? null : _pickFile,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: oneSendLime,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(Icons.upload_file_rounded, size: 36),
                  ),
                  const SizedBox(height: 22),
                  Text('选一个文件', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    '文件会被编码成一串不断变化的二维码。\n最大支持 64 MB，建议从小文件开始体验。',
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _ErrorText(message: _error!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _picking ? null : _pickFile,
                    icon: _picking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open_rounded),
                    label: Text(_picking ? '读取中…' : '选择文件'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTransfer() {
    final file = _file!;
    final sender = _sender;
    final blockCount = sender?.blockCount ?? 1;
    final progress = math.min(
      0.99,
      _framesSent / math.max(1, blockCount * expectedFrameOverhead),
    );
    final elapsed = _startedAt == null
        ? '—'
        : _formatDuration(DateTime.now().difference(_startedAt!));
    return LayoutBuilder(
      builder: (context, constraints) {
        final qrSize = math.min(
          500.0,
          math.max(250.0, constraints.maxWidth - 48),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          SizedBox.square(
                            dimension: qrSize,
                            child: _frame == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : OpticalQr(bytes: _frame!, size: qrSize),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            sender?.isPaused == true ? '已暂停播放' : '正在持续播放二维码',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '请把另一台设备的摄像头对准这块白色区域',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          FileTile(
                            name: file.name,
                            bytes: file.bytes.length,
                            icon: Icons.north_east_rounded,
                          ),
                          const SizedBox(height: 22),
                          LinearProgressIndicator(
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                            value: progress,
                            backgroundColor: const Color(0xffe8ebe4),
                            color: oneSendInk,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '已发 $_framesSent 帧',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '运行 $elapsed',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) _ErrorText(message: _error!),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _togglePause,
                          icon: Icon(
                            sender?.isPaused == true
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                          label: Text(sender?.isPaused == true ? '继续' : '暂停'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _endTransfer,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('结束传输'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _picking ? null : _pickFile,
                    child: const Text('换一个文件'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    return message;
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${(duration.inMinutes % 60).toString().padLeft(2, '0')}m';
    }
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xff9e3025), fontSize: 13),
      ),
    );
  }
}
