import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/envelope.dart';
import 'package:onesend/core/fountain.dart';
import 'package:onesend/core/protocol.dart';

void main() {
  test('transfer envelope preserves metadata and bytes', () {
    final original = TransferFile(
      name: '报告 01.pdf',
      mimeType: 'application/pdf',
      bytes: Uint8List.fromList(List<int>.generate(257, (i) => i & 0xff)),
    );

    final decoded = decodeTransferFile(encodeTransferFile(original));

    expect(decoded.name, original.name);
    expect(decoded.mimeType, original.mimeType);
    expect(decoded.bytes, orderedEquals(original.bytes));
  });

  test('LT fountain decoder reconstructs frames in an imperfect order', () {
    final payload = Uint8List.fromList(
      List<int>.generate(31 * 1450 + 17, (i) => (i * 37 + 11) & 0xff),
    );
    const sessionId = 0x1234;
    final encoder = LTEncoder(
      payload: payload,
      blockLength: 1450,
      sessionId: sessionId,
    );
    final decoder = LTDecoder(
      blockCount: encoder.blockCount,
      blockLength: encoder.blockLength,
      sessionId: sessionId,
      totalLength: payload.length,
    );

    final sequenceNumbers = <int>[];
    for (
      var sequence = 0;
      sequence < encoder.blockCount * 4 && !decoder.isComplete;
      sequence++
    ) {
      if (sequence % 7 != 0) sequenceNumbers.add(sequence);
    }
    sequenceNumbers.shuffle();
    for (final sequence in sequenceNumbers) {
      decoder.addFrame(sequence, encoder.encode(sequence));
      if (decoder.isComplete) break;
    }

    expect(decoder.isComplete, isTrue);
    expect(decoder.assemble(), orderedEquals(payload));
  });

  test('wire frame round trips as little-endian bytes', () {
    final header = FrameHeader(
      sessionId: 0x4321,
      sequence: 0x10203040,
      blockCount: 3,
      blockLength: 4,
      totalLength: 12,
      payloadHash: 0xaabbccdd,
    );
    final frame = packFrame(header, Uint8List.fromList([1, 2, 3, 4]));
    final parsed = parseFrame(frame);

    expect(parsed, isNotNull);
    expect(parsed!.header.sessionId, header.sessionId);
    expect(parsed.header.sequence, header.sequence);
    expect(parsed.header.payloadHash, header.payloadHash);
    expect(parsed.block, orderedEquals([1, 2, 3, 4]));
  });
}
