import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('receiver HTML satisfies every upstream DOM lookup', () async {
    final html = await rootBundle.loadString('assets/cimbar/receive.html');
    final upstream = await rootBundle.loadString(
      'assets/cimbar/upstream/recv.2026-07-13T0523.js',
    );
    final htmlIds = RegExp(
      r'''id\s*=\s*["']([^"']+)["']''',
    ).allMatches(html).map((match) => match.group(1)!).toSet();
    final lookedUpIds = RegExp(
      r'''getElementById\(["']([^"']+)["']\)''',
    ).allMatches(upstream).map((match) => match.group(1)!).toSet();

    expect(
      htmlIds,
      containsAll(lookedUpIds),
      reason:
          'Missing an upstream DOM node aborts Recv.setMode before the '
          'receive-ready bridge event is emitted.',
    );
  });

  test('receiver arms the bridge before loading Emscripten', () async {
    final html = await rootBundle.loadString('assets/cimbar/receive.html');
    final boot = html.indexOf('OneSendCimbar.bootReceive()');
    final wasm = html.indexOf('upstream/cimbar_js.2026-07-13T0523.js');

    expect(boot, greaterThanOrEqualTo(0));
    expect(wasm, greaterThan(boot));
  });

  test('pause keeps the camera pipeline reusable for resume', () async {
    final bridge = await rootBundle.loadString(
      'assets/cimbar/onesend_cimbar_bridge.js',
    );
    final screen = await File(
      'lib/screens/cimbar_transfer_screen.dart',
    ).readAsString();

    expect(bridge, contains('function setReceivePaused(paused)'));
    expect(bridge, contains('setReceivePaused: setReceivePaused'));
    final pauseStart = bridge.indexOf('function setReceivePaused(paused)');
    final pauseEnd = bridge.indexOf('function stopReceive()', pauseStart);
    final pauseBody = bridge.substring(pauseStart, pauseEnd);
    expect(pauseBody, isNot(contains('stopReceiveWorkers()')));

    final flutterPauseStart = screen.indexOf('Future<void> _pauseReceive()');
    final flutterPauseEnd = screen.indexOf(
      'Future<void> _resumeReceive()',
      flutterPauseStart,
    );
    final flutterPauseBody = screen.substring(
      flutterPauseStart,
      flutterPauseEnd,
    );
    expect(flutterPauseBody, contains('OneSendCimbar.setReceivePaused(true)'));
    expect(flutterPauseBody, isNot(contains('_stopReceiveResources()')));
    expect(screen, contains('OneSendCimbar.setReceivePaused(false)'));
  });

  test('camera starts only after every decoder worker is ready', () async {
    final bridge = await rootBundle.loadString(
      'assets/cimbar/onesend_cimbar_bridge.js',
    );
    final start = bridge.indexOf('function startReceive(options)');
    final end = bridge.indexOf('function base64ToBytes', start);
    final startReceive = bridge.substring(start, end);

    expect(startReceive, contains('prepareReceiveWorkers'));
    expect(startReceive, contains('workersReady.then'));
    expect(
      startReceive.indexOf('workersReady.then'),
      lessThan(startReceive.indexOf('initializeReceiveVideo()')),
    );
    expect(bridge, contains("data.error === 'no wasm'"));
  });
}
