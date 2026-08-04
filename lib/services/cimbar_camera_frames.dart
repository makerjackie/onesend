import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Max long-edge for frames fed into the CIMBAR WASM workers via the JS bridge.
///
/// Full camera frames as base64 through `runJavaScript` will freeze or kill
/// WKWebView. ~480px keeps the color grid readable without flooding the bridge.
const int cimbarNativeFrameMaxEdge = 480;

/// Convert a [CameraImage] into tightly packed RGBA bytes for CIMBAR workers.
///
/// Optionally downscales so the long edge is at most [maxEdge].
/// Returns null when the platform format is not supported.
Uint8List? cameraImageToRgba(
  CameraImage image, {
  int maxEdge = cimbarNativeFrameMaxEdge,
}) {
  final width = image.width;
  final height = image.height;
  if (width <= 0 || height <= 0 || image.planes.isEmpty) return null;

  Uint8List? full;
  final group = image.format.group;
  if (group == ImageFormatGroup.bgra8888) {
    full = _bgraToRgba(image);
  } else if (group == ImageFormatGroup.yuv420) {
    full = _yuv420ToRgba(image);
  } else {
    // Some iOS builds report unknown; try BGRA layout when 4 bytes/pixel.
    final plane = image.planes.first;
    if (plane.bytesPerPixel == 4) {
      full = _bgraToRgba(image);
    }
  }
  if (full == null) return null;

  if (maxEdge <= 0) return full;
  final longEdge = math.max(width, height);
  if (longEdge <= maxEdge) return full;

  final scale = maxEdge / longEdge;
  final outW = math.max(1, (width * scale).round());
  final outH = math.max(1, (height * scale).round());
  return _downscaleRgba(full, width, height, outW, outH);
}

/// Size after [cameraImageToRgba] downscale (or original when no scale).
({int width, int height}) cameraImageRgbaSize(
  CameraImage image, {
  int maxEdge = cimbarNativeFrameMaxEdge,
}) {
  final width = image.width;
  final height = image.height;
  if (width <= 0 || height <= 0 || maxEdge <= 0) {
    return (width: width, height: height);
  }
  final longEdge = math.max(width, height);
  if (longEdge <= maxEdge) return (width: width, height: height);
  final scale = maxEdge / longEdge;
  return (
    width: math.max(1, (width * scale).round()),
    height: math.max(1, (height * scale).round()),
  );
}

Uint8List _bgraToRgba(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final plane = image.planes.first;
  final src = plane.bytes;
  final rowStride = plane.bytesPerRow;
  final out = Uint8List(width * height * 4);
  var o = 0;
  for (var y = 0; y < height; y++) {
    final row = y * rowStride;
    for (var x = 0; x < width; x++) {
      final i = row + x * 4;
      if (i + 3 >= src.length) break;
      // BGRA → RGBA
      out[o] = src[i + 2];
      out[o + 1] = src[i + 1];
      out[o + 2] = src[i];
      out[o + 3] = src[i + 3];
      o += 4;
    }
  }
  return out;
}

Uint8List _yuv420ToRgba(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes.length > 1 ? image.planes[1] : yPlane;
  final vPlane = image.planes.length > 2 ? image.planes[2] : uPlane;
  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;
  final yRow = yPlane.bytesPerRow;
  final uRow = uPlane.bytesPerRow;
  final vRow = vPlane.bytesPerRow;
  final uPix = uPlane.bytesPerPixel ?? 1;
  final vPix = vPlane.bytesPerPixel ?? 1;
  final out = Uint8List(width * height * 4);
  var o = 0;
  for (var y = 0; y < height; y++) {
    final yOffset = y * yRow;
    final uvRow = y >> 1;
    for (var x = 0; x < width; x++) {
      final Y = yBytes[yOffset + x];
      final uvCol = x >> 1;
      final U = uBytes[uvRow * uRow + uvCol * uPix];
      final V = vBytes[uvRow * vRow + uvCol * vPix];
      // BT.601
      final c = Y - 16;
      final d = U - 128;
      final e = V - 128;
      final r = _clamp((298 * c + 409 * e + 128) >> 8);
      final g = _clamp((298 * c - 100 * d - 208 * e + 128) >> 8);
      final b = _clamp((298 * c + 516 * d + 128) >> 8);
      out[o] = r;
      out[o + 1] = g;
      out[o + 2] = b;
      out[o + 3] = 255;
      o += 4;
    }
  }
  return out;
}

/// Nearest-neighbor downscale of tightly packed RGBA.
@visibleForTesting
Uint8List downscaleRgbaForTest(
  Uint8List src,
  int srcW,
  int srcH,
  int dstW,
  int dstH,
) =>
    _downscaleRgba(src, srcW, srcH, dstW, dstH);

Uint8List _downscaleRgba(
  Uint8List src,
  int srcW,
  int srcH,
  int dstW,
  int dstH,
) {
  final out = Uint8List(dstW * dstH * 4);
  for (var y = 0; y < dstH; y++) {
    final sy = (y * srcH) ~/ dstH;
    final srcRow = sy * srcW * 4;
    final dstRow = y * dstW * 4;
    for (var x = 0; x < dstW; x++) {
      final sx = (x * srcW) ~/ dstW;
      final si = srcRow + sx * 4;
      final di = dstRow + x * 4;
      out[di] = src[si];
      out[di + 1] = src[si + 1];
      out[di + 2] = src[si + 2];
      out[di + 3] = src[si + 3];
    }
  }
  return out;
}

int _clamp(int value) {
  if (value < 0) return 0;
  if (value > 255) return 255;
  return value;
}
