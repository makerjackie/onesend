import 'package:flutter/material.dart';

import '../app.dart';

const String oneSendBrandIconAsset = 'assets/brand/onesend-icon-1024.png';
const String oneSendBrandName = 'OneSend';

/// The shared OneSend product icon.
class BrandIcon extends StatelessWidget {
  const BrandIcon({required this.size, this.borderRadius, super.key});

  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? size * 0.2),
      child: Image.asset(
        oneSendBrandIconAsset,
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: oneSendInk,
            alignment: Alignment.center,
            child: Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white,
              size: size * 0.55,
            ),
          );
        },
      ),
    );
  }
}

/// Product mark: official app icon + wordmark.
///
/// Prefer the branded raster icon over a re-drawn silhouette so the home
/// header matches the App Store / desktop launcher artwork.
class BrandMark extends StatelessWidget {
  const BrandMark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 42.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandIcon(size: size, borderRadius: compact ? 7 : 9),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Text(
            oneSendBrandName,
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
