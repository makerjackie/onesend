import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';

class DesktopCameraReceiver extends StatefulWidget {
  const DesktopCameraReceiver({
    required this.onFrame,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<Uint8List> onFrame;
  final bool enabled;

  @override
  State<DesktopCameraReceiver> createState() => _DesktopCameraReceiverState();
}

class _DesktopCameraReceiverState extends State<DesktopCameraReceiver> {
  CameraController? _controller;
  Timer? _timer;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant DesktopCameraReceiver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) return;
    if (widget.enabled) {
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError(
          'No camera was found. Connect a webcam and try again.',
        );
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      if (widget.enabled) _startTimer();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      unawaited(_captureAndDecode());
    });
  }

  Future<void> _captureAndDecode() async {
    final controller = _controller;
    if (!mounted ||
        controller == null ||
        _capturing ||
        !controller.value.isInitialized) {
      return;
    }
    _capturing = true;
    String? imagePath;
    try {
      final image = await controller.takePicture();
      imagePath = image.path;
      final result = await zx.readBarcodeImagePathString(
        image.path,
        DecodeParams(
          format: Format.qrCode,
          tryHarder: true,
          tryDownscale: true,
          maxSize: 1280,
        ),
      );
      if (result.isValid && result.rawBytes != null) {
        widget.onFrame(result.rawBytes!);
      }
    } catch (_) {
      // A missed desktop frame is expected; the fountain code absorbs it.
    } finally {
      _capturing = false;
      if (imagePath != null) {
        try {
          await File(imagePath).delete();
        } catch (_) {
          // Camera backends may manage their temporary files themselves.
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(controller);
  }
}
