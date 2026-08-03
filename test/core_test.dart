import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/envelope.dart';
import 'package:onesend/core/fountain.dart';
import 'package:onesend/core/frame_pacer.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';
import 'package:onesend/core/transfer_codec.dart';
import 'package:onesend/widgets/optical_qr.dart';
import 'package:qr/qr.dart';

void main() {
  group('checksums and file envelope', () {
    test('CRC32 matches the standard check vector', () {
      expect(crc32(Uint8List.fromList(ascii.encode('123456789'))), 0xcbf43926);
    });

    test('v2 envelope compresses and preserves metadata and bytes', () {
      final original = TransferFile(
        name: '报告 01.txt',
        mimeType: 'text/plain',
        bytes: Uint8List.fromList(List<int>.filled(12000, 0x41)),
      );

      final encoded = encodeTransferFile(original);
      final decoded = decodeTransferFile(encoded);

      expect(encoded.length, lessThan(original.bytes.length ~/ 4));
      expect(decoded.name, original.name);
      expect(decoded.mimeType, original.mimeType);
      expect(decoded.wasCompressed, isTrue);
      expect(decoded.bytes, orderedEquals(original.bytes));
    });

    test('v2 envelope rejects corrupted stored data', () {
      final encoded = encodeTransferFile(
        TransferFile(
          name: 'notes.txt',
          mimeType: 'text/plain',
          bytes: Uint8List.fromList(List<int>.filled(4096, 0x62)),
        ),
      );
      encoded[encoded.length - 1] ^= 0x01;

      expect(() => decodeTransferFile(encoded), throwsFormatException);
    });

    test('v2 envelope bounds decompression to its declared size', () {
      final encoded = encodeTransferFile(
        TransferFile(
          name: 'repetitive.txt',
          mimeType: 'text/plain',
          bytes: Uint8List.fromList(List<int>.filled(4096, 0x61)),
        ),
      );
      ByteData.sublistView(encoded).setUint32(10, 1, Endian.little);

      expect(() => decodeTransferFile(encoded), throwsFormatException);
    });

    test('v2 envelope rejects oversized declared files before decoding', () {
      final encoded = encodeTransferFile(
        TransferFile(
          name: 'small.txt',
          mimeType: 'text/plain',
          bytes: Uint8List.fromList(List<int>.filled(2048, 0x61)),
        ),
      );
      ByteData.sublistView(
        encoded,
      ).setUint32(10, maxTransferFileBytes + 1, Endian.little);

      expect(() => decodeTransferFile(encoded), throwsFormatException);
    });

    test('legacy v1 envelope remains readable', () {
      final payload = Uint8List.fromList(<int>[7, 8, 9, 10]);
      final decoded = decodeTransferFile(
        _legacyEnvelope('legacy.bin', 'application/octet-stream', payload),
      );

      expect(decoded.name, 'legacy.bin');
      expect(decoded.bytes, orderedEquals(payload));
    });

    test('empty files remain valid transfers', () {
      final decoded = decodeTransferFile(
        encodeTransferFile(
          TransferFile(
            name: 'empty.txt',
            mimeType: 'text/plain',
            bytes: Uint8List(0),
          ),
        ),
      );

      expect(decoded.name, 'empty.txt');
      expect(decoded.bytes, isEmpty);
    });
  });

  group('background transfer codec', () {
    test(
      'round trips compressed text with metadata across an isolate',
      () async {
        final originalBytes = Uint8List.fromList(List<int>.filled(12000, 0x41));

        final encoded = await encodeTransferFileInBackground(
          name: '报告 01.txt',
          mimeType: 'text/plain',
          bytes: originalBytes,
        );
        final decoded = await decodeTransferFileInBackground(encoded);

        expect(decoded.name, '报告 01.txt');
        expect(decoded.mimeType, 'text/plain');
        expect(decoded.wasCompressed, isTrue);
        expect(decoded.bytes, orderedEquals(originalBytes));
      },
    );

    test(
      'round trips arbitrary binary without compression across an isolate',
      () async {
        final originalBytes = Uint8List.fromList(
          List<int>.generate(4096, (index) => (index * 73 + 19) & 0xff),
        );

        final encoded = await encodeTransferFileInBackground(
          name: 'payload.bin',
          mimeType: 'application/octet-stream',
          bytes: originalBytes,
          enableCompression: false,
        );
        final decoded = await decodeTransferFileInBackground(encoded);

        expect(decoded.name, 'payload.bin');
        expect(decoded.mimeType, 'application/octet-stream');
        expect(decoded.wasCompressed, isFalse);
        expect(decoded.bytes, orderedEquals(originalBytes));
      },
    );
  });

  group('wire protocol', () {
    test('v2 frame round trips with 32-bit geometry', () {
      final header = FrameHeader(
        profileId: TransferMode.fast.id,
        sessionId: 0xfedcba98,
        sequence: 0x10203040,
        blockCount: 70000,
        blockLength: 4,
        totalLength: 280000,
        payloadChecksum: 0xaabbccdd,
      );
      final frame = packFrame(header, Uint8List.fromList(<int>[1, 2, 3, 4]));
      final parsed = parseFrame(frame);

      expect(parsed, isNotNull);
      expect(parsed!.header.protocolVersion, currentProtocolVersion);
      expect(parsed.header.profileId, TransferMode.fast.id);
      expect(parsed.header.sessionId, header.sessionId);
      expect(parsed.header.sequence, header.sequence);
      expect(parsed.header.blockCount, 70000);
      expect(parsed.header.payloadChecksum, header.payloadChecksum);
      expect(parsed.block, orderedEquals(<int>[1, 2, 3, 4]));
    });

    test('turbo profile uses the V40-L-safe frame geometry', () {
      final block = _patternBytes(
        TransferMode.turbo.blockLength,
        multiplier: 41,
      );
      final frame = packFrame(
        FrameHeader(
          profileId: TransferMode.turbo.id,
          sessionId: 0x10203040,
          sequence: 7,
          blockCount: 1,
          blockLength: TransferMode.turbo.blockLength,
          totalLength: block.length,
          payloadChecksum: crc32(block),
        ),
        block,
      );
      final parsed = parseFrame(frame);

      expect(TransferMode.fromId(3), TransferMode.turbo);
      expect(
        TransferMode.fromProfile(3, TransferMode.turbo.blockLength),
        TransferMode.turbo,
      );
      expect(frame.length, maxOpticalFrameLength);
      expect(frame.length, 2953);
      expect(parsed?.header.profileId, TransferMode.turbo.id);
      expect(parsed?.header.blockLength, 2921);
      expect(parsed?.block, orderedEquals(block));
    });

    test(
      'turbo sender emits the new profile without changing frame pacing',
      () {
        final emitted = <Uint8List>[];
        final sender = OpticalSender(
          payload: _patternBytes(
            TransferMode.turbo.blockLength + 7,
            multiplier: 47,
          ),
          fileName: 'turbo.bin',
          mimeType: 'application/octet-stream',
          mode: TransferMode.turbo,
          useInternalClock: false,
          onFrame: (frame, _) => emitted.add(frame),
        );

        sender.start();
        sender.stop();

        final parsed = parseFrame(emitted.single);
        expect(TransferMode.turbo.framesPerSecond, 24);
        expect(sender.frameInterval, TransferMode.turbo.frameInterval);
        expect(parsed?.header.profileId, TransferMode.turbo.id);
        expect(parsed?.header.blockLength, TransferMode.turbo.blockLength);
        expect(emitted.single.length, 2953);
      },
    );

    test('v2 frame rejects one-bit camera corruption', () {
      final header = FrameHeader(
        sessionId: 42,
        sequence: 3,
        blockCount: 2,
        blockLength: 8,
        totalLength: 15,
        payloadChecksum: 123,
      );
      final frame = packFrame(header, Uint8List(8));
      frame[frameHeaderLength + 3] ^= 0x01;

      expect(parseFrame(frame), isNull);
    });

    test('legacy v1 frame remains readable', () {
      final frame = _legacyFrame(
        sessionId: 0x4321,
        sequence: 99,
        blockCount: 2,
        blockLength: 4,
        totalLength: 7,
        payloadHash: 0x12345678,
        block: Uint8List.fromList(<int>[4, 3, 2, 1]),
      );
      final parsed = parseFrame(frame);

      expect(parsed, isNotNull);
      expect(parsed!.header.protocolVersion, 1);
      expect(parsed.header.sessionId, 0x4321);
      expect(parsed.header.payloadChecksum, 0x12345678);
    });
  });

  group('fountain transport', () {
    test(
      'systematic stream completes after a late join without repair frames',
      () {
        final payload = _patternBytes(53 * 720 + 17, multiplier: 37);
        const sessionId = 0x12345678;
        final encoder = LTEncoder(
          payload: payload,
          blockLength: 720,
          sessionId: sessionId,
        );
        final decoder = LTDecoder(
          blockCount: encoder.blockCount,
          blockLength: encoder.blockLength,
          sessionId: sessionId,
          totalLength: payload.length,
        );

        for (
          var sequence = 37;
          sequence < 37 + encoder.blockCount * 4 && !decoder.isComplete;
          sequence++
        ) {
          if (isRepairSequence(sequence)) continue;
          decoder.addFrame(sequence, encoder.encode(sequence));
        }

        expect(decoder.isComplete, isTrue);
        expect(decoder.assemble(), orderedEquals(payload));
      },
    );

    test('repair stream tolerates loss, duplicates, and reordering', () {
      final payload = _patternBytes(79 * 720 + 51, multiplier: 19);
      const sessionId = 0x87654321;
      final encoder = LTEncoder(
        payload: payload,
        blockLength: 720,
        sessionId: sessionId,
      );
      final decoder = LTDecoder(
        blockCount: encoder.blockCount,
        blockLength: encoder.blockLength,
        sessionId: sessionId,
        totalLength: payload.length,
      );

      final sequences = <int>[
        for (var sequence = 21; sequence < encoder.blockCount * 8; sequence++)
          if (sequence % 9 != 0) sequence,
      ]..shuffle(math.Random(20260801));
      for (final sequence in sequences) {
        decoder.addFrame(sequence, encoder.encode(sequence));
        if (sequence % 17 == 0) {
          decoder.addFrame(sequence, encoder.encode(sequence));
        }
        if (decoder.isComplete) break;
      }

      expect(decoder.isComplete, isTrue);
      expect(decoder.framesDuplicate, greaterThan(0));
      expect(decoder.assemble(), orderedEquals(payload));
    });

    test('legacy v1 random LT schedule still decodes', () {
      final payload = _patternBytes(31 * 256 + 13, multiplier: 11);
      const sessionId = 0x1234;
      final encoder = LTEncoder(
        payload: payload,
        blockLength: 256,
        sessionId: sessionId,
        protocolVersion: 1,
      );
      final decoder = LTDecoder(
        blockCount: encoder.blockCount,
        blockLength: encoder.blockLength,
        sessionId: sessionId,
        totalLength: payload.length,
        protocolVersion: 1,
      );

      final sequences = <int>[
        for (var sequence = 0; sequence < encoder.blockCount * 5; sequence++)
          if (sequence % 7 != 0) sequence,
      ]..shuffle(math.Random(7));
      for (final sequence in sequences) {
        decoder.addFrame(sequence, encoder.encode(sequence));
        if (decoder.isComplete) break;
      }

      expect(decoder.isComplete, isTrue);
      expect(decoder.assemble(), orderedEquals(payload));
    });
  });

  group('end-to-end optical receiver', () {
    test('reconstructs a transfer despite deterministic frame loss', () {
      final original = TransferFile(
        name: 'photo.raw',
        mimeType: 'application/octet-stream',
        bytes: _patternBytes(25000, multiplier: 43),
      );
      final payload = encodeTransferFile(original, enableCompression: false);
      const sessionId = 0x10293847;
      final encoder = LTEncoder(
        payload: payload,
        blockLength: TransferMode.reliable.blockLength,
        sessionId: sessionId,
      );
      final receiver = OpticalReceiver();
      Uint8List? completedPayload;

      for (var sequence = 13; sequence < encoder.blockCount * 8; sequence++) {
        if (sequence % 8 == 0) continue;
        final block = encoder.encode(sequence);
        final frame = packFrame(
          FrameHeader(
            profileId: TransferMode.reliable.id,
            sessionId: sessionId,
            sequence: sequence,
            blockCount: encoder.blockCount,
            blockLength: encoder.blockLength,
            totalLength: payload.length,
            payloadChecksum: crc32(payload),
          ),
          block,
        );
        final event = receiver.consume(frame);
        completedPayload ??= event?.payload;
        if (completedPayload != null) break;
      }

      expect(completedPayload, isNotNull);
      final decoded = decodeTransferFile(completedPayload!);
      expect(decoded.name, original.name);
      expect(decoded.bytes, orderedEquals(original.bytes));
      expect(receiver.snapshot!.progress, 1);
    });

    test('ignores a foreign session after locking progress', () {
      final receiver = OpticalReceiver();
      receiver.consume(_singleBlockFrame(sessionId: 1, sequence: 0));
      receiver.consume(_singleBlockFrame(sessionId: 2, sequence: 0));

      expect(receiver.snapshot!.sessionId, 1);
    });

    test('accepts the OneSend 1.1 fast profile', () {
      final payload = Uint8List.fromList(<int>[7, 8, 9]);
      final block = Uint8List(1320)..setRange(0, payload.length, payload);
      final receiver = OpticalReceiver();
      final event = receiver.consume(
        packFrame(
          FrameHeader(
            profileId: 1,
            sessionId: 77,
            sequence: 0,
            blockCount: 1,
            blockLength: 1320,
            totalLength: payload.length,
            payloadChecksum: crc32(payload),
          ),
          block,
        ),
      );

      expect(event?.verified, isTrue);
      expect(event?.payload, orderedEquals(payload));
      expect(event?.snapshot.mode, TransferMode.fast);
    });

    test('accepts turbo geometry and selects rateless fountain decoding', () {
      final payload = Uint8List.fromList(<int>[7, 8, 9]);
      final block = Uint8List(TransferMode.turbo.blockLength)
        ..setRange(0, payload.length, payload);
      final receiver = OpticalReceiver();
      final event = receiver.consume(
        packFrame(
          FrameHeader(
            profileId: TransferMode.turbo.id,
            sessionId: 88,
            sequence: 0,
            blockCount: 1,
            blockLength: TransferMode.turbo.blockLength,
            totalLength: payload.length,
            payloadChecksum: crc32(payload),
          ),
          block,
        ),
      );

      expect(event?.verified, isTrue);
      expect(event?.payload, orderedEquals(payload));
      expect(event?.snapshot.mode, TransferMode.turbo);
      expect(event?.snapshot.usesRatelessFountain, isTrue);
    });
  });

  group('display pacing', () {
    test('fast mode sustains 24 fps on a 60 Hz display timeline', () {
      final pacer = FramePacer(TransferMode.fast.frameInterval);
      var emitted = 1; // The sender displays the first frame immediately.
      for (var displayFrame = 1; displayFrame <= 600; displayFrame++) {
        final elapsed = Duration(
          microseconds: displayFrame * Duration.microsecondsPerSecond ~/ 60,
        );
        if (pacer.shouldEmit(elapsed)) emitted++;
      }

      expect(emitted, 240);
    });

    test('missed display deadlines never create a catch-up burst', () {
      final pacer = FramePacer(TransferMode.fast.frameInterval);

      expect(pacer.shouldEmit(const Duration(seconds: 2)), isTrue);
      expect(
        pacer.shouldEmit(const Duration(seconds: 2, microseconds: 1)),
        isFalse,
      );
    });
  });

  test('raw and useful transport rates remain explicitly conservative', () {
    expect(TransferMode.reliable.rawBytesPerSecond, 5760);
    expect(TransferMode.fast.rawBytesPerSecond, 40800);
    expect(TransferMode.turbo.rawBytesPerSecond, 70104);
    expect(TransferMode.turbo.usefulBytesPerSecond, closeTo(56083.2, 0.001));
    expect(TransferMode.turbo.theoreticalCodeStreamBytesPerSecond, 70872);
  });

  test(
    'large fast and turbo transfers fall back to bounded-memory scheduling',
    () {
      expect(
        TransferMode.fast.usesRatelessFountainFor(maxRatelessFountainBlocks),
        isTrue,
      );
      expect(
        TransferMode.fast.usesRatelessFountainFor(
          maxRatelessFountainBlocks + 1,
        ),
        isFalse,
      );
      expect(
        TransferMode.turbo.usesRatelessFountainFor(maxRatelessFountainBlocks),
        isTrue,
      );
      expect(
        TransferMode.turbo.usesRatelessFountainFor(
          maxRatelessFountainBlocks + 1,
        ),
        isFalse,
      );
      expect(TransferMode.reliable.usesRatelessFountainFor(1), isFalse);
    },
  );

  test('rateless receiver progress follows accepted frames', () {
    const halfway = ReceiverSnapshot(
      protocolVersion: currentProtocolVersion,
      profileId: 2,
      sessionId: 1,
      blockCount: 512,
      blockLength: 1700,
      totalLength: 512 * 1700,
      framesNew: 320,
      framesDuplicate: 0,
      framesDiscarded: 0,
      solvedBlocks: 0,
    );
    const complete = ReceiverSnapshot(
      protocolVersion: currentProtocolVersion,
      profileId: 2,
      sessionId: 1,
      blockCount: 512,
      blockLength: 1700,
      totalLength: 512 * 1700,
      framesNew: 610,
      framesDuplicate: 0,
      framesDiscarded: 0,
      solvedBlocks: 512,
    );

    expect(halfway.progress, 0.5);
    expect(complete.progress, 1);
  });

  test('all transfer modes fit their intended QR error correction level', () {
    for (final mode in TransferMode.values) {
      final block = Uint8List(mode.blockLength);
      final frame = packFrame(
        FrameHeader(
          profileId: mode.id,
          sessionId: 1,
          sequence: 0,
          blockCount: 1,
          blockLength: mode.blockLength,
          totalLength: mode.blockLength,
          payloadChecksum: crc32(block),
        ),
        block,
      );
      final code = QrCode(
        payload: QrPayload.fromTypedData(frame),
        errorCorrectLevel: mode == TransferMode.reliable
            ? QrErrorCorrectLevel.medium
            : QrErrorCorrectLevel.low,
      );

      expect(QrImage(code).moduleCount, lessThanOrEqualTo(177));
      if (mode == TransferMode.fast) expect(code.typeNumber, 30);
      if (mode == TransferMode.turbo) expect(code.typeNumber, 40);
    }
  });

  test('the optimized fast frame produces a complete V30-L symbol', () {
    final block = _patternBytes(TransferMode.fast.blockLength, multiplier: 29);
    final frame = packFrame(
      FrameHeader(
        profileId: TransferMode.fast.id,
        sessionId: 0x10203040,
        sequence: 19,
        blockCount: 3,
        blockLength: block.length,
        totalLength: block.length * 3,
        payloadChecksum: crc32(block),
      ),
      block,
    );
    final image = buildOpticalQrImage(frame, robust: false);

    expect(image.typeNumber, 30);
    expect(image.moduleCount, 137);
    expect(image.errorCorrectLevel, QrErrorCorrectLevel.low);
    expect(image.qrModules.expand((row) => row), everyElement(isNotNull));
  });

  test('the optimized turbo frame produces a complete V40-L symbol', () {
    final block = _patternBytes(TransferMode.turbo.blockLength, multiplier: 53);
    final frame = packFrame(
      FrameHeader(
        profileId: TransferMode.turbo.id,
        sessionId: 0x20304050,
        sequence: 29,
        blockCount: 3,
        blockLength: block.length,
        totalLength: block.length * 3,
        payloadChecksum: crc32(block),
      ),
      block,
    );
    final image = buildOpticalQrImage(frame, robust: false);

    expect(frame.length, 2953);
    expect(image.typeNumber, 40);
    expect(image.moduleCount, 177);
    expect(image.errorCorrectLevel, QrErrorCorrectLevel.low);
    expect(image.qrModules.expand((row) => row), everyElement(isNotNull));
  });
}

Uint8List _patternBytes(int length, {required int multiplier}) =>
    Uint8List.fromList(
      List<int>.generate(length, (index) => (index * multiplier + 17) & 0xff),
    );

Uint8List _legacyEnvelope(String name, String mime, Uint8List payload) {
  final nameBytes = utf8.encode(name);
  final mimeBytes = utf8.encode(mime);
  final bytes = Uint8List(
    9 + nameBytes.length + mimeBytes.length + payload.length,
  );
  bytes.setRange(0, 4, const <int>[0x4c, 0x4d, 0x53, 0x31]);
  bytes[4] = 1;
  ByteData.sublistView(bytes)
    ..setUint16(5, nameBytes.length, Endian.little)
    ..setUint16(7, mimeBytes.length, Endian.little);
  bytes.setRange(9, 9 + nameBytes.length, nameBytes);
  bytes.setRange(
    9 + nameBytes.length,
    9 + nameBytes.length + mimeBytes.length,
    mimeBytes,
  );
  bytes.setRange(
    9 + nameBytes.length + mimeBytes.length,
    bytes.length,
    payload,
  );
  return bytes;
}

Uint8List _legacyFrame({
  required int sessionId,
  required int sequence,
  required int blockCount,
  required int blockLength,
  required int totalLength,
  required int payloadHash,
  required Uint8List block,
}) {
  final bytes = Uint8List(legacyFrameHeaderLength + blockLength);
  final data = ByteData.sublistView(bytes)
    ..setUint8(0, 0xd1)
    ..setUint8(1, 0x0c)
    ..setUint16(2, sessionId, Endian.little)
    ..setUint32(4, sequence, Endian.little)
    ..setUint16(8, blockCount, Endian.little)
    ..setUint16(10, blockLength, Endian.little)
    ..setUint32(12, totalLength, Endian.little)
    ..setUint32(16, payloadHash, Endian.little);
  data;
  bytes.setRange(legacyFrameHeaderLength, bytes.length, block);
  return bytes;
}

Uint8List _singleBlockFrame({required int sessionId, required int sequence}) {
  final payload = Uint8List.fromList(<int>[sessionId]);
  final block = Uint8List(TransferMode.reliable.blockLength)..[0] = sessionId;
  return packFrame(
    FrameHeader(
      profileId: TransferMode.reliable.id,
      sessionId: sessionId,
      sequence: sequence,
      blockCount: 1,
      blockLength: TransferMode.reliable.blockLength,
      totalLength: 1,
      payloadChecksum: crc32(payload),
    ),
    block,
  );
}
