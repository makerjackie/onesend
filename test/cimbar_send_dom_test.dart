import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _sendDomIdsRequiredByUpstream = <String>{
  'canvas',
  'current-file',
  'file_input',
  'invisible_click',
  'nav-container',
  'nav-button',
  'nav-content',
  'nav-find-file-link',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sender HTML contains every upstream initialization DOM ID', () async {
    final html = await rootBundle.loadString('assets/cimbar/send.html');
    final ids = RegExp(
      r'''id\s*=\s*["']([^"']+)["']''',
    ).allMatches(html).map((match) => match.group(1)!).toSet();

    expect(ids, containsAll(_sendDomIdsRequiredByUpstream));
    expect(
      html,
      contains(RegExp(r'''<[^>]*id=["']current-file["'][^>]*\bhidden\b''')),
    );
  });
}
