import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/update_manifest.dart';
import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/screens/about_screen.dart';
import 'package:onesend/screens/settings_screen.dart';
import 'package:onesend/services/app_settings.dart';
import 'package:onesend/services/update_service.dart';

void main() {
  testWidgets('settings defaults to fast and shows theoretical KB/s', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings();
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _testApp(SettingsScreen(settings: settings, isDesktop: false)),
    );

    expect(find.text('快速'), findsOneWidget);
    expect(find.textContaining('理论约 33 KB/s'), findsOneWidget);
    expect(find.textContaining('理论约 4.7 KB/s'), findsOneWidget);
    expect(find.textContaining('帧/秒'), findsNothing);
    expect(find.textContaining('FPS'), findsNothing);

    await tester.tap(find.byKey(const ValueKey<String>('settings-reliable')));
    await tester.pumpAndSettle();

    expect(settings.transferMode, TransferMode.reliable);
    expect(find.textContaining('传输更慢'), findsOneWidget);
  });

  testWidgets(
    'language is injectable and mobile hides update network settings',
    (WidgetTester tester) async {
      final settings = AppSettings();
      addTearDown(settings.dispose);
      var languageTapped = false;

      await tester.pumpWidget(
        _testApp(
          SettingsScreen(
            settings: settings,
            updates: _TestUpdateManager(),
            isDesktop: false,
            onLanguageTap: () => languageTapped = true,
          ),
        ),
      );

      expect(find.text('自动更新'), findsNothing);
      await tester.tap(find.byKey(const ValueKey<String>('settings-language')));
      expect(languageTapped, isTrue);
    },
  );

  testWidgets('desktop exposes the existing automatic update entry', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings();
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _testApp(
        SettingsScreen(
          settings: settings,
          updates: _TestUpdateManager(),
          isDesktop: true,
        ),
      ),
    );

    expect(find.text('自动更新'), findsOneWidget);
    expect(find.text('桌面端检查更新与自动检查设置。'), findsOneWidget);
  });

  testWidgets('about screen loads version details and launches GitHub', (
    WidgetTester tester,
  ) async {
    final openedUrls = <Uri>[];
    final packageInfo = PackageInfo(
      appName: 'OneSend',
      packageName: 'com.makerjackie.onesend',
      version: '1.4.0',
      buildNumber: '14',
    );

    await tester.pumpWidget(
      _testApp(
        AboutScreen(
          packageInfoLoader: () async => packageInfo,
          urlLauncher: (url) async {
            openedUrls.add(url);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OneSend'), findsOneWidget);
    expect(find.text('扫传'), findsOneWidget);
    expect(find.text('实验性离线视觉传输'), findsOneWidget);
    expect(find.text('传输不经网络或服务器；移动端只需要相机权限。'), findsOneWidget);
    expect(find.text('MakerJackie / 01MVP'), findsOneWidget);
    expect(find.text('MIT'), findsOneWidget);
    expect(find.text('1.4.0 (14)'), findsOneWidget);
    expect(find.text(oneSendGithubUrl), findsOneWidget);

    final githubButton = find.byKey(const ValueKey<String>('about-github'));
    await tester.ensureVisible(githubButton);
    await tester.tap(githubButton);
    await tester.pumpAndSettle();

    expect(openedUrls, <Uri>[oneSendGithubUri]);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: LocaleSupport.parseTag('zh-Hans'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: LocaleSupport.supportedLocales,
    home: child,
  );
}

class _TestUpdateManager extends UpdateManager {
  @override
  bool get automaticChecksEnabled => true;

  @override
  OneSendUpdateRelease? get availableRelease => null;

  @override
  bool get checking => false;

  @override
  String get currentVersionLabel => '1.4.0 (14)';

  @override
  double? get downloadProgress => null;

  @override
  bool get downloading => false;

  @override
  String? get lastError => null;

  @override
  bool get supportsUpdates => true;

  @override
  Future<UpdateCheckOutcome> checkForUpdates({
    bool userInitiated = true,
  }) async => UpdateCheckOutcome.upToDate;

  @override
  Future<void> downloadAvailableUpdate() async {}

  @override
  Future<void> openReleasePage() async {}

  @override
  Future<void> performStartupCheck() async {}

  @override
  Future<void> setAutomaticChecksEnabled(bool enabled) async {}
}
