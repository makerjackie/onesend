import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/services/cimbar_camera_frames.dart';

void main() {
  group('cimbar native frame helpers', () {
    test('max edge constant is conservative for JS bridge', () {
      expect(cimbarNativeFrameMaxEdge, lessThanOrEqualTo(640));
      expect(cimbarNativeFrameMaxEdge, greaterThanOrEqualTo(240));
    });

    test('downscale keeps RGBA packing and samples corners', () {
      // 4x2 checker of distinct colors → 2x1.
      final src = Uint8List(4 * 2 * 4);
      void put(int x, int y, int r, int g, int b) {
        final i = (y * 4 + x) * 4;
        src[i] = r;
        src[i + 1] = g;
        src[i + 2] = b;
        src[i + 3] = 255;
      }

      put(0, 0, 10, 0, 0);
      put(1, 0, 20, 0, 0);
      put(2, 0, 30, 0, 0);
      put(3, 0, 40, 0, 0);
      put(0, 1, 50, 0, 0);
      put(1, 1, 60, 0, 0);
      put(2, 1, 70, 0, 0);
      put(3, 1, 80, 0, 0);

      final out = downscaleRgbaForTest(src, 4, 2, 2, 1);
      expect(out.length, 2 * 1 * 4);
      // nearest: (0,0)→(0,0)=10, (1,0)→(2,0)=30
      expect(out[0], 10);
      expect(out[4], 30);
      expect(out[3], 255);
      expect(out[7], 255);
    });
  });
}
