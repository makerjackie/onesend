import 'package:flutter/material.dart';

import '../app.dart';

/// Canonical C3 raster mark (file + QR + scan corners + scan line).
/// Source of truth: `assets/brand/onesend-file-scan-mark.png`.
const String oneSendBrandSourceAsset =
    'assets/brand/onesend-file-scan-mark.png';

/// Opaque warm off-white app icon generated from [oneSendBrandSourceAsset].
const String oneSendBrandIconAsset = 'assets/brand/onesend-icon-1024.png';
const String oneSendBrandName = 'OneSend';

/// The shared OneSend product icon.
class BrandIcon extends StatelessWidget {
  const BrandIcon({required this.size, this.borderRadius, super.key});

  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius ?? size * 0.2);
    return ClipRRect(
      borderRadius: radius,
      child: ColoredBox(
        color: oneSendPaper,
        child: Image.asset(
          oneSendBrandIconAsset,
          width: size,
          height: size,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: oneSendInk,
                  size: size * 0.55,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Product mark: official app icon + wordmark.
///
/// Prefer the generated raster icon over a re-drawn silhouette so the home
/// header matches the App Store / desktop launcher artwork. The light plate
/// keeps the black file visible when this mark is placed on dark UI chrome.
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
