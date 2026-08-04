import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/screens/receive_screen.dart';
import 'package:onesend/services/transfer_store.dart';

void main() {
  testWidgets(
    'mobile receive scanning stays fixed and keeps its focus controls',
    (WidgetTester tester) async {
      addTearDown(tester.view.reset);

      const sizes = <Size>[Size(360, 800), Size(390, 844)];
      for (final size in sizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;

        await tester.pumpWidget(_receiveLayoutTestApp());
        await tester.pump();

        expect(find.byType(SingleChildScrollView), findsNothing);
        for (final key in <Key>[
          const ValueKey<String>('receive-camera-frame'),
          const ValueKey<String>('receive-scan-readout'),
          const ValueKey<String>('receive-progress-percent'),
          const ValueKey<String>('receive-current-rate'),
          const ValueKey<String>('receive-scan-control'),
        ]) {
          expect(find.byKey(key), findsOneWidget);
          _expectInsideViewport(tester, find.byKey(key), size);
        }
        expect(
          find.byKey(const ValueKey<String>('receive-mode-menu')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('receive-mode-qr')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);

        if (size == sizes.first) {
          await tester.tap(
            find.byKey(const ValueKey<String>('receive-mode-menu')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey<String>('receive-mode-qr')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey<String>('receive-mode-cimbar')),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey<String>('receive-mode-qr')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey<String>('receive-mode-qr')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}

Widget _receiveLayoutTestApp() {
  return MaterialApp(
    locale: const Locale('en', 'US'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: LocaleSupport.supportedLocales,
    home: ReceiveScreen(
      store: TransferStore(),
      cameraBuilder: (_) => const ColoredBox(color: Colors.black),
    ),
  );
}

void _expectInsideViewport(WidgetTester tester, Finder finder, Size viewport) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(viewport.width));
  expect(rect.bottom, lessThanOrEqualTo(viewport.height));
}
