import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _cimbarUpstreamAssets = <String>[
  'assets/cimbar/upstream/cimbar_js.2026-07-13T0523.js',
  'assets/cimbar/upstream/cimbar_js.2026-07-13T0523.wasm',
  'assets/cimbar/upstream/main.2026-07-13T0523.js',
  'assets/cimbar/upstream/recv.2026-07-13T0523.js',
  'assets/cimbar/upstream/recv-worker.2026-07-13T0523.js',
  'assets/cimbar/upstream/send.2026-07-13T0523.js',
  'assets/cimbar/upstream/send-worker.2026-07-13T0523.js',
  'assets/cimbar/upstream/zstd.2026-07-13T0523.js',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads every packaged CIMBAR upstream JS/WASM asset', () async {
    for (final assetPath in _cimbarUpstreamAssets) {
      final data = await rootBundle.load(assetPath);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'CIMBAR asset is empty: $assetPath',
      );
    }
  });
}
