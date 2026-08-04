import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/app.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/services/app_settings.dart';
import 'package:onesend/services/file_service.dart';
import 'package:onesend/services/transfer_store.dart';
import 'package:onesend/widgets/stored_file_actions.dart';

void main() {
  testWidgets('send flow opens in fast mode with all four mode entries', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );
    await tester.tap(find.text('发送文件'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey<String>('send-mode-fast')),
          )
          .selected,
      isTrue,
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
    expect(
      find.byKey(const ValueKey<String>('send-sample-video')),
      findsOneWidget,
    );
  });

  testWidgets('settings keeps four modes in a non-blocking mode sheet', (
    WidgetTester tester,
  ) async {
    final settings = AppSettings(initialLocaleTag: 'zh-Hans');
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      OneSendApp(store: TransferStore(), settings: settings),
    );
    await tester.tap(find.byKey(const ValueKey<String>('home-settings')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('settings-transfer-mode')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('settings-reliable')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('settings-fast')), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('settings-turbo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('settings-cimbar')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('settings-turbo')));
    await tester.pumpAndSettle();
    expect(settings.transferAlgorithm, TransferAlgorithm.qr);
    expect(settings.transferMode, TransferMode.turbo);
  });

  testWidgets('stored receive result exposes preview and file actions', (
    WidgetTester tester,
  ) async {
    const path = '/tmp/onesend-ui-flow/received.mp4';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: LocaleSupport.supportedLocales,
        home: Scaffold(
          body: StoredFileActions(
            isDesktop: true,
            pathExists: (_) => SynchronousFuture<bool>(true),
            file: const StoredTransfer(
              name: 'received.mp4',
              mimeType: 'video/mp4',
              bytes: 1024,
              path: path,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('stored-file-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('stored-file-open')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('stored-file-share')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('stored-file-save-as')),
      findsOneWidget,
    );
    expect(find.text('Saved to: $path'), findsOneWidget);
  });
}
