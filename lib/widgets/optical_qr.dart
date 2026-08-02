import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class OpticalQr extends StatelessWidget {
  const OpticalQr({
    required this.bytes,
    this.size = 320,
    this.robust = true,
    super.key,
  });

  final Uint8List bytes;
  final double size;
  final bool robust;

  @override
  Widget build(BuildContext context) {
    final image = buildOpticalQrImage(bytes, robust: robust);
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _OpticalQrPainter(
            image,
            MediaQuery.devicePixelRatioOf(context),
          ),
          size: Size.square(size),
        ),
      ),
    );
  }
}

QrImage buildOpticalQrImage(Uint8List bytes, {required bool robust}) {
  final code = QrCode(
    payload: QrPayload.fromTypedData(bytes),
    errorCorrectLevel: robust
        ? QrErrorCorrectLevel.medium
        : QrErrorCorrectLevel.low,
  );
  // Searching all eight masks is several milliseconds for a V30 symbol. Each
  // mask is standards-compliant, and the frame CRC gives us a stable,
  // well-distributed choice without adding work on the playback path.
  final maskByte = bytes.length >= 4 ? bytes[bytes.length - 4] : bytes.first;
  return QrImage.withMaskPattern(code, maskByte & 7);
}

class _OpticalQrPainter extends CustomPainter {
  _OpticalQrPainter(this.image, this.devicePixelRatio);

  final QrImage image;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    const marginModules = 4;
    final totalModules = image.moduleCount + marginModules * 2;
    final physicalModuleSize = math.max(
      1,
      (size.shortestSide * devicePixelRatio / totalModules).floor(),
    );
    final moduleSize = physicalModuleSize / devicePixelRatio;
    final renderedSize = moduleSize * totalModules;
    final origin = Offset(
      (size.width - renderedSize) / 2,
      (size.height - renderedSize) / 2,
    );
    final white = Paint()
      ..color = Colors.white
      ..isAntiAlias = false;
    final black = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, white);
    final modules = Path();
    for (var row = 0; row < image.moduleCount; row++) {
      for (var column = 0; column < image.moduleCount; column++) {
        if (!image.isDark(row, column)) continue;
        modules.addRect(
          Rect.fromLTWH(
            origin.dx + (column + marginModules) * moduleSize,
            origin.dy + (row + marginModules) * moduleSize,
            moduleSize,
            moduleSize,
          ),
        );
      }
    }
    canvas.drawPath(modules, black);
  }

  @override
  bool shouldRepaint(covariant _OpticalQrPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.devicePixelRatio != devicePixelRatio;
}
