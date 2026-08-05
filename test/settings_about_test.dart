import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:onesend/core/release_info.dart';
import 'package:onesend/core/update_manifest.dart';
import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/screens/about_screen.dart';
import 'package:onesend/screens/settings_screen.dart';
import 'package:onesend/services/app_settings.dart';
import 'package:onesend/services/update_service.dart';

void main() {
  testWidgets('settings no longer hosts transfer mode pickers', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings();
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _testApp(
        SettingsScreen(
          settings: settings,
          isDesktop: false,
          packageInfoLoader: () async => PackageInfo(
            appName: 'OneSend',
            packageName: 'com.makerjackie.onesend',
            version: '1.5.4',
            buildNumber: '23',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('应用设置'), findsOneWidget);
    expect(find.textContaining('发送页'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('settings-fast')), findsNothing);
    expect(find.byKey(const ValueKey<String>('settings-cimbar')), findsNothing);
    expect(find.text('语言'), findsOneWidget);
    expect(find.text('主题'), findsOneWidget);
    expect(find.text('问题反馈'), findsOneWidget);
    expect(find.text('关于 OneSend'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('settings-version-footer')),
      findsOneWidget,
    );
    expect(find.text('1.5.4（2026-08-05 10:43）'), findsOneWidget);
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
      final languageEntry = find.byKey(
        const ValueKey<String>('settings-language'),
      );
      await tester.ensureVisible(languageEntry);
      await tester.tap(languageEntry);
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
          releaseInfo: const OneSendReleaseInfo(
            version: '1.5.2',
            publishedAt: '2026-08-04 21:30',
          ),
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
    expect(find.text('1.4.0（2026-08-04 21:30）'), findsOneWidget);
    expect(find.text('开源致谢'), findsOneWidget);
    expect(find.textContaining('decimen-optical-transfer'), findsOneWidget);
    expect(find.textContaining('libcimbar'), findsOneWidget);

    final githubButton = find.byKey(const ValueKey<String>('about-github'));
    await tester.ensureVisible(githubButton);
    await tester.tap(githubButton);
    await tester.pumpAndSettle();

    expect(openedUrls, isNotEmpty);
    expect(openedUrls.last.toString(), oneSendGithubUrl);

    final feedbackButton = find.byKey(const ValueKey<String>('about-feedback'));
    await tester.ensureVisible(feedbackButton);
    await tester.tap(feedbackButton);
    await tester.pumpAndSettle();

    expect(openedUrls.last.toString(), oneSendGithubNewIssueUrl);
  });

  testWidgets('settings feedback opens GitHub new issue', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings();
    addTearDown(settings.dispose);
    final openedUrls = <Uri>[];

    await tester.pumpWidget(
      _testApp(
        SettingsScreen(
          settings: settings,
          isDesktop: false,
          packageInfoLoader: () async => PackageInfo(
            appName: 'OneSend',
            packageName: 'com.makerjackie.onesend',
            version: '1.5.4',
            buildNumber: '23',
          ),
          urlLauncher: (url) async {
            openedUrls.add(url);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final feedback = find.byKey(const ValueKey<String>('settings-feedback'));
    await tester.ensureVisible(feedback);
    await tester.tap(feedback);
    await tester.pumpAndSettle();

    expect(openedUrls.single.toString(), oneSendGithubNewIssueUrl);
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
