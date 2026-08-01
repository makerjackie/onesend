import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class OpticalQr extends StatelessWidget {
  const OpticalQr({required this.bytes, this.size = 320, super.key});

  final Uint8List bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final payload = QrPayload.fromTypedData(bytes);
    final code = QrCode(
      payload: payload,
      errorCorrectLevel: QrErrorCorrectLevel.low,
    );
    final image = QrImage(code);
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _OpticalQrPainter(image),
          size: Size.square(size),
        ),
      ),
    );
  }
}

class _OpticalQrPainter extends CustomPainter {
  _OpticalQrPainter(this.image);

  final QrImage image;

  @override
  void paint(Canvas canvas, Size size) {
    const marginModules = 4;
    final totalModules = image.moduleCount + marginModules * 2;
    final moduleSize = size.shortestSide / totalModules;
    final white = Paint()..color = Colors.white;
    final black = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, white);
    for (var row = 0; row < image.moduleCount; row++) {
      for (var column = 0; column < image.moduleCount; column++) {
        if (!image.isDark(row, column)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (column + marginModules) * moduleSize,
            (row + marginModules) * moduleSize,
            moduleSize + 0.2,
            moduleSize + 0.2,
          ),
          black,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OpticalQrPainter oldDelegate) =>
      oldDelegate.image != image;
}
