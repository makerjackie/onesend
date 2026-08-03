import 'dart:io';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/native_qr_codec_self_test.dart';
import 'services/app_settings.dart';
import 'services/transfer_store.dart';
import 'services/update_service.dart';

const _nativeQrCodecSelfTestEnabled = bool.fromEnvironment(
  'ONESEND_NATIVE_QR_SELF_TEST',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_nativeQrCodecSelfTestEnabled) {
    try {
      await runNativeQrCodecSelfTest();
      exit(0);
    } catch (error, stackTrace) {
      stderr
        ..writeln(error)
        ..writeln(stackTrace);
      exit(1);
    }
  }

  final store = TransferStore();
  await store.init();
  AppSettings settings;
  try {
    settings = await AppSettings.load();
  } catch (_) {
    // A preference-store failure must not make the transfer UI unavailable.
    // AppSettings defaults to the fastest profile on a clean launch.
    settings = AppSettings(
      initialTransferMode: AppSettings.defaultTransferMode,
    );
  }
  final updates = createUpdateManager();
  try {
    await updates.initialize();
  } catch (_) {
    // File transfer must remain available even if the platform update service
    // cannot initialize on this launch.
  }
  runApp(OneSendApp(store: store, settings: settings, updates: updates));
}
