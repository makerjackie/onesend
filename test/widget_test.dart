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
}
