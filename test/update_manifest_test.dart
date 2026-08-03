import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/update_manifest.dart';

void main() {
  group('signed update manifest', () {
    test(
      'accepts an authentic release and selects each platform asset',
      () async {
        final fixture = await _signedFixture();

        final release = await parseSignedUpdateManifest(
          fixture.bytes,
          publicKey: fixture.publicKey,
        );

        expect(release.version, '1.3.0');
        expect(release.buildNumber, 9);
        expect(release.notes, <String>['桌面自动更新', '稳定性改进']);
        expect(
          release.assetFor(OneSendDesktopPlatform.macos).fileName,
          'onesend-macos-universal.zip',
        );
        expect(
          release.assetFor(OneSendDesktopPlatform.windows).fileName,
          'onesend-windows-setup.exe',
        );
        expect(
          release.assetFor(OneSendDesktopPlatform.linux).fileName,
          'onesend-linux-x64.tar.gz',
        );
      },
    );

    test('rejects payload tampering after signing', () async {
      final fixture = await _signedFixture();
      final envelope =
          jsonDecode(utf8.decode(fixture.bytes)) as Map<String, dynamic>;
      final payload = base64Decode(envelope['payload'] as String);
      payload[payload.length - 2] ^= 0x01;
      envelope['payload'] = base64Encode(payload);

      await expectLater(
        parseSignedUpdateManifest(
          Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
          publicKey: fixture.publicKey,
        ),
        throwsA(isA<UpdateManifestException>()),
      );
    });

    test('rejects a validly signed asset from another host', () async {
      final fixture = await _signedFixture(
        mutate: (payload) {
          final assets = payload['assets'] as Map<String, Object?>;
          final linux = assets['linux'] as Map<String, Object?>;
          linux['url'] = 'https://example.com/onesend-linux-x64.tar.gz';
        },
      );

      await expectLater(
        parseSignedUpdateManifest(fixture.bytes, publicKey: fixture.publicKey),
        throwsA(
          isA<UpdateManifestException>().having(
            (error) => error.message,
            'message',
            contains('地址'),
          ),
        ),
      );
    });

    test('rejects nested release paths and non-canonical filenames', () async {
      final nestedPath = await _signedFixture(
        mutate: (payload) {
          final assets = payload['assets'] as Map<String, Object?>;
          final linux = assets['linux'] as Map<String, Object?>;
          linux['url'] =
              'https://github.com/makerjackie/onesend/releases/download/'
              'v1.3.0/nested/onesend-linux-x64.tar.gz';
        },
      );
      final renamedFile = await _signedFixture(
        mutate: (payload) {
          final assets = payload['assets'] as Map<String, Object?>;
          final linux = assets['linux'] as Map<String, Object?>;
          linux['url'] =
              'https://github.com/makerjackie/onesend/releases/download/'
              'v1.3.0/onesend-linux-portable.tar.gz';
          linux['fileName'] = 'onesend-linux-portable.tar.gz';
        },
      );

      await expectLater(
        parseSignedUpdateManifest(
          nestedPath.bytes,
          publicKey: nestedPath.publicKey,
        ),
        throwsA(isA<UpdateManifestException>()),
      );
      await expectLater(
        parseSignedUpdateManifest(
          renamedFile.bytes,
          publicKey: renamedFile.publicKey,
        ),
        throwsA(isA<UpdateManifestException>()),
      );
    });

    test('rejects empty or control-character release notes', () async {
      final emptyNote = await _signedFixture(
        mutate: (payload) => payload['notes'] = <String>['   '],
      );
      final multilineNote = await _signedFixture(
        mutate: (payload) => payload['notes'] = <String>['line one\nline two'],
      );

      await expectLater(
        parseSignedUpdateManifest(
          emptyNote.bytes,
          publicKey: emptyNote.publicKey,
        ),
        throwsA(isA<UpdateManifestException>()),
      );
      await expectLater(
        parseSignedUpdateManifest(
          multilineNote.bytes,
          publicKey: multilineNote.publicKey,
        ),
        throwsA(isA<UpdateManifestException>()),
      );
    });

    test(
      'rejects malformed signature fields without leaking type errors',
      () async {
        final malformed = Uint8List.fromList(
          utf8.encode(
            jsonEncode(<String, Object>{
              'schemaVersion': 1,
              'algorithm': 'ed25519',
              'payload': 42,
              'signature': false,
            }),
          ),
        );

        await expectLater(
          parseSignedUpdateManifest(malformed),
          throwsA(isA<UpdateManifestException>()),
        );
      },
    );

    test('rejects signatures and public keys with invalid lengths', () async {
      final fixture = await _signedFixture();
      final envelope =
          jsonDecode(utf8.decode(fixture.bytes)) as Map<String, dynamic>;
      envelope['signature'] = base64Encode(Uint8List(12));

      await expectLater(
        parseSignedUpdateManifest(
          Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
          publicKey: fixture.publicKey,
        ),
        throwsA(isA<UpdateManifestException>()),
      );
    });
  });

  group('update version ordering', () {
    test('compares semantic versions and same-version build numbers', () {
      expect(compareOneSendVersions('1.3.0', '1.2.9'), 1);
      expect(compareOneSendVersions('1.3.0', '1.3.0'), 0);
      expect(compareOneSendVersions('1.2.9', '1.3.0'), -1);

      final release = _releasePayload();
      final parsed = OneSendUpdateRelease.fromJson(release);
      expect(parsed.isNewerThan('1.2.9', 100), isTrue);
      expect(parsed.isNewerThan('1.3.0', 8), isTrue);
      expect(parsed.isNewerThan('1.3.0', 9), isFalse);
      expect(parsed.isNewerThan('1.3.1', 1), isFalse);
    });

    test('rejects non-release version strings', () {
      expect(
        () => compareOneSendVersions('1.3.0-beta', '1.2.0'),
        throwsA(isA<UpdateManifestException>()),
      );
      expect(
        () => compareOneSendVersions('9999999999.0.0', '1.2.0'),
        throwsA(isA<UpdateManifestException>()),
      );
    });
  });
}

Future<({Uint8List bytes, String publicKey})> _signedFixture({
  void Function(Map<String, Object?> payload)? mutate,
}) async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(
    List<int>.generate(32, (index) => index + 1),
  );
  final publicKey = await keyPair.extractPublicKey();
  final payload = _releasePayload();
  mutate?.call(payload);
  final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
  final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);
  final envelope = <String, Object>{
    'schemaVersion': 1,
    'algorithm': 'ed25519',
    'payload': base64Encode(payloadBytes),
    'signature': base64Encode(signature.bytes),
  };
  return (
    bytes: Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
    publicKey: base64Encode(publicKey.bytes),
  );
}

Map<String, Object?> _releasePayload() {
  Map<String, Object> asset(String platform, String suffix, String digest) =>
      <String, Object>{
        'url':
            'https://github.com/makerjackie/onesend/releases/download/v1.3.0/'
            'onesend-$platform-$suffix',
        'fileName': 'onesend-$platform-$suffix',
        'sha256': List<String>.filled(64, digest).join(),
        'length': 12345,
      };

  return <String, Object?>{
    'schemaVersion': 1,
    'version': '1.3.0',
    'buildNumber': 9,
    'publishedAt': '2026-08-03T04:00:00.000Z',
    'releasePage': 'https://github.com/makerjackie/onesend/releases/tag/v1.3.0',
    'notes': <String>['桌面自动更新', '稳定性改进'],
    'assets': <String, Object?>{
      'macos': asset('macos', 'universal.zip', 'a'),
      'windows': asset('windows', 'setup.exe', 'b'),
      'linux': asset('linux', 'x64.tar.gz', 'c'),
    },
  };
}
