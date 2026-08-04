// The test needs a controllable platform store to reproduce delayed native
// preference writes; the app itself only depends on shared_preferences.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:onesend/core/fountain.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/core/protocol.dart';
import 'package:onesend/services/app_settings.dart';

void main() {
  test('rejects invalid FEC geometry before constructing decoder buffers', () {
    expect(
      () => LTDecoder(
        blockCount: 0,
        blockLength: 720,
        sessionId: 1,
        totalLength: 1,
      ),
      throwsArgumentError,
    );
    expect(
      () => LTDecoder(
        blockCount: 1,
        blockLength: 720,
        sessionId: 1,
        totalLength: 721,
      ),
      throwsArgumentError,
    );
  });

  test('keeps sender wire geometry aligned with the selected QR profile', () {
    final payload = Uint8List.fromList(<int>[1]);

    OpticalSender createSender({int? blockLength, Duration? frameInterval}) {
      return OpticalSender(
        payload: payload,
        fileName: 'payload.bin',
        mimeType: 'application/octet-stream',
        mode: TransferMode.fast,
        blockLength: blockLength,
        frameInterval: frameInterval,
        useInternalClock: false,
        onFrame: (_, _) {},
      );
    }

    expect(
      () => createSender(blockLength: TransferMode.reliable.blockLength),
      throwsArgumentError,
    );
    expect(
      () => createSender(frameInterval: Duration.zero),
      throwsArgumentError,
    );
  });

  test(
    'hands off an idle QR receiver session without breaking live isolation',
    () {
      var now = DateTime.utc(2026, 1, 1);
      final receiver = OpticalReceiver(
        sessionIdleTimeout: const Duration(seconds: 5),
        clock: () => now,
      );

      final first = receiver.consume(_singleBlockFrame(sessionId: 1, byte: 1));
      expect(first?.payload, orderedEquals(<int>[1]));
      expect(receiver.snapshot?.sessionId, 1);

      now = now.add(const Duration(seconds: 4));
      expect(
        receiver.consume(_singleBlockFrame(sessionId: 2, byte: 2)),
        isNull,
      );
      expect(receiver.snapshot?.sessionId, 1);

      now = now.add(const Duration(seconds: 2));
      final handoff = receiver.consume(
        _singleBlockFrame(sessionId: 2, byte: 2),
      );
      expect(handoff?.payload, orderedEquals(<int>[2]));
      expect(receiver.snapshot?.sessionId, 2);
    },
  );

  test('serializes rapid transfer preference writes', () async {
    final store = _ManualPreferencesStore(<String, Object>{
      'flutter.$appSettingsTransferModeKey': TransferMode.reliable.id,
    });
    SharedPreferencesStorePlatform.instance = store;
    SharedPreferences.resetStatic();
    addTearDown(() {
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance =
          InMemorySharedPreferencesStore.empty();
    });

    final preferences = await SharedPreferences.getInstance();
    final settings = AppSettings(preferences: preferences);
    addTearDown(settings.dispose);

    final first = settings.setTransferMode(TransferMode.fast);
    await Future<void>.delayed(Duration.zero);
    final second = settings.setTransferMode(TransferMode.turbo);
    await Future<void>.delayed(Duration.zero);

    expect(store.pendingWrites, 1);
    store.completeNext(true);
    await Future<void>.delayed(Duration.zero);
    expect(store.pendingWrites, 1);
    store.completeNext(true);

    await Future.wait(<Future<void>>[first, second]);
    expect(
      store.values['flutter.$appSettingsTransferModeKey'],
      TransferMode.turbo.id,
    );
  });
}

Uint8List _singleBlockFrame({required int sessionId, required int byte}) {
  const blockLength = 720;
  final payload = Uint8List.fromList(<int>[byte]);
  final block = Uint8List(blockLength)..[0] = byte;
  return packFrame(
    FrameHeader(
      profileId: TransferMode.reliable.id,
      sessionId: sessionId,
      sequence: 0,
      blockCount: 1,
      blockLength: blockLength,
      totalLength: payload.length,
      payloadChecksum: crc32(payload),
    ),
    block,
  );
}

class _ManualPreferencesStore extends SharedPreferencesStorePlatform {
  _ManualPreferencesStore(Map<String, Object> initialValues)
    : values = Map<String, Object>.from(initialValues);

  final Map<String, Object> values;
  final List<_PendingWrite> _writes = <_PendingWrite>[];

  int get pendingWrites => _writes.length;

  void completeNext(bool result) {
    final write = _writes.removeAt(0);
    if (result) values[write.key] = write.value;
    write.completer.complete(result);
  }

  @override
  Future<bool> clear() async {
    values.clear();
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() async =>
      Map<String, Object>.from(values);

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    final completer = Completer<bool>();
    _writes.add(_PendingWrite(key, value, completer));
    return completer.future;
  }
}

class _PendingWrite {
  _PendingWrite(this.key, this.value, this.completer);

  final String key;
  final Object value;
  final Completer<bool> completer;
}
