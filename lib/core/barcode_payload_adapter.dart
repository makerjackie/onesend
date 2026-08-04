import 'dart:typed_data';

import 'package:mobile_scanner/mobile_scanner.dart';

/// Identifies which mobile_scanner field supplied a barcode payload.
enum BarcodePayloadSource {
  /// Bytes decoded by ML Kit on Android (and by the web backends).
  decoded,

  /// Bytes decoded by the Apple Vision QR payload parser.
  visionDecoded,

  /// Bytes supplied through mobile_scanner's deprecated `Barcode.rawBytes`.
  legacyRaw,

  /// The native scanner reported a barcode, but no usable bytes were exposed.
  unavailable,
}

/// The byte payload extracted from a native barcode result.
final class BarcodePayload {
  const BarcodePayload({required this.source, this.bytes});

  final Uint8List? bytes;
  final BarcodePayloadSource source;

  bool get isAvailable => bytes != null;
}

/// Adapts mobile_scanner 7.4.0's platform-specific barcode byte models to the
/// byte stream consumed by [OpticalReceiver].
///
/// On Apple platforms, [DecodedVisionBarcodeBytes.rawBytes] includes the
/// Vision payload header/padding and must not be passed to the OneSend frame
/// parser. If Vision cannot produce [DecodedVisionBarcodeBytes.bytes], the
/// deprecated `Barcode.rawBytes` is the only safe compatibility fallback.
BarcodePayload adaptBarcodePayload(Barcode barcode) {
  final decoded = barcode.rawDecodedBytes;
  if (decoded is DecodedBarcodeBytes) {
    return BarcodePayload(
      bytes: decoded.bytes,
      source: BarcodePayloadSource.decoded,
    );
  }
  if (decoded is DecodedVisionBarcodeBytes && decoded.bytes != null) {
    return BarcodePayload(
      bytes: decoded.bytes,
      source: BarcodePayloadSource.visionDecoded,
    );
  }

  // mobile_scanner 7.2+ still populates this deprecated field from native
  // rawBytes. It also keeps older integrations testable and working when a
  // platform result does not expose rawDecodedBytes.
  // ignore: deprecated_member_use
  final legacyBytes = barcode.rawBytes;
  if (legacyBytes != null) {
    return BarcodePayload(
      bytes: legacyBytes,
      source: BarcodePayloadSource.legacyRaw,
    );
  }

  return const BarcodePayload(source: BarcodePayloadSource.unavailable);
}
