import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/services/cimbar_asset_server.dart';

void main() {
  test('safeRelativePath rejects traversal and maps root', () {
    expect(CimbarAssetServer.safeRelativePath('/'), 'receive.html');
    expect(
      CimbarAssetServer.safeRelativePath('/upstream/recv-worker.js'),
      'upstream/recv-worker.js',
    );
    expect(CimbarAssetServer.safeRelativePath('/foo/../../x'), isNull);
    expect(CimbarAssetServer.safeRelativePath('..'), isNull);
    expect(CimbarAssetServer.safeRelativePath('/../secrets'), isNull);
  });
}
