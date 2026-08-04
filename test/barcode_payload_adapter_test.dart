import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:onesend/core/barcode_payload_adapter.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';
import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/screens/receive_screen.dart';
import 'package:onesend/services/transfer_store.dart';

void main() {
  group('mobile_scanner barcode payload adapter', () {
    test('Android decoded bytes reach OpticalReceiver unchanged', () {
      final frame = _validFrame();
      final result = adaptBarcodePayload(
        Barcode(rawDecodedBytes: DecodedBarcodeBytes(bytes: frame)),
      );

      expect(result.source, BarcodePayloadSource.decoded);
      expect(result.bytes, orderedEquals(frame));
      expect(OpticalReceiver().consume(result.bytes!)?.verified, isTrue);
    });

    test('Apple Vision decoded bytes are preferred over raw payload bytes', () {
      final frame = _validFrame();
      final visionRawPayload = Uint8List.fromList(<int>[0, 1, 2, ...frame, 0]);
      final result = adaptBarcodePayload(
        Barcode(
          rawDecodedBytes: DecodedVisionBarcodeBytes(
            bytes: frame,
            rawBytes: visionRawPayload,
          ),
        ),
      );

      expect(result.source, BarcodePayloadSource.visionDecoded);
      expect(result.bytes, orderedEquals(frame));
      expect(OpticalReceiver().consume(result.bytes!)?.verified, isTrue);
    });

    test('legacy rawBytes is a compatibility fallback', () {
      final frame = _validFrame();
      // ignore: deprecated_member_use
      final barcode = Barcode(rawBytes: frame);
      final result = adaptBarcodePayload(barcode);

      expect(result.source, BarcodePayloadSource.legacyRaw);
      expect(result.bytes, orderedEquals(frame));
      expect(OpticalReceiver().consume(result.bytes!)?.verified, isTrue);
    });

    test(
      'legacy rawBytes is used when Vision decoded bytes are unavailable',
      () {
        final frame = _validFrame();
        final result = adaptBarcodePayload(
          Barcode(
            // ignore: deprecated_member_use
            rawBytes: frame,
            rawDecodedBytes: DecodedVisionBarcodeBytes(
              bytes: null,
              rawBytes: Uint8List.fromList(<int>[0, 1, 2]),
            ),
          ),
        );

        expect(result.source, BarcodePayloadSource.legacyRaw);
        expect(result.bytes, orderedEquals(frame));
      },
    );

    test('Vision raw payload is not mistaken for a decoded OneSend frame', () {
      final result = adaptBarcodePayload(
        Barcode(
          rawDecodedBytes: DecodedVisionBarcodeBytes(
            bytes: null,
            rawBytes: _validFrame(),
          ),
        ),
      );

      expect(result.source, BarcodePayloadSource.unavailable);
      expect(result.bytes, isNull);
    });

    test('invalid decoded frame is rejected by OpticalReceiver', () {
      final invalidFrame = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final result = adaptBarcodePayload(
        Barcode(rawDecodedBytes: DecodedBarcodeBytes(bytes: invalidFrame)),
      );

      expect(result.bytes, orderedEquals(invalidFrame));
      expect(OpticalReceiver().consume(result.bytes!), isNull);
    });

    testWidgets(
      'missing bytes and invalid frames are observable without pausing scan',
      (WidgetTester tester) async {
        final stateKey = GlobalKey<ReceiveScreenState>();
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en', 'US'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: LocaleSupport.supportedLocales,
            home: ReceiveScreen(
              key: stateKey,
              store: TransferStore(),
              cameraBuilder: (_) => const ColoredBox(color: Colors.black),
            ),
          ),
        );

        stateKey.currentState!.handleMobileCaptureForTesting(
          const BarcodeCapture(barcodes: <Barcode>[Barcode()]),
        );
        await tester.pump();
        expect(
          stateKey.currentState!.barcodeObservationForTesting,
          'bytesUnavailable',
        );
        expect(stateKey.currentState!.pausedForTesting, isFalse);
        expect(
          find.byKey(const ValueKey<String>('receive-barcode-observation')),
          findsOneWidget,
        );

        stateKey.currentState!.handleMobileCaptureForTesting(
          BarcodeCapture(
            barcodes: <Barcode>[
              Barcode(
                rawDecodedBytes: DecodedBarcodeBytes(
                  bytes: Uint8List.fromList(<int>[1, 2, 3]),
                ),
              ),
            ],
          ),
        );
        await tester.pump();
        expect(
          stateKey.currentState!.barcodeObservationForTesting,
          'invalidFrame',
        );
        expect(stateKey.currentState!.pausedForTesting, isFalse);
      },
    );
  });
}

Uint8List _validFrame() {
  final payload = Uint8List.fromList(<int>[7, 8, 9, 10]);
  final block = Uint8List(TransferMode.reliable.blockLength)
    ..setRange(0, payload.length, payload);
  return packFrame(
    FrameHeader(
      profileId: TransferMode.reliable.id,
      sessionId: 0x10203040,
      sequence: 0,
      blockCount: 1,
      blockLength: block.length,
      totalLength: payload.length,
      payloadChecksum: crc32(payload),
    ),
    block,
  );
}
