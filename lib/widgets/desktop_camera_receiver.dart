import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_desktop/camera_desktop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;

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
  bool _processingFrame = false;
  bool _streaming = false;
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
      unawaited(_startStream());
    } else {
      unawaited(_stopStream());
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
        fps: 30,
      );
      await controller.initialize();
      if (!Platform.isWindows) {
        // Mirrored pixels look natural in a webcam preview, but mirrored QR
        // modules are not reliably decodable.
        await CameraDesktopPlugin().setMirror(controller.cameraId, false);
      }
      await zxing.zx.startCameraProcessing();
      if (!mounted) {
        await controller.dispose();
        zxing.zx.stopCameraProcessing();
        return;
      }
      setState(() => _controller = controller);
      if (widget.enabled) await _startStream();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _startStream() async {
    final controller = _controller;
    if (!mounted ||
        !widget.enabled ||
        _streaming ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    try {
      await controller.startImageStream(_onCameraImage);
      _streaming = true;
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _stopStream() async {
    final controller = _controller;
    if (controller == null || !_streaming) return;
    _streaming = false;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // The native camera may already have stopped while the window closes.
    }
    if (mounted && widget.enabled) await _startStream();
  }

  void _onCameraImage(CameraImage image) {
    if (!mounted || !widget.enabled || _processingFrame) return;
    _processingFrame = true;
    unawaited(_decodeFrame(image));
  }

  Future<void> _decodeFrame(CameraImage image) async {
    try {
      final result = await zxing.zx.processCameraImage(
        image,
        zxing.DecodeParams(
          imageFormat: image.format.group == ImageFormatGroup.bgra8888
              ? zxing.ImageFormat.bgrx
              : zxing.ImageFormat.lum,
          format: zxing.Format.qrCode,
          width: image.width,
          height: image.height,
          tryHarder: false,
          tryRotate: true,
          tryDownscale: true,
        ),
      );
      if (result.isValid && result.rawBytes != null) {
        widget.onFrame(result.rawBytes!);
      }
    } catch (_) {
      // A missed desktop frame is expected; the fountain code absorbs it.
    } finally {
      _processingFrame = false;
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    unawaited(() async {
      await _stopStream();
      await controller?.dispose();
      zxing.zx.stopCameraProcessing();
    }());
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
