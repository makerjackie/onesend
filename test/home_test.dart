import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/app.dart';
import 'package:onesend/screens/about_screen.dart';
import 'package:onesend/screens/receive_screen.dart';
import 'package:onesend/screens/send_screen.dart';
import 'package:onesend/services/app_settings.dart';
import 'package:onesend/services/transfer_store.dart';

void main() {
  testWidgets('mobile shell exposes transfer, files, and settings tabs', (
    WidgetTester tester,
  ) async {
    _setMobileSurface(tester);

    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('传输'), findsOneWidget);
    expect(find.text('发送文件'), findsOneWidget);
    expect(find.text('接收文件'), findsOneWidget);
    expect(find.text('最近传输'), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
  });

  testWidgets(
    'files and settings are separate tabs and about is nested in settings',
    (WidgetTester tester) async {
      _setMobileSurface(tester);

      final settings = AppSettings(initialLocaleTag: 'zh-Hans');
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        OneSendApp(store: TransferStore(), settings: settings),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('文件'));
      await tester.pumpAndSettle();
      expect(find.text('管理传输记录和已接收文件。'), findsOneWidget);
      expect(find.text('最近传输'), findsNothing);

      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('settings-theme')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('settings-about')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('settings-about')));
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
    },
  );

  testWidgets('transfer entries open independent send and receive screens', (
    WidgetTester tester,
  ) async {
    _setMobileSurface(tester);

    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-send')));
    await tester.pumpAndSettle();
    expect(find.byType(SendScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(SendScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('home-receive')));
    // A live camera surface intentionally keeps scheduling frames, especially
    // on Linux desktop. Advance the route animation without waiting for a
    // continuously running preview to become idle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(ReceiveScreen), findsOneWidget);
  });
}

void _setMobileSurface(WidgetTester tester) {
  final view = tester.view;
  final oldSize = view.physicalSize;
  final oldDevicePixelRatio = view.devicePixelRatio;
  view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(() {
    view
      ..physicalSize = oldSize
      ..devicePixelRatio = oldDevicePixelRatio;
  });
}
