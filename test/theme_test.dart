import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/app.dart';
import 'package:onesend/screens/home_screen.dart';
import 'package:onesend/services/app_settings.dart';
import 'package:onesend/services/transfer_store.dart';

void main() {
  testWidgets('theme setting switches the app to dark mode', (
    WidgetTester tester,
  ) async {
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

    final settings = AppSettings(
      initialLocaleTag: 'zh-Hans',
      initialThemeMode: ThemeMode.light,
    );
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      Brightness.light,
    );

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('settings-theme')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('theme-dark')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('theme-dark')));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(HomeScreen))).brightness,
      Brightness.dark,
    );
  });
}
