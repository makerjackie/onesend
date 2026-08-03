import 'package:flutter/material.dart';

import 'app.dart';
import 'services/transfer_store.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TransferStore();
  await store.init();
  final updates = DesktopUpdateManager();
  try {
    await updates.initialize();
  } catch (_) {
    // File transfer must remain available even if the platform update service
    // cannot initialize on this launch.
  }
  runApp(OneSendApp(store: store, updates: updates));
}
