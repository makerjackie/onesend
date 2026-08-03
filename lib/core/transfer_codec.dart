import 'package:flutter/foundation.dart';

import 'envelope.dart';

// Keep these callbacks top-level and the messages made only of sendable
// values. Isolate.run's documentation warns that a closure can capture more
// state than its body references (dartbug 36983), including unsendable async
// state from the surrounding StatefulWidget method.

/// Encodes a picked file without sending UI state or plugin objects to the
/// worker isolate.
Future<Uint8List> encodeTransferFileInBackground({
  required String name,
  required String mimeType,
  required Uint8List bytes,
  bool enableCompression = true,
}) {
  return compute<Map<String, Object?>, Uint8List>(
    _encodeTransferFileCallback,
    <String, Object?>{
      'name': name,
      'mimeType': mimeType,
      'bytes': bytes,
      'enableCompression': enableCompression,
    },
    debugLabel: 'encode transfer file',
  );
}

/// Decodes an optical payload without sending UI state or plugin objects to
/// the worker isolate.
Future<TransferFile> decodeTransferFileInBackground(Uint8List payload) async {
  final message = await compute<Uint8List, Map<String, Object?>>(
    _decodeTransferFileCallback,
    payload,
    debugLabel: 'decode transfer file',
  );
  return TransferFile(
    name: message['name']! as String,
    mimeType: message['mimeType']! as String,
    bytes: message['bytes']! as Uint8List,
    wasCompressed: message['wasCompressed']! as bool,
  );
}

Uint8List _encodeTransferFileCallback(Map<String, Object?> message) {
  return encodeTransferFile(
    TransferFile(
      name: message['name']! as String,
      mimeType: message['mimeType']! as String,
      bytes: message['bytes']! as Uint8List,
    ),
    enableCompression: message['enableCompression']! as bool,
  );
}

Map<String, Object?> _decodeTransferFileCallback(Uint8List payload) {
  final file = decodeTransferFile(payload);
  return <String, Object?>{
    'name': file.name,
    'mimeType': file.mimeType,
    'bytes': file.bytes,
    'wasCompressed': file.wasCompressed,
  };
}
