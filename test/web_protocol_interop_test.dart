import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/envelope.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';

Map<String, dynamic> _loadFixture(String name) {
  final source = File('test/fixtures/optical_interop/$name');
  return jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
}

Uint8List _decode(String value) => Uint8List.fromList(base64Decode(value));

Map<String, dynamic> _asMap(Object? value) => value! as Map<String, dynamic>;

TransferMode _modeFor(String name) =>
    TransferMode.values.firstWhere((mode) => mode.name == name);

void _expectFrame(
  Uint8List bytes,
  Map<String, dynamic> document,
  Map<String, dynamic> fixture,
  Map<String, dynamic> frameFixture,
  TransferMode mode,
) {
  expect(bytes.length, mode.blockLength + opticalFrameOverheadBytes);
  expect(
    ByteData.sublistView(
      bytes,
    ).getUint32(bytes.length - frameChecksumLength, Endian.little),
    frameFixture['frameChecksum'],
  );
  expect(
    crc32(bytes, end: bytes.length - frameChecksumLength),
    frameFixture['frameChecksum'],
  );

  final parsed = parseFrame(bytes);
  expect(parsed, isNotNull);
  final header = parsed!.header;
  expect(header.protocolVersion, document['protocolVersion']);
  expect(header.profileId, mode.id);
  expect(header.profileId, fixture['profileId']);
  expect(header.sessionId, fixture['sessionId']);
  expect(header.sequence, frameFixture['sequence']);
  expect(header.blockCount, fixture['blockCount']);
  expect(header.blockLength, mode.blockLength);
  expect(header.blockLength, fixture['blockLength']);
  expect(header.totalLength, fixture['totalLength']);
  expect(header.payloadChecksum, fixture['payloadChecksum']);
}

void _checkDartCanReadJsFixture(Map<String, dynamic> document) {
  expect(document['schemaVersion'], 1);
  expect(document['protocolVersion'], currentProtocolVersion);
  expect(document['source'], 'javascript');

  final file = _asMap(document['file']);
  final original = _decode(file['bytesBase64'] as String);
  final envelope = _decode(file['envelopeBase64'] as String);
  expect(envelope.length, file['envelopeLength']);
  expect(crc32(envelope), file['envelopeChecksum']);

  final decoded = decodeTransferFile(envelope);
  expect(decoded.name, file['name']);
  expect(decoded.mimeType, file['mimeType']);
  expect(decoded.bytes, orderedEquals(original));
  expect(decoded.wasCompressed, isFalse);

  for (final rawCase in document['cases'] as List<dynamic>) {
    final fixture = _asMap(rawCase);
    final mode = _modeFor(fixture['mode'] as String);
    expect(fixture['profileId'], mode.id);
    expect(fixture['blockLength'], mode.blockLength);
    expect(
      fixture['usesRatelessFountain'],
      mode.usesRatelessFountainFor(fixture['blockCount'] as int),
    );

    final receiver = OpticalReceiver();
    ReceiverEvent? completion;
    final frames = fixture['frames'] as List<dynamic>;
    expect(frames, isNotEmpty);
    expect(frames.length, lessThanOrEqualTo(32));
    for (final rawFrame in frames) {
      final frameFixture = _asMap(rawFrame);
      final bytes = _decode(frameFixture['bytesBase64'] as String);
      _expectFrame(bytes, document, fixture, frameFixture, mode);
      final event = receiver.consume(bytes);
      if (event?.verified == true) completion = event;
    }

    expect(completion, isNotNull);
    expect(completion!.verified, isTrue);
    expect(completion.payload, orderedEquals(envelope));
    expect(completion.snapshot.mode, mode);
    expect(completion.snapshot.sessionId, fixture['sessionId']);
    expect(completion.snapshot.blockCount, fixture['blockCount']);
    expect(completion.snapshot.blockLength, fixture['blockLength']);
    expect(completion.snapshot.solvedBlocks, fixture['blockCount']);
  }
}

void main() {
  test('Dart parses JS-generated v2 frames and Envelope fixtures', () {
    _checkDartCanReadJsFixture(_loadFixture('js_to_dart.json'));
  });
}
