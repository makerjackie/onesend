import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onesend/core/update_manifest.dart';
import 'package:onesend/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'native updater forwards checks and automatic-check preference',
    () async {
      final bridge = _FakeNativeUpdateBridge(automaticChecksEnabled: false);
      final manager = DesktopUpdateManager(
        platform: OneSendDesktopPlatform.macos,
        nativeBridge: bridge,
        packageInfoLoader: () async => _packageInfo(),
      );
      addTearDown(manager.dispose);

      await manager.initialize();
      expect(manager.currentVersionLabel, '1.3.0 (9)');
      expect(manager.automaticChecksEnabled, isFalse);

      expect(
        await manager.checkForUpdates(),
        UpdateCheckOutcome.nativeWindowOpened,
      );
      expect(bridge.checkCalls, 1);

      await manager.setAutomaticChecksEnabled(true);
      expect(manager.automaticChecksEnabled, isTrue);
      expect(bridge.automaticChecksEnabled, isTrue);
    },
  );

  test(
    'native preference failures keep the updater and transfer UI alive',
    () async {
      final bridge = _FailingPreferenceBridge();
      final manager = DesktopUpdateManager(
        platform: OneSendDesktopPlatform.windows,
        nativeBridge: bridge,
        packageInfoLoader: () async => _packageInfo(),
      );
      addTearDown(manager.dispose);

      await manager.initialize();

      expect(manager.currentVersionLabel, '1.3.0 (9)');
      expect(manager.automaticChecksEnabled, isTrue);
      expect(
        await manager.checkForUpdates(),
        UpdateCheckOutcome.nativeWindowOpened,
      );
      expect(bridge.checkCalls, 1);
    },
  );

  test(
    'Linux updater checks, verifies, downloads, and opens an update',
    () async {
      final bytes = Uint8List.fromList(
        List<int>.generate(8192, (index) => (index * 37 + 11) & 0xff),
      );
      final release = _releaseForLinux(bytes: bytes);
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        if (request.url.path.endsWith('/latest.json')) {
          return http.Response('{}', HttpStatus.ok);
        }
        return http.Response.bytes(
          bytes,
          HttpStatus.ok,
          headers: <String, String>{
            HttpHeaders.contentLengthHeader: bytes.length.toString(),
          },
        );
      });
      final downloads = await Directory.systemTemp.createTemp(
        'onesend-update-test-',
      );
      addTearDown(() => downloads.delete(recursive: true));
      String? openedPath;
      final manager = DesktopUpdateManager(
        platform: OneSendDesktopPlatform.linux,
        client: client,
        packageInfoLoader: () async =>
            _packageInfo(version: '1.2.1', buildNumber: '8'),
        manifestParser: (_) async => release,
        downloadsDirectoryLoader: () async => downloads,
        fileOpener: (path) async {
          openedPath = path;
          return true;
        },
      );
      addTearDown(manager.dispose);

      await manager.initialize();
      expect(
        await manager.checkForUpdates(),
        UpdateCheckOutcome.updateAvailable,
      );
      expect(manager.availableRelease, same(release));

      await manager.downloadAvailableUpdate();

      expect(openedPath, isNotNull);
      expect(await File(openedPath!).readAsBytes(), orderedEquals(bytes));
      expect(manager.downloadProgress, 1);
      expect(manager.downloading, isFalse);
      expect(requests, hasLength(2));
      expect(
        downloads.listSync().whereType<File>().any(
          (file) => file.path.endsWith('.part'),
        ),
        isFalse,
      );
    },
  );

  test(
    'Linux updater deletes a package that fails SHA-256 verification',
    () async {
      final bytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
      final release = _releaseForLinux(
        bytes: bytes,
        shaOverride: List<String>.filled(64, '0').join(),
      );
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/latest.json')) {
          return http.Response('{}', HttpStatus.ok);
        }
        return http.Response.bytes(bytes, HttpStatus.ok);
      });
      final downloads = await Directory.systemTemp.createTemp(
        'onesend-bad-update-test-',
      );
      addTearDown(() => downloads.delete(recursive: true));
      final manager = DesktopUpdateManager(
        platform: OneSendDesktopPlatform.linux,
        client: client,
        packageInfoLoader: () async =>
            _packageInfo(version: '1.2.1', buildNumber: '8'),
        manifestParser: (_) async => release,
        downloadsDirectoryLoader: () async => downloads,
      );
      addTearDown(manager.dispose);

      await manager.initialize();
      await manager.checkForUpdates();
      await expectLater(
        manager.downloadAvailableUpdate(),
        throwsA(isA<UpdateManifestException>()),
      );

      expect(downloads.listSync(), isEmpty);
      expect(manager.lastError, contains('SHA-256'));
    },
  );

  test(
    'Linux updater reports when neither the package nor release page opens',
    () async {
      final bytes = Uint8List.fromList(<int>[7, 8, 9]);
      final release = _releaseForLinux(bytes: bytes);
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/latest.json')) {
          return http.Response('{}', HttpStatus.ok);
        }
        return http.Response.bytes(bytes, HttpStatus.ok);
      });
      final downloads = await Directory.systemTemp.createTemp(
        'onesend-open-update-test-',
      );
      addTearDown(() => downloads.delete(recursive: true));
      final manager = DesktopUpdateManager(
        platform: OneSendDesktopPlatform.linux,
        client: client,
        packageInfoLoader: () async =>
            _packageInfo(version: '1.2.1', buildNumber: '8'),
        manifestParser: (_) async => release,
        downloadsDirectoryLoader: () async => downloads,
        fileOpener: (_) async => false,
        externalUrlLauncher: (_) async => false,
      );
      addTearDown(manager.dispose);

      await manager.initialize();
      await manager.checkForUpdates();
      await expectLater(manager.downloadAvailableUpdate(), throwsStateError);

      expect(manager.lastError, contains('无法打开'));
      expect(
        downloads.listSync().whereType<File>().single.path,
        endsWith('onesend-linux-x64.tar.gz'),
      );
    },
  );

  test('Linux automatic check is throttled to once per 24 hours', () async {
    var now = DateTime.utc(2026, 8, 3, 4);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'desktop_update_last_check': now
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    });
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response('{}', HttpStatus.ok);
    });
    final manager = DesktopUpdateManager(
      platform: OneSendDesktopPlatform.linux,
      client: client,
      packageInfoLoader: () async => _packageInfo(),
      manifestParser: (_) async => _releaseForLinux(
        bytes: Uint8List.fromList(<int>[1]),
        version: '1.3.0',
        buildNumber: 9,
      ),
      clock: () => now,
    );
    addTearDown(manager.dispose);

    await manager.initialize();
    await manager.performStartupCheck();
    expect(requestCount, 0);

    now = now.add(const Duration(hours: 25));
    await manager.performStartupCheck();
    expect(requestCount, 1);
  });

  test(
    'release-page launch failures become a user-facing updater error',
    () async {
      final manager = DesktopUpdateManager(
        platform: OneSendDesktopPlatform.linux,
        packageInfoLoader: () async => _packageInfo(),
        externalUrlLauncher: (_) async => false,
      );
      addTearDown(manager.dispose);
      await manager.initialize();

      await expectLater(manager.openReleasePage(), throwsStateError);
      expect(manager.lastError, '无法打开下载页面。');
    },
  );
}

PackageInfo _packageInfo({
  String version = '1.3.0',
  String buildNumber = '9',
}) => PackageInfo(
  appName: 'OneSend',
  packageName: 'com.makerjackie.onesend',
  version: version,
  buildNumber: buildNumber,
);

OneSendUpdateRelease _releaseForLinux({
  required Uint8List bytes,
  String? shaOverride,
  String version = '1.3.0',
  int buildNumber = 9,
}) {
  final releaseUrl = Uri.parse(
    'https://github.com/makerjackie/onesend/releases/tag/v$version',
  );
  OneSendUpdateAsset asset(String platform, String fileName) =>
      OneSendUpdateAsset(
        url: Uri.parse(
          'https://github.com/makerjackie/onesend/releases/download/v$version/'
          '$fileName',
        ),
        fileName: fileName,
        sha256: platform == 'linux'
            ? (shaOverride ?? sha256.convert(bytes).toString())
            : List<String>.filled(64, '0').join(),
        length: platform == 'linux' ? bytes.length : 1,
      );

  return OneSendUpdateRelease(
    version: version,
    buildNumber: buildNumber,
    publishedAt: DateTime.utc(2026, 8, 3, 4),
    releasePage: releaseUrl,
    notes: const <String>['稳定更新'],
    assets: <String, OneSendUpdateAsset>{
      'macos': asset('macos', 'onesend-macos-universal.zip'),
      'windows': asset('windows', 'onesend-windows-setup.exe'),
      'linux': asset('linux', 'onesend-linux-x64.tar.gz'),
    },
  );
}

class _FakeNativeUpdateBridge implements NativeUpdateBridge {
  _FakeNativeUpdateBridge({required this.automaticChecksEnabled});

  bool automaticChecksEnabled;
  int checkCalls = 0;

  @override
  Future<void> checkForUpdates() async {
    checkCalls++;
  }

  @override
  Future<bool> getAutomaticChecksEnabled() async => automaticChecksEnabled;

  @override
  Future<void> setAutomaticChecksEnabled(bool enabled) async {
    automaticChecksEnabled = enabled;
  }
}

class _FailingPreferenceBridge implements NativeUpdateBridge {
  int checkCalls = 0;

  @override
  Future<void> checkForUpdates() async {
    checkCalls++;
  }

  @override
  Future<bool> getAutomaticChecksEnabled() {
    throw MissingPluginException('preference bridge unavailable');
  }

  @override
  Future<void> setAutomaticChecksEnabled(bool enabled) async {}
}
