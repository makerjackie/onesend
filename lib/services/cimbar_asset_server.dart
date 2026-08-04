import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serves `assets/cimbar/*` over loopback HTTP for the mobile WebView shell.
///
/// Loading CIMBAR via `loadFlutterAsset` uses a `file://` origin. On iOS/Android
/// WebViews that often yields a black camera preview and failed getUserMedia,
/// while native QR scanning still works. Localhost is a secure context and
/// restores camera capture inside WKWebView / Android WebView.
class CimbarAssetServer {
  CimbarAssetServer._();

  static final CimbarAssetServer instance = CimbarAssetServer._();

  static const String assetRoot = 'assets/cimbar';

  HttpServer? _server;
  Future<CimbarAssetServer>? _starting;

  int? get port => _server?.port;

  bool get isRunning => _server != null;

  /// Base URL, e.g. `http://127.0.0.1:54321/`.
  Uri get baseUri {
    final server = _server;
    if (server == null) {
      throw StateError('CimbarAssetServer has not started.');
    }
    return Uri(scheme: 'http', host: '127.0.0.1', port: server.port, path: '/');
  }

  Uri pageUri(String pageFileName) {
    final name = pageFileName.startsWith('/')
        ? pageFileName.substring(1)
        : pageFileName;
    return baseUri.resolve(name);
  }

  Future<CimbarAssetServer> ensureStarted({AssetBundle? bundle}) {
    if (_server != null) return Future<CimbarAssetServer>.value(this);
    return _starting ??= _start(bundle ?? rootBundle).whenComplete(() {
      _starting = null;
    });
  }

  Future<CimbarAssetServer> _start(AssetBundle bundle) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen((request) {
      unawaited(_handle(request, bundle));
    });
    debugPrint(
      '[OneSend CIMBAR] local asset server on http://127.0.0.1:${server.port}/',
    );
    return this;
  }

  Future<void> _handle(HttpRequest request, AssetBundle bundle) async {
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }

      final relative = safeRelativePath(request.uri.path);
      if (relative == null) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }

      final assetKey = '$assetRoot/$relative';
      final bytes = await _loadAssetBytes(bundle, assetKey);
      if (bytes == null) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.set('Content-Type', 'text/plain; charset=utf-8');
        request.response.write('Not found: $relative');
        await request.response.close();
        return;
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.set('Content-Type', _mimeFor(relative));
      request.response.headers.set('Cache-Control', 'no-store');
      // Workers / WASM from localhost need CORS-like openness for modules.
      request.response.headers.set('Cross-Origin-Resource-Policy', 'same-origin');
      if (request.method == 'GET') {
        request.response.add(bytes);
      }
      await request.response.close();
    } catch (error, stack) {
      debugPrint('[OneSend CIMBAR] asset server error: $error\n$stack');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  /// Reject path traversal; map `/` to receive.html only for health checks.
  @visibleForTesting
  static String? safeRelativePath(String rawPath) {
    var path = Uri.decodeComponent(rawPath);
    if (path.contains('\x00')) return null;
    while (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.isEmpty) return 'receive.html';
    if (path.contains('..')) return null;
    // Only serve files under the cimbar asset tree.
    if (path.startsWith('/') || path.contains('\\')) return null;
    return path;
  }

  Future<Uint8List?> _loadAssetBytes(AssetBundle bundle, String key) async {
    try {
      final data = await bundle.load(key);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on Object {
      return null;
    }
  }

  String _mimeFor(String relativePath) {
    final lower = relativePath.toLowerCase();
    if (lower.endsWith('.html')) return 'text/html; charset=utf-8';
    if (lower.endsWith('.js')) return 'text/javascript; charset=utf-8';
    if (lower.endsWith('.mjs')) return 'text/javascript; charset=utf-8';
    if (lower.endsWith('.css')) return 'text/css; charset=utf-8';
    if (lower.endsWith('.wasm')) return 'application/wasm';
    if (lower.endsWith('.json')) return 'application/json; charset=utf-8';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }
}
