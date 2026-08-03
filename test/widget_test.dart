import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/app.dart';
import 'package:onesend/core/update_manifest.dart';
import 'package:onesend/services/transfer_store.dart';
import 'package:onesend/services/update_service.dart';
import 'package:onesend/widgets/optical_qr.dart';

void main() {
  testWidgets('shows the OneSend home screen', (WidgetTester tester) async {
    await tester.pumpWidget(OneSendApp(store: TransferStore()));

    expect(find.text('OneSend'), findsOneWidget);
    expect(find.text('发送文件'), findsOneWidget);
    expect(find.text('扫描接收'), findsOneWidget);
  });

  testWidgets('send screen offers reliable and fast modes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(OneSendApp(store: TransferStore()));
    await tester.tap(find.text('发送文件'));
    await tester.pumpAndSettle();

    expect(find.text('可靠'), findsOneWidget);
    expect(find.text('快速'), findsOneWidget);
    expect(find.textContaining('8 帧/秒'), findsOneWidget);

    await tester.tap(find.text('快速'));
    await tester.pumpAndSettle();

    expect(find.textContaining('24 帧/秒'), findsOneWidget);
    expect(find.textContaining('32 KB/s'), findsOneWidget);
  });

  testWidgets('picking a file starts the send flow without unsendable state', (
    WidgetTester tester,
  ) async {
    final previousPicker = _currentFilePickerOrNull();
    final bytes = Uint8List.fromList(List<int>.filled(12000, 0x41));
    FilePicker.platform = _FakeFilePicker(
      FilePickerResult(<PlatformFile>[
        PlatformFile(name: 'fixture.txt', size: bytes.length, bytes: bytes),
      ]),
    );
    addTearDown(() {
      if (previousPicker != null) FilePicker.platform = previousPicker;
    });

    await tester.pumpWidget(OneSendApp(store: TransferStore()));
    await tester.tap(find.text('发送文件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择文件'));
    await tester.pump();
    for (
      var attempt = 0;
      attempt < 20 && find.text('fixture.txt').evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(find.text('fixture.txt'), findsOneWidget);
    expect(find.byType(OpticalQr), findsOneWidget);
    expect(find.textContaining('unsendable'), findsNothing);
    expect(find.textContaining('Invalid argument'), findsNothing);
  });

  testWidgets('desktop menu exposes version and automatic update setting', (
    WidgetTester tester,
  ) async {
    final updates = _FakeUpdateManager();
    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), updates: updates),
    );

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('关于 OneSend'), findsOneWidget);

    await tester.tap(find.text('关于 OneSend'));
    await tester.pumpAndSettle();
    expect(find.text('OneSend · 扫传'), findsOneWidget);
    expect(find.text('1.3.0 (9)'), findsOneWidget);
    expect(find.text('自动检查更新'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(updates.automaticChecksEnabled, isFalse);
  });

  testWidgets('available desktop update shows notes and starts download', (
    WidgetTester tester,
  ) async {
    final updates = _FakeUpdateManager(availableRelease: _widgetRelease());
    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), updates: updates),
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

FilePicker? _currentFilePickerOrNull() {
  try {
    return FilePicker.platform;
  } on Object {
    return null;
  }
}

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this._result);

  final FilePickerResult _result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return _result;
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
