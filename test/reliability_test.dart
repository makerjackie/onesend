import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/fountain.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';

void main() {
  test('both profiles survive randomized loss, corruption, and reordering', () {
    for (final mode in TransferMode.values) {
      for (final blockCount in <int>[1, 7, 31, 127, 1023]) {
        final trials = blockCount >= 1023 ? 2 : 4;
        for (var trial = 0; trial < trials; trial++) {
          _runChannelSimulation(mode, blockCount, trial);
        }
      }
    }
  });
}

void _runChannelSimulation(
  TransferMode mode,
  int requestedBlockCount,
  int trial,
) {
  final random = math.Random(
    0x51a9 + mode.id * 100000 + requestedBlockCount * 100 + trial,
  );
  final payloadLength =
      requestedBlockCount * mode.blockLength - random.nextInt(mode.blockLength);
  final payload = Uint8List.fromList(
    List<int>.generate(
      payloadLength,
      (index) => (index * 73 + trial * 19 + requestedBlockCount) & 0xff,
    ),
  );
  final sessionId = 0x10000000 + requestedBlockCount * 100 + trial;
  final encoder = LTEncoder(
    payload: payload,
    blockLength: mode.blockLength,
    sessionId: sessionId,
  );
  final receiver = OpticalReceiver();
  final checksum = crc32(payload);
  final startSequence = random.nextInt(encoder.blockCount * 2 + 1);
  final candidates = <Uint8List>[];
  var corruptedFrames = 0;

  for (
    var sequence = startSequence;
    sequence < startSequence + encoder.blockCount * 10;
    sequence++
  ) {
    if (random.nextDouble() < 0.34) continue;
    final frame = packFrame(
      FrameHeader(
        profileId: mode.id,
        sessionId: sessionId,
        sequence: sequence,
        blockCount: encoder.blockCount,
        blockLength: encoder.blockLength,
        totalLength: payload.length,
        payloadChecksum: checksum,
      ),
      encoder.encode(sequence),
    );
    if (random.nextDouble() < 0.08) {
      frame[frameHeaderLength + random.nextInt(mode.blockLength)] ^= 0x01;
      corruptedFrames++;
    }
    candidates.add(frame);
    if (random.nextDouble() < 0.12) candidates.add(Uint8List.fromList(frame));
  }
  candidates.shuffle(random);

  Uint8List? reconstructed;
  for (final frame in candidates) {
    reconstructed ??= receiver.consume(frame)?.payload;
    if (reconstructed != null) break;
  }

  expect(
    reconstructed,
    orderedEquals(payload),
    reason:
        '${mode.name}, $requestedBlockCount blocks, trial $trial did not recover',
  );
  if (corruptedFrames > 0) {
    expect(receiver.snapshot!.framesNew, lessThan(candidates.length));
  }
}
