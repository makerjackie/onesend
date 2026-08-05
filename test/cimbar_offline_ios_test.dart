import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'iOS CIMBAR path contains no local server or network entitlement',
    () async {
      final screen = await File(
        'lib/screens/cimbar_transfer_screen.dart',
      ).readAsString();
      final plist = await File('ios/Runner/Info.plist').readAsString();

      expect(screen, isNot(contains('CimbarAssetServer')));
      expect(screen, isNot(contains('loadRequest(')));
      expect(screen, contains('loadFlutterAsset('));
      expect(plist, isNot(contains('NSAppTransportSecurity')));
      expect(plist, isNot(contains('NSAllowsLocalNetworking')));
      expect(plist, isNot(contains('NSLocalNetworkUsageDescription')));
    },
  );
}
