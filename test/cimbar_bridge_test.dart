import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/core/protocol.dart';
import 'package:onesend/services/cimbar_bridge.dart';

String _event(Map<String, Object?> fields) => jsonEncode(fields);

String _chunk({
  required String session,
  required int index,
  required int size,
  required int totalChunks,
  required List<int> bytes,
}) => _event(<String, Object?>{
  'type': 'receive-file-chunk',
  'session': session,
  'index': index,
  'size': size,
  'totalChunks': totalChunks,
  'data': base64.encode(bytes),
});

void main() {
  test('parses structured bridge events and rejects malformed JSON', () {
    final event = CimbarBridgeEvent.parse(
      _event(<String, Object?>{
        'type': 'decode-progress',
        'progress': <double>[0.25, 0.5],
      }),
    );

    expect(event.type, 'decode-progress');
    expect(event.progressValues(), <double>[0.25, 0.5]);
    expect(
      () => CimbarBridgeEvent.parse('{not-json'),
      throwsA(isA<CimbarBridgeFormatException>()),
    );
    expect(
      () => CimbarBridgeEvent.parse(_event(<String, Object?>{'type': 'nope'})),
      throwsA(isA<CimbarBridgeFormatException>()),
    );
    // Camera-live must be allow-listed; otherwise receive dies right after open.
    final live = CimbarBridgeEvent.parse(
      _event(<String, Object?>{
        'type': 'receive-camera-live',
        'native': true,
        'width': 480,
        'height': 360,
      }),
    );
    expect(live.type, 'receive-camera-live');
  });

  test('reassembles out-of-order chunks and sanitizes the filename', () {
    const session = 'test-session';
    final bridge = CimbarBridge(
      assembler: CimbarChunkAssembler(chunkBytes: 4, maxFileBytes: 32),
    );
    bridge.accept(
      _event(<String, Object?>{
        'type': 'receive-file-start',
        'session': session,
        'name': '../../bad:name?.txt',
        'mimeType': 'text/plain',
        'size': 10,
        'totalChunks': 3,
        'crc32': crc32(Uint8List.fromList('abcdefghij'.codeUnits)),
        'verified': true,
      }),
    );

    bridge.accept(
      _chunk(
        session: session,
        index: 1,
        size: 10,
        totalChunks: 3,
        bytes: 'efgh'.codeUnits,
      ),
    );
    bridge.accept(
      _chunk(
        session: session,
        index: 2,
        size: 10,
        totalChunks: 3,
        bytes: 'ij'.codeUnits,
      ),
    );
    bridge.accept(
      _chunk(
        session: session,
        index: 0,
        size: 10,
        totalChunks: 3,
        bytes: 'abcd'.codeUnits,
      ),
    );
    final file = bridge.accept(
      _event(<String, Object?>{
        'type': 'receive-file-complete',
        'session': session,
        'size': 10,
        'totalChunks': 3,
        'crc32': crc32(Uint8List.fromList('abcdefghij'.codeUnits)),
        'verified': true,
      }),
    );

    expect(file, isNotNull);
    expect(file!.bytes, 'abcdefghij'.codeUnits);
    expect(file.mimeType, 'text/plain');
    expect(file.name, isNot(contains('/')));
    expect(file.name, isNot(contains('\\')));
    expect(file.name, isNot('../../bad:name?.txt'));
  });

  test('rejects duplicate, out-of-range, and oversized chunks', () {
    final bridge = CimbarBridge(
      assembler: CimbarChunkAssembler(chunkBytes: 4, maxFileBytes: 8),
    );
    bridge.accept(
      _event(<String, Object?>{
        'type': 'receive-file-start',
        'session': 'safe-session',
        'name': 'file.bin',
        'mimeType': 'application/octet-stream',
        'size': 5,
        'totalChunks': 2,
        'crc32': 0,
        'verified': true,
      }),
    );
    final chunk = _chunk(
      session: 'safe-session',
      index: 0,
      size: 5,
      totalChunks: 2,
      bytes: <int>[1, 2, 3, 4],
    );
    bridge.accept(chunk);
    expect(
      () => bridge.accept(chunk),
      throwsA(isA<CimbarBridgeFormatException>()),
    );

    bridge.reset();
    bridge.accept(
      _event(<String, Object?>{
        'type': 'receive-file-start',
        'session': 'safe-session',
        'name': 'file.bin',
        'mimeType': 'application/octet-stream',
        'size': 5,
        'totalChunks': 2,
        'crc32': 0,
        'verified': true,
      }),
    );
    expect(
      () => bridge.accept(
        _chunk(
          session: 'safe-session',
          index: 2,
          size: 5,
          totalChunks: 2,
          bytes: <int>[1],
        ),
      ),
      throwsA(isA<CimbarBridgeFormatException>()),
    );
    expect(
      () =>
          CimbarBridge(
            assembler: CimbarChunkAssembler(chunkBytes: 4, maxFileBytes: 4),
          ).accept(
            _event(<String, Object?>{
              'type': 'receive-file-start',
              'session': 'too-large',
              'name': 'file.bin',
              'mimeType': 'application/octet-stream',
              'size': 5,
              'totalChunks': 2,
              'crc32': 0,
              'verified': true,
            }),
          ),
      throwsA(isA<CimbarBridgeFormatException>()),
    );
  });

  test('does not complete while any chunk is missing', () {
    final bridge = CimbarBridge(
      assembler: CimbarChunkAssembler(chunkBytes: 4, maxFileBytes: 8),
    );
    bridge.accept(
      _event(<String, Object?>{
        'type': 'receive-file-start',
        'session': 'missing-chunk',
        'name': 'file.bin',
        'mimeType': 'application/octet-stream',
        'size': 5,
        'totalChunks': 2,
        'crc32': 0,
        'verified': true,
      }),
    );
    bridge.accept(
      _chunk(
        session: 'missing-chunk',
        index: 0,
        size: 5,
        totalChunks: 2,
        bytes: <int>[1, 2, 3, 4],
      ),
    );
    expect(
      () => bridge.accept(
        _event(<String, Object?>{
          'type': 'receive-file-complete',
          'session': 'missing-chunk',
          'size': 5,
          'totalChunks': 2,
          'crc32': 0,
          'verified': true,
        }),
      ),
      throwsA(isA<CimbarBridgeFormatException>()),
    );
  });
}
