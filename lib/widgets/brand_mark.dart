import 'package:flutter/material.dart';

import '../app.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          child: const CustomPaint(painter: _TransferMarkPainter()),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Text(
            'OneSend',
            style: TextStyle(
              color: oneSendInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _TransferMarkPainter extends CustomPainter {
  const _TransferMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final offset = Offset((size.width - side) / 2, (size.height - side) / 2);
    final scale = side / 1024;
    final black = Paint()..color = oneSendInk;
    final white = Paint()..color = Colors.white;

    canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, side, side), black);

    Offset point(double x, double y) => offset + Offset(x * scale, y * scale);
    double sx(double x) => offset.dx + x * scale;
    double sy(double y) => offset.dy + y * scale;

    void rect(double x, double y, double width, double height, Paint paint) {
      canvas.drawRect(
        Rect.fromPoints(point(x, y), point(x + width, y + height)),
        paint,
      );
    }

    rect(160, 400, 224, 224, white);
    rect(224, 464, 96, 96, black);
    rect(416, 480, 80, 80, white);
    rect(512, 416, 80, 80, white);
    rect(608, 352, 80, 80, white);

    Path arrow(double innerOffset) {
      return Path()
        ..moveTo(sx(608 + innerOffset), sy(240 + innerOffset))
        ..lineTo(sx(704 - innerOffset), sy(240 + innerOffset))
        ..lineTo(sx(848 - innerOffset), sy(512))
        ..lineTo(sx(704 - innerOffset), sy(784 - innerOffset))
        ..lineTo(sx(608 + innerOffset), sy(784 - innerOffset))
        ..lineTo(sx(752), sy(512))
        ..close();
    }

    canvas.drawPath(arrow(0), white);
    canvas.drawPath(
      Path()
        ..moveTo(sx(656), sy(368))
        ..lineTo(sx(688), sy(368))
        ..lineTo(sx(768), sy(512))
        ..lineTo(sx(688), sy(656))
        ..lineTo(sx(656), sy(656))
        ..lineTo(sx(736), sy(512))
        ..close(),
      black,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
