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
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: oneSendInk,
            borderRadius: BorderRadius.circular(compact ? 11 : 14),
          ),
          alignment: Alignment.center,
          child: const Text(
            '1',
            style: TextStyle(
              color: oneSendLime,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
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
