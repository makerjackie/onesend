import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/l10n/generated/app_localizations.dart';
import 'package:onesend/l10n/locale_support.dart';
import 'package:onesend/services/file_service.dart';
import 'package:onesend/widgets/stored_file_actions.dart';

void main() {
  testWidgets('uses simplified Chinese labels and location text', (
    WidgetTester tester,
  ) async {
    const path = '/tmp/onesend-widget/received.txt';
    await _pumpActions(
      tester,
      locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      file: const StoredTransfer(
        name: 'received.txt',
        mimeType: 'text/plain',
        bytes: 8,
        path: path,
      ),
      exists: true,
    );

    expect(find.text('保存位置'), findsOneWidget);
    expect(find.text('已保存到：$path'), findsOneWidget);
    expect(find.text('打开'), findsOneWidget);
    expect(find.text('分享 / 转发'), findsOneWidget);
    expect(find.text('保存副本'), findsOneWidget);
    expect(find.text('在文件夹中显示'), findsOneWidget);
  });

  testWidgets('uses English labels and missing-file messages', (
    WidgetTester tester,
  ) async {
    await _pumpActions(
      tester,
      locale: const Locale('en', 'US'),
      file: const StoredTransfer(
        name: 'received.txt',
        mimeType: 'text/plain',
        bytes: 8,
        path: '',
      ),
      exists: false,
    );

    expect(find.text('Saved location'), findsOneWidget);
    expect(find.text('No saved location was recorded.'), findsOneWidget);
    expect(
      find.text('The file is missing; it may have been moved or deleted.'),
      findsOneWidget,
    );
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Share / forward'), findsOneWidget);
    expect(find.text('Save a copy'), findsOneWidget);
    expect(find.text('Reveal in folder'), findsOneWidget);
  });
}

Future<void> _pumpActions(
  WidgetTester tester, {
  required Locale locale,
  required StoredTransfer file,
  required bool exists,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: LocaleSupport.supportedLocales,
      home: Scaffold(
        body: StoredFileActions(
          isDesktop: true,
          pathExists: (_) => SynchronousFuture<bool>(exists),
          file: file,
        ),
      ),
    ),
  );
  await tester.pump();
}
