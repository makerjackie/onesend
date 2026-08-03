import 'package:flutter/widgets.dart';

/// A language that can be selected in OneSend's settings.
class LocaleOption {
  const LocaleOption({required this.tag, required this.nativeLabel});

  /// The canonical tag used for persistence and ARB files.
  final String tag;

  /// The language's own name for an un-translated language picker.
  final String nativeLabel;

  Locale get locale => LocaleSupport.parseTag(tag)!;

  String get label => nativeLabel;

  String get displayName => nativeLabel;
}

/// The supported locale set and the conversion rules around device locales.
class LocaleSupport {
  LocaleSupport._();

  static const List<String> supportedTags = <String>[
    'en',
    'zh-Hans',
    'zh-Hant',
    'ja',
    'ko',
    'es',
    'fr',
    'de',
    'pt',
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('ja'),
    Locale('ko'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('pt'),
  ];

  static const List<LocaleOption> options = <LocaleOption>[
    LocaleOption(tag: 'en', nativeLabel: 'English'),
    LocaleOption(tag: 'zh-Hans', nativeLabel: '简体中文'),
    LocaleOption(tag: 'zh-Hant', nativeLabel: '繁體中文'),
    LocaleOption(tag: 'ja', nativeLabel: '日本語'),
    LocaleOption(tag: 'ko', nativeLabel: '한국어'),
    LocaleOption(tag: 'es', nativeLabel: 'Español'),
    LocaleOption(tag: 'fr', nativeLabel: 'Français'),
    LocaleOption(tag: 'de', nativeLabel: 'Deutsch'),
    LocaleOption(tag: 'pt', nativeLabel: 'Português'),
  ];

  static const List<LocaleOption> localeOptions = options;

  static bool isSupportedTag(String? tag) => parseTag(tag) != null;

  static bool isKnownLanguageCode(String languageCode) {
    final normalized = languageCode.toLowerCase();
    return supportedTags.any(
      (tag) => tag.split('-').first.toLowerCase() == normalized,
    );
  }

  /// Returns the canonical form of a supported tag, or null when invalid.
  static String? canonicalTag(String? tag) {
    final locale = parseTag(tag);
    return locale == null ? null : serializeTag(locale);
  }

  /// Parses a supported tag. Underscores and casing are accepted on input.
  static Locale? parseTag(String? tag) {
    if (tag == null || tag.trim().isEmpty) {
      return null;
    }

    final normalized = tag.trim().replaceAll('_', '-').toLowerCase();
    return switch (normalized) {
      'en' => const Locale('en'),
      'zh-hans' => const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hans',
      ),
      'zh-hant' => const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
      ),
      'ja' => const Locale('ja'),
      'ko' => const Locale('ko'),
      'es' => const Locale('es'),
      'fr' => const Locale('fr'),
      'de' => const Locale('de'),
      'pt' => const Locale('pt'),
      _ => null,
    };
  }

  static Locale? parseLocaleTag(String? tag) => parseTag(tag);

  /// Serializes a locale to one of the supported canonical tags.
  /// Unknown locales fall back to English so this method is total.
  static String serializeTag(Locale locale) {
    final language = locale.languageCode.toLowerCase();
    if (language == 'zh') {
      final script = locale.scriptCode?.toLowerCase();
      final country = locale.countryCode?.toUpperCase();
      final traditionalCountry =
          country == 'TW' || country == 'HK' || country == 'MO';
      if (script == 'hant' || traditionalCountry) {
        return 'zh-Hant';
      }
      return 'zh-Hans';
    }

    return switch (language) {
      'en' => 'en',
      'ja' => 'ja',
      'ko' => 'ko',
      'es' => 'es',
      'fr' => 'fr',
      'de' => 'de',
      'pt' => 'pt',
      _ => 'en',
    };
  }

  static String? serializeNullableTag(Locale? locale) {
    return locale == null ? null : serializeTag(locale);
  }

  /// Resolves a device locale to a supported Flutter [Locale].
  static Locale resolveDeviceLocale(Locale? deviceLocale) {
    return parseTag(resolveDeviceLocaleTag(deviceLocale))!;
  }

  /// Resolves a device locale to the canonical persisted tag.
  static String resolveDeviceLocaleTag(Locale? deviceLocale) {
    return deviceLocale == null ? 'en' : serializeTag(deviceLocale);
  }

  static Locale resolveLocale(Locale? deviceLocale) =>
      resolveDeviceLocale(deviceLocale);
}

const List<LocaleOption> supportedLocaleOptions = LocaleSupport.options;

Locale? parseLocaleTag(String? tag) => LocaleSupport.parseTag(tag);

String serializeLocaleTag(Locale locale) => LocaleSupport.serializeTag(locale);

String resolveDeviceLocaleTag(Locale? locale) =>
    LocaleSupport.resolveDeviceLocaleTag(locale);

Locale resolveDeviceLocale(Locale? locale) =>
    LocaleSupport.resolveDeviceLocale(locale);
