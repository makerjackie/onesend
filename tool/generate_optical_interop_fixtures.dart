import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:onesend/core/envelope.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';
import 'package:onesend/core/fountain.dart';

Uint8List _bytesOf(int length, int seed) {
  return Uint8List.fromList(
    List<int>.generate(
      length,
      (index) => (index * 97 + seed * 13 + (index >> 3)) & 0xff,
      growable: false,
    ),
  );
}

String _base64(Uint8List bytes) => base64Encode(bytes);

int _frameChecksum(Uint8List frame) => ByteData.sublistView(
  frame,
).getUint32(frame.length - frameChecksumLength, Endian.little);

Map<String, Object?> _makeCase({
  required TransferMode mode,
  required int sessionId,
  required Uint8List envelope,
}) {
  final blockCount =
      (envelope.length + mode.blockLength - 1) ~/ mode.blockLength;
  final usesRateless = mode.usesRatelessFountainFor(blockCount);
  final encoder = LTEncoder(
    payload: envelope,
    blockLength: mode.blockLength,
    sessionId: sessionId,
    systematicFrames: !usesRateless,
  );
  final receiver = OpticalReceiver();
  final frames = <Map<String, Object?>>[];
  ReceiverEvent? completion;

  for (var sequence = 0; sequence < 32 && completion == null; sequence++) {
    final block = encoder.encode(sequence);
    final frame = packFrame(
      FrameHeader(
        profileId: mode.id,
        sessionId: sessionId,
        sequence: sequence,
        blockCount: encoder.blockCount,
        blockLength: mode.blockLength,
        totalLength: envelope.length,
        payloadChecksum: crc32(envelope),
      ),
      block,
    );
    final parsed = parseFrame(frame);
    if (parsed == null) {
      throw StateError('$mode generated an invalid frame');
    }
    final event = receiver.consume(frame);
    frames.add(<String, Object?>{
      'sequence': sequence,
      'frameChecksum': _frameChecksum(frame),
      'bytesBase64': _base64(frame),
    });
    if (event?.verified == true && event?.payload != null) {
      completion = event;
    }
  }

  if (completion?.verified != true || completion?.payload == null) {
    throw StateError('$mode fixture did not complete');
  }
  if (!_sameBytes(completion!.payload!, envelope)) {
    throw StateError('$mode fixture payload did not round-trip');
  }
  if (receiver.snapshot?.sessionId != sessionId) {
    throw StateError('$mode fixture session changed unexpectedly');
  }

  return <String, Object?>{
    'mode': mode.name,
    'profileId': mode.id,
    'sessionId': sessionId,
    'blockLength': mode.blockLength,
    'blockCount': encoder.blockCount,
    'totalLength': envelope.length,
    'payloadChecksum': crc32(envelope),
    'usesRatelessFountain': usesRateless,
    'frames': frames,
  };
}

bool _sameBytes(Uint8List left, Uint8List right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void main() {
  final file = TransferFile(
    name: 'dart-optical-interop.bin',
    mimeType: 'application/octet-stream',
    bytes: _bytesOf(3200, 53),
  );
  final envelope = encodeTransferFile(file, enableCompression: false);
  final sessionIds = <TransferMode, int>{
    TransferMode.reliable: 0x24681357,
    TransferMode.fast: 0x24681358,
    TransferMode.turbo: 0x24681359,
  };

  final document = <String, Object?>{
    'schemaVersion': 1,
    'protocolVersion': currentProtocolVersion,
    'source': 'dart',
    'generator': 'lib/core/optical_transfer.dart',
    'file': <String, Object?>{
      'name': file.name,
      'mimeType': file.mimeType,
      'bytesBase64': _base64(file.bytes),
      'envelopeLength': envelope.length,
      'envelopeChecksum': crc32(envelope),
      'envelopeBase64': _base64(envelope),
    },
    'cases': TransferMode.values
        .map(
          (mode) => _makeCase(
            mode: mode,
            sessionId: sessionIds[mode]!,
            envelope: envelope,
          ),
        )
        .toList(growable: false),
  };

  final scriptDirectory = File(Platform.script.toFilePath()).parent;
  final repositoryRoot = scriptDirectory.parent.path;
  final output = File(
    '$repositoryRoot/test/fixtures/optical_interop/dart_to_js.json',
  );
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(document)}\n',
  );
  stdout.writeln('wrote ${output.path}');
}
