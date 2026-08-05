import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/services/transfer_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('add and clear notify listeners once each', () async {
    final store = TransferStore();
    await store.init();
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.add(
      TransferRecord(
        id: '1',
        direction: TransferDirection.sent,
        fileName: 'a.txt',
        bytes: 3,
        createdAt: DateTime(2026, 8, 5),
        status: 'sent',
      ),
    );
    expect(store.records, hasLength(1));
    expect(notifications, 1);

    await store.clear();
    expect(store.records, isEmpty);
    expect(notifications, 2);
    store.dispose();
  });
}
