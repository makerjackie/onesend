import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/screens/cimbar_transfer_screen.dart';

void main() {
  test('decode progress uses the furthest worker and never moves backward', () {
    expect(stableCimbarDecodeProgress(null, <double>[0.2, 0.45]), 0.45);
    expect(stableCimbarDecodeProgress(0.45, <double>[0.1, 0.3]), 0.45);
    expect(stableCimbarDecodeProgress(0.45, <double>[0.7, 0.4]), 0.7);
  });

  test(
    'decode progress clamps invalid ranges and ignores non-finite values',
    () {
      expect(stableCimbarDecodeProgress(null, <double>[-1, 2]), 1);
      expect(
        stableCimbarDecodeProgress(0.4, <double>[double.nan, double.infinity]),
        0.4,
      );
      expect(stableCimbarDecodeProgress(null, null), isNull);
    },
  );
}
