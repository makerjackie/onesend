import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';
import 'package:qr/qr.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    for (final mode in TransferMode.values) {
      final block = Uint8List.fromList(
        List<int>.generate(
          mode.blockLength,
          (index) => (index * 149 + mode.id * 31) & 0xff,
        ),
      );
      final frame = packFrame(
        FrameHeader(
          profileId: mode.id,
          sessionId: 0xf1020304,
          sequence: 0x10203040,
          blockCount: 1,
          blockLength: mode.blockLength,
          totalLength: mode.blockLength,
          payloadChecksum: crc32(block),
        ),
        block,
      );
      final qr = QrImage(
        QrCode(
          payload: QrPayload.fromTypedData(frame),
          errorCorrectLevel: mode == TransferMode.reliable
              ? QrErrorCorrectLevel.medium
              : QrErrorCorrectLevel.low,
        ),
      );
      final raster = _rasterize(qr);
      final result = zxing.zx.readBarcode(
        raster.pixels,
        zxing.DecodeParams(
          imageFormat: zxing.ImageFormat.lum,
          format: zxing.Format.qrCode,
          width: raster.side,
          height: raster.side,
          tryHarder: true,
          tryRotate: false,
          tryDownscale: true,
        ),
      );
      final decoded = result.rawBytes;
      if (!result.isValid ||
          decoded == null ||
          !_bytesEqual(decoded, frame) ||
          parseFrame(decoded) == null) {
        throw StateError('${mode.name} QR codec self-test failed');
      }
    }
    stdout.writeln('OneSend native QR codec self-test passed.');
    exit(0);
  } catch (error, stackTrace) {
    stderr
      ..writeln(error)
      ..writeln(stackTrace);
    exit(1);
  }
}

({Uint8List pixels, int side}) _rasterize(QrImage qr) {
  const quietZone = 4;
  const scale = 4;
  final side = (qr.moduleCount + quietZone * 2) * scale;
  final pixels = Uint8List(side * side)..fillRange(0, side * side, 0xf4);

  for (var row = 0; row < qr.moduleCount; row++) {
    for (var column = 0; column < qr.moduleCount; column++) {
      if (!qr.isDark(row, column)) continue;
      final top = (row + quietZone) * scale;
      final left = (column + quietZone) * scale;
      for (var y = top; y < top + scale; y++) {
        pixels.fillRange(y * side + left, y * side + left + scale, 0x12);
      }
    }
  }
  return (pixels: pixels, side: side);
}

bool _bytesEqual(Uint8List left, Uint8List right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
