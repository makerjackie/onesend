import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/optical_transfer.dart';

import '../tool/benchmark_optical.dart';

void main() {
  test('benchmark reports all modes with reproducible protocol geometry', () {
    final results = runOpticalBenchmark(
      seed: 7,
      blockCount: 8,
      repeats: 1,
      lossRate: 0.25,
    );

    expect(results.map((result) => result.mode), TransferMode.values);
    for (final result in results) {
      expect(result.singleFrameNetBytes, result.mode.blockLength);
      expect(
        result.singleFrameWireBytes,
        result.mode.blockLength + opticalFrameOverheadBytes,
      );
      expect(result.rawBytesPerSecond, result.mode.rawBytesPerSecond);
      expect(
        result.theoreticalCodeStreamBytesPerSecond,
        result.mode.theoreticalCodeStreamBytesPerSecond,
      );
      expect(result.protocolEncodeCpuBytesPerSecond, greaterThan(0));
      expect(result.protocolDecodeCpuBytesPerSecond, greaterThan(0));
      expect(result.recovered, isTrue);
      expect(result.recoveredPayloadBytes, result.payloadLength);
      expect(result.recoveryUsefulBytesPerSecond, greaterThan(0));
    }

    final turbo = results.singleWhere(
      (result) => result.mode == TransferMode.turbo,
    );
    expect(turbo.singleFrameNetBytes, 2921);
    expect(turbo.singleFrameWireBytes, 2953);
  });

  test('benchmark rejects an invalid synthetic loss rate', () {
    expect(() => runOpticalBenchmark(lossRate: 1), throwsArgumentError);
  });
}
