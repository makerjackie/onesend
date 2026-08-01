import 'package:flutter/material.dart';

import 'app.dart';
import 'services/transfer_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TransferStore();
  await store.init();
  runApp(OneSendApp(store: store));
}
