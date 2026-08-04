import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onesend/app.dart';
import 'package:onesend/core/envelope.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/screens/receive_screen.dart';
import 'package:onesend/services/app_settings.dart';
import 'package:onesend/services/file_service.dart';
import 'package:onesend/services/transfer_store.dart';
import 'package:onesend/widgets/stored_file_actions.dart';

void main() {
  testWidgets('send flow opens with QR + color modes only', (
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
            find.byKey(const ValueKey<String>('send-mode-qr')),
          )
          .selected,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey<String>('send-mode-fast')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('send-mode-reliable')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('send-mode-turbo')),
      findsNothing,
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
    await tester.tap(find.byKey(const ValueKey<String>('home-tab-settings')));
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

  testWidgets(
    'verified QR payload decodes and saves once before showing file actions',
    (WidgetTester tester) async {
      final store = _FailingTransferStore();
      final stateKey = GlobalKey<ReceiveScreenState>();
      final decodeCompleter = Completer<TransferFile>();
      var decodeCalls = 0;
      var saveCalls = 0;
      final decodedFile = TransferFile(
        name: 'verified.txt',
        mimeType: 'text/plain',
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
      );
      const stored = StoredTransfer(
        name: 'verified.txt',
        mimeType: 'text/plain',
        bytes: 3,
        path: '/tmp/onesend-ui-flow/verified.txt',
      );

      await tester.pumpWidget(
        _receiveTestApp(
          ReceiveScreen(
            key: stateKey,
            store: store,
            cameraBuilder: (_) => const ColoredBox(color: Colors.black),
            payloadDecoder: (payload) {
              decodeCalls++;
              return decodeCompleter.future;
            },
            receivedFileSaver: (file) async {
              saveCalls++;
              expect(file, same(decodedFile));
              return stored;
            },
          ),
        ),
      );

      final state = stateKey.currentState!;
      final first = state.acceptVerifiedPayloadForTesting(
        Uint8List.fromList(<int>[7, 8, 9]),
      );
      final duplicate = state.acceptVerifiedPayloadForTesting(
        Uint8List.fromList(<int>[7, 8, 9]),
      );
      expect(decodeCalls, 1);

      decodeCompleter.complete(decodedFile);
      await Future.wait(<Future<void>>[first, duplicate]);
      await tester.pumpAndSettle();

      expect(decodeCalls, 1);
      expect(saveCalls, 1);
      expect(store.addCalls, 1);
      expect(find.textContaining('history record'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('stored-file-actions')),
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
    },
  );

  testWidgets('failed save retries without rescanning and then shows actions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = TransferStore();
    await store.init();
    final stateKey = GlobalKey<ReceiveScreenState>();
    var decodeCalls = 0;
    var saveCalls = 0;
    final decodedFile = TransferFile(
      name: 'retry.txt',
      mimeType: 'text/plain',
      bytes: Uint8List.fromList(<int>[4, 5, 6]),
    );
    const stored = StoredTransfer(
      name: 'retry.txt',
      mimeType: 'text/plain',
      bytes: 3,
      path: '/tmp/onesend-ui-flow/retry.txt',
    );

    await tester.pumpWidget(
      _receiveTestApp(
        ReceiveScreen(
          key: stateKey,
          store: store,
          cameraBuilder: (_) => const ColoredBox(color: Colors.black),
          payloadDecoder: (payload) async {
            decodeCalls++;
            return decodedFile;
          },
          receivedFileSaver: (file) async {
            saveCalls++;
            if (saveCalls == 1) throw StateError('disk full');
            return stored;
          },
        ),
      ),
    );

    await stateKey.currentState!.acceptVerifiedPayloadForTesting(
      Uint8List.fromList(<int>[1]),
    );
    await tester.pumpAndSettle();

    expect(decodeCalls, 1);
    expect(saveCalls, 1);
    expect(find.textContaining('Save failed:'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('receive-retry-save')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('stored-file-actions')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('receive-retry-save')));
    await tester.pumpAndSettle();

    expect(decodeCalls, 1);
    expect(saveCalls, 2);
    expect(store.records, hasLength(1));
    expect(
      find.byKey(const ValueKey<String>('receive-retry-save')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('stored-file-actions')),
      findsOneWidget,
    );
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

Widget _receiveTestApp(Widget home) {
  return MaterialApp(
    locale: const Locale('en', 'US'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: LocaleSupport.supportedLocales,
    home: home,
  );
}

class _FailingTransferStore extends TransferStore {
  int addCalls = 0;

  @override
  Future<void> add(TransferRecord record) async {
    addCalls++;
    throw StateError('history unavailable');
  }
}
