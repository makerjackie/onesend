// ignore_for_file: avoid_print

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:onesend/core/fountain.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';

const int defaultBenchmarkSeed = 20260804;
const int defaultBenchmarkBlockCount = 64;
const int defaultBenchmarkRepeats = 1;
const double defaultBenchmarkLossRate = 0.30;

/// A host-only optical protocol benchmark result.
///
/// The CPU rates measure Dart protocol work. The end-to-end rate is calculated
/// from a deterministic synthetic frame-loss channel and the configured mode
/// frame rate; neither is a camera or QR decoder measurement.
class OpticalBenchmarkResult {
  const OpticalBenchmarkResult({
    required this.mode,
    required this.payloadLength,
    required this.singleFrameNetBytes,
    required this.singleFrameWireBytes,
    required this.rawBytesPerSecond,
    required this.theoreticalCodeStreamBytesPerSecond,
    required this.conservativeUsefulBytesPerSecond,
    required this.protocolEncodeCpuBytesPerSecond,
    required this.protocolDecodeCpuBytesPerSecond,
    required this.lossRate,
    required this.recoveryDisplayedFrames,
    required this.recoveredPayloadBytes,
    required this.recovered,
    required this.recoveryUsefulBytesPerSecond,
  });

  final TransferMode mode;
  final int payloadLength;
  final int singleFrameNetBytes;
  final int singleFrameWireBytes;
  final int rawBytesPerSecond;
  final int theoreticalCodeStreamBytesPerSecond;
  final double conservativeUsefulBytesPerSecond;
  final double protocolEncodeCpuBytesPerSecond;
  final double protocolDecodeCpuBytesPerSecond;
  final double lossRate;
  final int recoveryDisplayedFrames;
  final int recoveredPayloadBytes;
  final bool recovered;
  final double recoveryUsefulBytesPerSecond;

  Map<String, Object?> toJson() => <String, Object?>{
    'mode': mode.name,
    'profile_id': mode.id,
    'block_length': mode.blockLength,
    'payload_length': payloadLength,
    'single_frame_net_bytes': singleFrameNetBytes,
    'single_frame_wire_bytes': singleFrameWireBytes,
    'raw_bytes_per_second': rawBytesPerSecond,
    'theoretical_code_stream_bytes_per_second':
        theoreticalCodeStreamBytesPerSecond,
    'conservative_useful_bytes_per_second': conservativeUsefulBytesPerSecond,
    'protocol_encode_cpu_bytes_per_second': protocolEncodeCpuBytesPerSecond,
    'protocol_decode_cpu_bytes_per_second': protocolDecodeCpuBytesPerSecond,
    'e2e_loss_rate': lossRate,
    'e2e_recovery_displayed_frames': recoveryDisplayedFrames,
    'e2e_recovered_payload_bytes': recoveredPayloadBytes,
    'e2e_recovered': recovered,
    'e2e_recovery_useful_bytes_per_second': recoveryUsefulBytesPerSecond,
  };
}

/// Runs the same deterministic workload used by the command-line benchmark.
List<OpticalBenchmarkResult> runOpticalBenchmark({
  int seed = defaultBenchmarkSeed,
  int blockCount = defaultBenchmarkBlockCount,
  int repeats = defaultBenchmarkRepeats,
  double lossRate = defaultBenchmarkLossRate,
}) {
  if (blockCount <= 0) {
    throw ArgumentError.value(blockCount, 'blockCount', 'must be positive');
  }
  if (repeats <= 0) {
    throw ArgumentError.value(repeats, 'repeats', 'must be positive');
  }
  if (lossRate < 0 || lossRate >= 1) {
    throw ArgumentError.value(
      lossRate,
      'lossRate',
      'must be at least 0 and less than 1',
    );
  }

  return <OpticalBenchmarkResult>[
    for (final mode in TransferMode.values)
      _runMode(
        mode,
        seed: seed,
        blockCount: blockCount,
        repeats: repeats,
        lossRate: lossRate,
      ),
  ];
}

OpticalBenchmarkResult _runMode(
  TransferMode mode, {
  required int seed,
  required int blockCount,
  required int repeats,
  required double lossRate,
}) {
  final payloadLength = math.max(
    1,
    blockCount * mode.blockLength - mode.blockLength ~/ 3,
  );
  final payload = _benchmarkPayload(payloadLength, seed, mode);
  final sessionId = _sessionId(seed, mode);
  final payloadChecksum = crc32(payload);
  final cpuFrameCount = math.max(blockCount * 4, 8);
  final cpuEncoders = <LTEncoder>[
    for (var repeat = 0; repeat < repeats; repeat++)
      _newEncoder(mode, payload, sessionId),
  ];

  var encodedBytes = 0;
  final encodeWatch = Stopwatch()..start();
  var encodeGuard = 0;
  for (final encoder in cpuEncoders) {
    for (var sequence = 0; sequence < cpuFrameCount; sequence++) {
      final frame = _encodeFrame(
        mode,
        encoder,
        payload.length,
        payloadChecksum,
        sequence,
      );
      encodedBytes += mode.blockLength;
      encodeGuard ^= frame[frame.length - 1];
    }
  }
  encodeWatch.stop();
  if (encodeGuard < 0) throw StateError('unreachable benchmark guard');

  final decodeFrames = <Uint8List>[
    for (var sequence = 0; sequence < cpuFrameCount; sequence++)
      _encodeFrame(
        mode,
        cpuEncoders.first,
        payload.length,
        payloadChecksum,
        sequence,
      ),
  ];
  var decodedBytes = 0;
  final decodeWatch = Stopwatch()..start();
  for (var repeat = 0; repeat < repeats; repeat++) {
    final decoder = LTDecoder(
      blockCount: blockCount,
      blockLength: mode.blockLength,
      sessionId: sessionId,
      totalLength: payload.length,
      systematicFrames: !mode.usesRatelessFountainFor(blockCount),
    );
    for (final frame in decodeFrames) {
      final parsed = parseFrame(frame);
      if (parsed == null) continue;
      decodedBytes += parsed.block.length;
      decoder.addFrame(parsed.header.sequence, parsed.block);
    }
  }
  decodeWatch.stop();

  final receiver = OpticalReceiver();
  final e2eEncoder = _newEncoder(mode, payload, sessionId);
  final random = math.Random(_channelSeed(seed, mode));
  final maximumDisplayedFrames = math.max(blockCount * 32, 256);
  var displayedFrames = 0;
  Uint8List? recoveredPayload;
  for (
    var sequence = 0;
    sequence < maximumDisplayedFrames && recoveredPayload == null;
    sequence++
  ) {
    displayedFrames++;
    if (random.nextDouble() < lossRate) continue;
    final event = receiver.consume(
      _encodeFrame(mode, e2eEncoder, payload.length, payloadChecksum, sequence),
    );
    recoveredPayload = event?.payload;
  }

  final recovered = recoveredPayload != null;
  final recoveryRate = recovered
      ? payload.length * mode.framesPerSecond / displayedFrames
      : 0.0;
  // decodedBytes is intentionally retained as part of the measured work;
  // use it in a guard so a future optimizer cannot remove the decode loop.
  if (decodedBytes < 0) throw StateError('unreachable decode guard');

  return OpticalBenchmarkResult(
    mode: mode,
    payloadLength: payload.length,
    singleFrameNetBytes: mode.blockLength,
    singleFrameWireBytes: mode.blockLength + opticalFrameOverheadBytes,
    rawBytesPerSecond: mode.rawBytesPerSecond,
    theoreticalCodeStreamBytesPerSecond:
        mode.theoreticalCodeStreamBytesPerSecond,
    conservativeUsefulBytesPerSecond: mode.usefulBytesPerSecond,
    protocolEncodeCpuBytesPerSecond: _bytesPerSecond(
      encodedBytes,
      encodeWatch.elapsedMicroseconds,
    ),
    protocolDecodeCpuBytesPerSecond: _bytesPerSecond(
      decodedBytes,
      decodeWatch.elapsedMicroseconds,
    ),
    lossRate: lossRate,
    recoveryDisplayedFrames: displayedFrames,
    recoveredPayloadBytes: recoveredPayload?.length ?? 0,
    recovered: recovered,
    recoveryUsefulBytesPerSecond: recoveryRate,
  );
}

LTEncoder _newEncoder(TransferMode mode, Uint8List payload, int sessionId) {
  return LTEncoder(
    payload: payload,
    blockLength: mode.blockLength,
    sessionId: sessionId,
    systematicFrames: !mode.usesRatelessFountainFor(
      math.max(1, (payload.length + mode.blockLength - 1) ~/ mode.blockLength),
    ),
  );
}

Uint8List _encodeFrame(
  TransferMode mode,
  LTEncoder encoder,
  int totalLength,
  int payloadChecksum,
  int sequence,
) {
  final block = encoder.encode(sequence);
  return packFrame(
    FrameHeader(
      profileId: mode.id,
      sessionId: encoder.sessionId,
      sequence: sequence,
      blockCount: encoder.blockCount,
      blockLength: mode.blockLength,
      totalLength: totalLength,
      payloadChecksum: payloadChecksum,
    ),
    block,
  );
}

Uint8List _benchmarkPayload(int length, int seed, TransferMode mode) {
  final offset = (seed + mode.id * 67) & 0xff;
  return Uint8List.fromList(
    List<int>.generate(
      length,
      (index) => (index * 73 + offset) & 0xff,
      growable: false,
    ),
  );
}

int _sessionId(int seed, TransferMode mode) =>
    ((seed ^ (mode.id * 0x9e3779b9)) & 0x7fffffff) + 1;

int _channelSeed(int seed, TransferMode mode) =>
    (seed ^ (mode.id * 0x45d9f3b)) & 0x7fffffff;

double _bytesPerSecond(int bytes, int elapsedMicroseconds) =>
    bytes * Duration.microsecondsPerSecond / math.max(1, elapsedMicroseconds);

String _rate(double value) => value.toStringAsFixed(1);

void main(List<String> args) {
  if (args.contains('--help')) {
    print(
      'Usage: dart run tool/benchmark_optical.dart '
      '[--seed=N] [--blocks=N] [--repeats=N] [--loss=0.30]',
    );
    return;
  }

  var seed = defaultBenchmarkSeed;
  var blockCount = defaultBenchmarkBlockCount;
  var repeats = defaultBenchmarkRepeats;
  var lossRate = defaultBenchmarkLossRate;
  for (final argument in args) {
    if (argument.startsWith('--seed=')) {
      seed = int.parse(argument.substring('--seed='.length));
    } else if (argument.startsWith('--blocks=')) {
      blockCount = int.parse(argument.substring('--blocks='.length));
    } else if (argument.startsWith('--repeats=')) {
      repeats = int.parse(argument.substring('--repeats='.length));
    } else if (argument.startsWith('--loss=')) {
      lossRate = double.parse(argument.substring('--loss='.length));
    } else {
      throw ArgumentError('Unknown argument: $argument');
    }
  }

  final results = runOpticalBenchmark(
    seed: seed,
    blockCount: blockCount,
    repeats: repeats,
    lossRate: lossRate,
  );
  print('OneSend optical protocol benchmark');
  print(
    'seed=$seed blocks=$blockCount repeats=$repeats '
    'loss_rate=${lossRate.toStringAsFixed(2)} '
    'fps=${TransferMode.fast.framesPerSecond}',
  );
  print(
    'NOTE: CPU rates are host protocol-only; '
    'e2e rates use a deterministic synthetic loss channel and are not camera '
    'measurements.',
  );
  for (final result in results) {
    print(
      'mode=${result.mode.name} profile_id=${result.mode.id} '
      'block_length=${result.mode.blockLength} '
      'single_frame_net_bytes=${result.singleFrameNetBytes} '
      'single_frame_wire_bytes=${result.singleFrameWireBytes} '
      'raw_bytes_per_second=${result.rawBytesPerSecond} '
      'theoretical_code_stream_bytes_per_second='
      '${result.theoreticalCodeStreamBytesPerSecond} '
      'conservative_useful_bytes_per_second='
      '${_rate(result.conservativeUsefulBytesPerSecond)} '
      'protocol_encode_cpu_bytes_per_second='
      '${_rate(result.protocolEncodeCpuBytesPerSecond)} '
      'protocol_decode_cpu_bytes_per_second='
      '${_rate(result.protocolDecodeCpuBytesPerSecond)} '
      'e2e_recovery_displayed_frames=${result.recoveryDisplayedFrames} '
      'e2e_recovered=${result.recovered} '
      'e2e_recovered_payload_bytes=${result.recoveredPayloadBytes} '
      'e2e_recovery_useful_bytes_per_second='
      '${_rate(result.recoveryUsefulBytesPerSecond)}',
    );
  }
}
