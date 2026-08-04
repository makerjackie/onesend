import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/screens/cimbar_transfer_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  test('receive grants camera even when iOS also reports microphone', () {
    expect(
      shouldGrantCimbarWebViewMediaPermission(
        isSending: false,
        types: <WebViewPermissionResourceType>{
          WebViewPermissionResourceType.camera,
          WebViewPermissionResourceType.microphone,
        },
      ),
      isTrue,
    );
  });

  test('receive grants plain camera-only requests', () {
    expect(
      shouldGrantCimbarWebViewMediaPermission(
        isSending: false,
        types: <WebViewPermissionResourceType>{
          WebViewPermissionResourceType.camera,
        },
      ),
      isTrue,
    );
  });

  test('send never grants camera capture', () {
    expect(
      shouldGrantCimbarWebViewMediaPermission(
        isSending: true,
        types: <WebViewPermissionResourceType>{
          WebViewPermissionResourceType.camera,
        },
      ),
      isFalse,
    );
  });

  test('receive denies requests that do not include camera', () {
    expect(
      shouldGrantCimbarWebViewMediaPermission(
        isSending: false,
        types: <WebViewPermissionResourceType>{
          WebViewPermissionResourceType.microphone,
        },
      ),
      isFalse,
    );
  });

  test('receive grants empty type sets used by some WebView builds', () {
    expect(
      shouldGrantCimbarWebViewMediaPermission(
        isSending: false,
        types: <WebViewPermissionResourceType>{},
      ),
      isTrue,
    );
  });
}
