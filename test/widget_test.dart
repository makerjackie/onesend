import 'package:file_selector/file_selector.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart'
    show FileSelectorPlatform, SaveDialogOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/app.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/update_manifest.dart';
import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/services/app_settings.dart';
import 'package:onesend/services/file_service.dart';
import 'package:onesend/services/sample_file_service.dart';
import 'package:onesend/services/transfer_store.dart';
import 'package:onesend/services/update_service.dart';
import 'package:onesend/widgets/optical_qr.dart';
import 'package:onesend/widgets/stored_file_actions.dart';

void main() {
  testWidgets('shows the OneSend home screen', (WidgetTester tester) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );

    expect(find.text('OneSend'), findsOneWidget);
    expect(find.text('发送文件'), findsOneWidget);
    expect(find.text('接收文件'), findsOneWidget);
  });

  testWidgets('new sends expose transfer mode chips without FPS copy', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );
    await tester.tap(find.text('发送文件'));
    await tester.pumpAndSettle();

    expect(find.text('传输模式'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('send-mode-fast')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('send-mode-reliable')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('send-mode-turbo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('send-mode-cimbar')),
      findsOneWidget,
    );
    expect(find.byType(SegmentedButton<TransferMode>), findsNothing);
    expect(find.textContaining('FPS'), findsNothing);
    expect(find.textContaining('帧/秒'), findsNothing);
    expect(find.textContaining('新传输默认使用'), findsNothing);
  });

  testWidgets('picking a file starts the send flow without unsendable state', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    final bytes = Uint8List.fromList(List<int>.filled(12000, 0x41));
    final fakeSelector = _FakeFileSelector(
      file: XFile.fromData(
        bytes,
        name: 'fixture.txt',
        mimeType: 'text/plain',
        path: '/tmp/fixture.txt',
      ),
    );
    final previousSelector = FileSelectorPlatform.instance;
    FileSelectorPlatform.instance = fakeSelector;
    addTearDown(() => FileSelectorPlatform.instance = previousSelector);

    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );
    await tester.tap(find.text('发送文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('send-pick-file')));
    await _pumpUntil(
      tester,
      () => find.text('fixture.txt').evaluate().isNotEmpty,
    );

    expect(find.text('fixture.txt'), findsOneWidget);
    expect(find.byType(OpticalQr), findsOneWidget);
    expect(find.textContaining('unsendable'), findsNothing);
    expect(find.textContaining('Invalid argument'), findsNothing);
    expect(fakeSelector.openedTypeGroups, hasLength(1));
    expect(fakeSelector.openedTypeGroups!.single.label, 'All files');
    expect(fakeSelector.openedTypeGroups!.single.allowsAny, isTrue);
  });

  testWidgets('bundled sample video can trigger the same send flow', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );
    await tester.tap(find.text('发送文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('send-sample-video')));
    await _pumpUntil(
      tester,
      () => find.text(sampleVideoFileName).evaluate().isNotEmpty,
    );

    expect(find.text(sampleVideoFileName), findsOneWidget);
    expect(find.textContaining('122.5 KB'), findsOneWidget);
    expect(find.byType(OpticalQr), findsOneWidget);
    expect(find.textContaining('Invalid argument'), findsNothing);
  });

  testWidgets('settings tab contains updates and nested about page', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = previousPlatform;
    });

    try {
      final updates = _FakeUpdateManager();
      await tester.pumpWidget(
        OneSendApp(
          store: TransferStore(),
          settings: settings,
          updates: updates,
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('home-tab-settings')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
      expect(find.text('检查更新'), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('home-tab-settings')));
      await tester.pumpAndSettle();
      expect(find.text('自动更新'), findsOneWidget);
      final updateEntry = find.byKey(
        const ValueKey<String>('settings-updates'),
      );
      await tester.ensureVisible(updateEntry);
      await tester.tap(updateEntry);
      await tester.pumpAndSettle();
      expect(find.text('自动检查更新'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(updates.automaticChecksEnabled, isFalse);
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('settings-about')));
      await tester.pumpAndSettle();
      expect(find.text('实验性离线视觉传输'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });

  testWidgets(
    'received-file action panel shows location and adaptive actions',
    (WidgetTester tester) async {
      const filePath = '/tmp/onesend-widget/received.txt';

      await tester.pumpWidget(
        MaterialApp(
          locale: LocaleSupport.parseTag('zh-Hans'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: LocaleSupport.supportedLocales,
          home: Scaffold(
            body: StoredFileActions(
              isDesktop: true,
              pathExists: (_) => SynchronousFuture<bool>(true),
              file: StoredTransfer(
                name: 'received.txt',
                mimeType: 'text/plain',
                bytes: 8,
                path: filePath,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('保存位置'), findsOneWidget);
      expect(find.textContaining(filePath), findsOneWidget);
      expect(find.text('打开'), findsOneWidget);
      expect(find.text('分享 / 转发'), findsOneWidget);
      expect(find.text('保存副本'), findsOneWidget);
      expect(find.text('在文件夹中显示'), findsOneWidget);
    },
  );

  testWidgets('available desktop update shows notes and starts download', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    final updates = _FakeUpdateManager(availableRelease: _widgetRelease());
    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings, updates: updates),
    );
    await tester.pumpAndSettle();

    expect(find.text('OneSend 1.3.1 可用'), findsOneWidget);
    expect(find.text('更新安装与传输回归测试'), findsOneWidget);

    await tester.tap(find.text('下载更新'));
    await tester.pumpAndSettle();
    expect(updates.downloadCalls, 1);
    expect(find.text('OneSend 1.3.1 可用'), findsNothing);
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 40 && !condition(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

class _FakeFileSelector extends FileSelectorPlatform {
  _FakeFileSelector({this.file});

  final XFile? file;
  List<XTypeGroup>? openedTypeGroups;
  SaveDialogOptions? saveOptions;

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    openedTypeGroups = acceptedTypeGroups;
    return file;
  }

  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async {
    saveOptions = options;
    return null;
  }
}

class _FakeUpdateManager extends UpdateManager {
  _FakeUpdateManager({this.availableRelease});

  bool _automaticChecksEnabled = true;
  int downloadCalls = 0;

  @override
  bool get automaticChecksEnabled => _automaticChecksEnabled;

  @override
  final OneSendUpdateRelease? availableRelease;

  @override
  bool get checking => false;

  @override
  String get currentVersionLabel => '1.3.0 (9)';

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
  }) async => UpdateCheckOutcome.nativeWindowOpened;

  @override
  Future<void> downloadAvailableUpdate() async {
    downloadCalls++;
  }

  @override
  Future<void> openReleasePage() async {}

  @override
  Future<void> performStartupCheck() async {}

  @override
  Future<void> setAutomaticChecksEnabled(bool enabled) async {
    _automaticChecksEnabled = enabled;
    notifyListeners();
  }
}

OneSendUpdateRelease _widgetRelease() {
  OneSendUpdateAsset asset(String fileName) => OneSendUpdateAsset(
    url: Uri.parse(
      'https://github.com/makerjackie/onesend/releases/download/v1.3.1/'
      '$fileName',
    ),
    fileName: fileName,
    sha256: List<String>.filled(64, '0').join(),
    length: 1,
  );

  return OneSendUpdateRelease(
    version: '1.3.1',
    buildNumber: 10,
    publishedAt: DateTime.utc(2026, 8, 4),
    releasePage: Uri.parse(
      'https://github.com/makerjackie/onesend/releases/tag/v1.3.1',
    ),
    notes: const <String>['更新安装与传输回归测试'],
    assets: <String, OneSendUpdateAsset>{
      'macos': asset('onesend-macos-universal.zip'),
      'windows': asset('onesend-windows-setup.exe'),
      'linux': asset('onesend-linux-x64.tar.gz'),
    },
  );
}
