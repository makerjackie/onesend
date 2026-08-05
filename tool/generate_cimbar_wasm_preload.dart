import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const _source = 'assets/cimbar/upstream/cimbar_js.2026-07-13T0523.wasm';
const _output = 'assets/cimbar/upstream/cimbar_wasm_binary.2026-07-13T0523.js';
const _workerSource = 'assets/cimbar/upstream/recv-worker.2026-07-13T0523.js';
const _runtimeSource = 'assets/cimbar/upstream/cimbar_js.2026-07-13T0523.js';
const _inlineWorkerOutput =
    'assets/cimbar/upstream/cimbar_recv_worker_inline.2026-07-13T0523.js';

Future<void> main() async {
  final bytes = await File(_source).readAsBytes();
  final wasmDigest = sha256.convert(bytes);
  final encoded = base64Encode(bytes);
  final output = File(_output);
  await output.writeAsString('''
/* Generated from libcimbar WASM. Source SHA-256: $wasmDigest. */
(function (global) {
  'use strict';
  var encoded = '$encoded';
  var binary = global.atob(encoded);
  var bytes = new Uint8Array(binary.length);
  for (var i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  global.Module = global.Module || {};
  global.Module.wasmBinary = bytes;
})(globalThis);
''');
  stdout.writeln('Generated ${output.path} (${bytes.length} WASM bytes).');

  var worker = await File(_workerSource).readAsString();
  worker = worker
      .replaceAll("importScripts('cimbar_wasm_binary.2026-07-13T0523.js');", '')
      .replaceAll("importScripts('cimbar_js.2026-07-13T0523.js');", '')
      .replaceFirst(
        'var Module = {',
        'var Module = {\n  wasmBinary: oneSendWasmBinary,',
      );
  final runtime = await File(_runtimeSource).readAsString();
  final workerDigest = sha256.convert(utf8.encode(worker));
  final runtimeDigest = sha256.convert(utf8.encode(runtime));
  final inlineWorker =
      '''
self.onmessage = function oneSendOfflineWorkerInit(event) {
  if (!event.data || event.data.type !== 'onesend-wasm-init') return;
  var oneSendWasmBinary = new Uint8Array(event.data.wasmBinary);
  self.onmessage = null;
  (function () {
$worker
$runtime
  }).call(self);
};
''';
  await File(_inlineWorkerOutput).writeAsString('''
/* Generated offline Worker. Worker SHA-256: $workerDigest; runtime SHA-256: $runtimeDigest. */
(function (global) {
  'use strict';
  global.OneSendCimbarInlineReceiveWorkerSource = ${jsonEncode(inlineWorker)};
})(globalThis);
''');
  stdout.writeln('Generated $_inlineWorkerOutput.');
}
