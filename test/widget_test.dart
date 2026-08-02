import 'package:flutter_test/flutter_test.dart';

import 'package:onesend/app.dart';
import 'package:onesend/services/transfer_store.dart';

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
}
