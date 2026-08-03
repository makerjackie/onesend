import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/app.dart';
import 'package:onesend/services/transfer_store.dart';
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
