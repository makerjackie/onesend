import 'dart:io';

import 'package:flutter/services.dart';

import 'file_service.dart';

const String sampleVideoAssetPath = 'assets/demo/onesend-optical-test.mp4';
const String sampleVideoFileName = 'onesend-optical-test.mp4';
const String sampleVideoMimeType = 'video/mp4';

/// Loads the checked-in optical test video as a transfer-ready file.
///
/// A Flutter [AssetBundle] is preferred when the asset is available in an
/// application bundle. The checked-in filesystem path is also supported for
/// desktop development and repository-level tests without changing the
/// application's existing asset manifest.
Future<PickedTransfer> loadSampleVideo({
  AssetBundle? bundle,
  String? filePath,
}) async {
  if (filePath != null) {
    return _readSampleVideoFile(File(filePath));
  }

  try {
    final data = await (bundle ?? rootBundle).load(sampleVideoAssetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return _toPickedTransfer(bytes);
  } on Object {
    // The repository path makes this service usable in desktop/dev runs where
    // the host intentionally has not registered a new asset yet.
  }

  return _readSampleVideoFile(File(sampleVideoAssetPath));
}

Future<PickedTransfer> _readSampleVideoFile(File file) async {
  final bytes = await file.readAsBytes();
  return _toPickedTransfer(bytes, sourcePath: file.path);
}

PickedTransfer _toPickedTransfer(Uint8List bytes, {String? sourcePath}) {
  if (bytes.isEmpty) {
    throw StateError('OneSend 内置测试视频为空。');
  }
  if (bytes.length > maxTransferBytes) {
    throw StateError('OneSend 内置测试视频超过 64 MB。');
  }

  return PickedTransfer(
    name: sampleVideoFileName,
    bytes: bytes,
    mimeType: sampleVideoMimeType,
    sourcePath: sourcePath,
  );
}
