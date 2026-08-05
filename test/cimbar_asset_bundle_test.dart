import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _cimbarUpstreamAssets = <String>[
  'assets/cimbar/upstream/cimbar_js.2026-07-13T0523.js',
  'assets/cimbar/upstream/cimbar_js.2026-07-13T0523.wasm',
  'assets/cimbar/upstream/cimbar_wasm_binary.2026-07-13T0523.js',
  'assets/cimbar/upstream/cimbar_recv_worker_inline.2026-07-13T0523.js',
  'assets/cimbar/upstream/main.2026-07-13T0523.js',
  'assets/cimbar/upstream/recv.2026-07-13T0523.js',
  'assets/cimbar/upstream/recv-worker.2026-07-13T0523.js',
  'assets/cimbar/upstream/send.2026-07-13T0523.js',
  'assets/cimbar/upstream/send-worker.2026-07-13T0523.js',
  'assets/cimbar/upstream/zstd.2026-07-13T0523.js',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads every packaged CIMBAR upstream JS/WASM asset', () async {
    for (final assetPath in _cimbarUpstreamAssets) {
      final data = await rootBundle.load(assetPath);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'CIMBAR asset is empty: $assetPath',
      );
    }
  });

  test('offline generated assets match their packaged sources', () async {
    final wasm = await rootBundle.load(
      'assets/cimbar/upstream/cimbar_js.2026-07-13T0523.wasm',
    );
    final preload = await rootBundle.loadString(
      'assets/cimbar/upstream/cimbar_wasm_binary.2026-07-13T0523.js',
    );
    final worker = await rootBundle.loadString(
      'assets/cimbar/upstream/recv-worker.2026-07-13T0523.js',
    );
    final runtime = await rootBundle.loadString(
      'assets/cimbar/upstream/cimbar_js.2026-07-13T0523.js',
    );
    final inline = await rootBundle.loadString(
      'assets/cimbar/upstream/cimbar_recv_worker_inline.2026-07-13T0523.js',
    );

    final wasmBytes = wasm.buffer.asUint8List(
      wasm.offsetInBytes,
      wasm.lengthInBytes,
    );
    final wasmDigest = sha256.convert(wasmBytes);
    final transformedWorker = worker
        .replaceAll(
          "importScripts('cimbar_wasm_binary.2026-07-13T0523.js');",
          '',
        )
        .replaceAll("importScripts('cimbar_js.2026-07-13T0523.js');", '')
        .replaceFirst(
          'var Module = {',
          'var Module = {\n  wasmBinary: oneSendWasmBinary,',
        );

    expect(preload, contains('Source SHA-256: $wasmDigest'));
    expect(
      inline,
      contains(
        'Worker SHA-256: ${sha256.convert(utf8.encode(transformedWorker))}',
      ),
    );
    expect(
      inline,
      contains('runtime SHA-256: ${sha256.convert(utf8.encode(runtime))}'),
    );
  });
}
