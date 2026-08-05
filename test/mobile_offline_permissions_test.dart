import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile release manifests keep file transfer offline', () async {
    final android = await File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsString();
    final ios = await File('ios/Runner/Info.plist').readAsString();

    expect(android, contains('android.permission.CAMERA'));
    for (final permission in const <String>[
      'android.permission.INTERNET',
      'android.permission.ACCESS_NETWORK_STATE',
      'android.permission.RECORD_AUDIO',
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.READ_MEDIA_IMAGES',
      'android.permission.READ_MEDIA_VIDEO',
      'android.permission.READ_MEDIA_AUDIO',
    ]) {
      expect(
        android,
        contains(
          '<uses-permission android:name="$permission" tools:node="remove"/>',
        ),
        reason: '$permission must be removed from merged release manifests',
      );
    }

    expect(ios, contains('NSCameraUsageDescription'));
    expect(ios, isNot(contains('NSLocalNetworkUsageDescription')));
    expect(ios, isNot(contains('NSBonjourServices')));
    expect(ios, isNot(contains('NSAppTransportSecurity')));
  });
}
