import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_zxing/flutter_zxing.dart' as zxing;
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';
import 'package:onesend/widgets/optical_qr.dart';
import 'package:qr/qr.dart';

/// Runs the native QR encode/decode smoke test used before desktop releases.
///
/// The caller owns process lifecycle and exit codes. This function writes a
/// success message and throws the first verification failure it encounters.
Future<void> runNativeQrCodecSelfTest() async {
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
    final qr = buildOpticalQrImage(
      frame,
      robust: mode == TransferMode.reliable,
    );
    if (mode == TransferMode.fast && qr.moduleCount != 137) {
      throw StateError(
        'Fast mode must render an exact V30 symbol, got ${qr.moduleCount} modules',
      );
    }
    _decodeAndVerify(qr, frame, '${mode.name} production render');

    if (mode == TransferMode.fast) {
      final code = QrCode(
        payload: QrPayload.fromTypedData(frame),
        errorCorrectLevel: QrErrorCorrectLevel.low,
      );
      for (var mask = 0; mask < 8; mask++) {
        _decodeAndVerify(
          QrImage.withMaskPattern(code, mask),
          frame,
          'fast mask $mask',
        );
      }
    }
  }
  stdout.writeln('OneSend native QR codec self-test passed.');
}

void _decodeAndVerify(QrImage qr, Uint8List frame, String label) {
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
    throw StateError('$label QR codec self-test failed');
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
