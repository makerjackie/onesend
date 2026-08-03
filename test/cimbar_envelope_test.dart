import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/envelope.dart';
import 'package:onesend/services/cimbar_bridge.dart';

void main() {
  group('CIMBAR CRC32 envelope', () {
    test('round trips UTF-8 filename, MIME and payload', () {
      final original = TransferFile(
        name: '报告 📦.bin',
        mimeType: 'application/octet-stream',
        bytes: Uint8List.fromList(<int>[0, 1, 2, 3, 0xff]),
      );

      final encoded = encodeCimbarEnvelope(original);
      final decoded = decodeCimbarEnvelope(encoded);

      expect(encoded.sublist(0, 4), cimbarEnvelopeMagic);
      expect(encoded[4], cimbarEnvelopeVersion);
      expect(decoded.name, original.name);
      expect(decoded.mimeType, original.mimeType);
      expect(decoded.bytes, orderedEquals(original.bytes));
    });

    test('rejects payload tampering and truncation', () {
      final encoded = encodeCimbarEnvelope(
        TransferFile(
          name: 'notes.txt',
          mimeType: 'text/plain',
          bytes: Uint8List.fromList(<int>[10, 20, 30, 40]),
        ),
      );
      encoded[encoded.length - 1] ^= 0x01;
      expect(() => decodeCimbarEnvelope(encoded), throwsFormatException);

      final valid = encodeCimbarEnvelope(
        TransferFile(
          name: 'notes.txt',
          mimeType: 'text/plain',
          bytes: Uint8List.fromList(<int>[10, 20, 30, 40]),
        ),
      );
      expect(
        () => decodeCimbarEnvelope(
          Uint8List.sublistView(valid, 0, valid.length - 1),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid UTF-8 and non-canonical lengths', () {
      final encoded = encodeCimbarEnvelope(
        TransferFile(
          name: 'file.bin',
          mimeType: 'application/octet-stream',
          bytes: Uint8List.fromList(<int>[1]),
        ),
      );
      encoded[cimbarEnvelopeHeaderBytes] = 0xff;
      expect(() => decodeCimbarEnvelope(encoded), throwsFormatException);

      final lengthTampered = encodeCimbarEnvelope(
        TransferFile(
          name: 'file.bin',
          mimeType: 'application/octet-stream',
          bytes: Uint8List.fromList(<int>[1]),
        ),
      );
      ByteData.sublistView(lengthTampered).setUint32(9, 2, Endian.little);
      expect(() => decodeCimbarEnvelope(lengthTampered), throwsFormatException);
    });

    test('enforces text and 33 MiB envelope safety ceilings', () {
      expect(
        () => encodeCimbarEnvelope(
          TransferFile(
            name: 'bad\u0000name.bin',
            mimeType: 'application/octet-stream',
            bytes: Uint8List(0),
          ),
        ),
        throwsArgumentError,
      );

      final encoded = encodeCimbarEnvelope(
        TransferFile(
          name: 'file.bin',
          mimeType: 'application/octet-stream',
          bytes: Uint8List.fromList(<int>[1]),
        ),
      );
      ByteData.sublistView(
        encoded,
      ).setUint32(9, cimbarMaxPayloadBytes + 1, Endian.little);
      expect(() => decodeCimbarEnvelope(encoded), throwsFormatException);
    });
  });
}
