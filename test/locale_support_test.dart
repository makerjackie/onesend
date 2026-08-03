import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:onesend/l10n/locale_support.dart';

void main() {
  test('exposes the nine supported locales and native labels', () {
    expect(LocaleSupport.options, hasLength(9));
    expect(
      LocaleSupport.options.map((option) => option.tag),
      containsAll(<String>[
        'en',
        'zh-Hans',
        'zh-Hant',
        'ja',
        'ko',
        'es',
        'fr',
        'de',
        'pt',
      ]),
    );
    expect(LocaleSupport.options[1].nativeLabel, '简体中文');
    expect(LocaleSupport.options[2].nativeLabel, '繁體中文');
  });

  test('parses and serializes supported locale tags', () {
    final simplified = LocaleSupport.parseTag('zh_Hans');
    final traditional = LocaleSupport.parseTag('ZH-hant');

    expect(simplified?.scriptCode, 'Hans');
    expect(traditional?.scriptCode, 'Hant');
    expect(LocaleSupport.serializeTag(simplified!), 'zh-Hans');
    expect(LocaleSupport.serializeTag(traditional!), 'zh-Hant');
    expect(LocaleSupport.parseTag('it'), isNull);
  });

  test('resolves device locales with Chinese script and region rules', () {
    expect(
      LocaleSupport.resolveDeviceLocaleTag(const Locale('en', 'US')),
      'en',
    );
    expect(
      LocaleSupport.resolveDeviceLocaleTag(const Locale('zh', 'CN')),
      'zh-Hans',
    );
    expect(
      LocaleSupport.resolveDeviceLocaleTag(const Locale('zh', 'TW')),
      'zh-Hant',
    );
    expect(
      LocaleSupport.resolveDeviceLocaleTag(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
      'zh-Hant',
    );
    expect(
      LocaleSupport.resolveDeviceLocaleTag(const Locale('it', 'IT')),
      'en',
    );
  });
}
