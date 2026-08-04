import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/services/app_settings.dart';

void main() {
  test('uses fast as the default transfer mode', () {
    final settings = AppSettings();
    addTearDown(settings.dispose);

    expect(settings.transferMode, TransferMode.fast);
    expect(settings.defaultMode, TransferMode.fast);
  });

  test('loads and persists the selected transfer mode', () async {
    SharedPreferences.setMockInitialValues({
      appSettingsTransferModeKey: TransferMode.reliable.id,
      appSettingsLocaleTagKey: 'zh-Hans',
    });
    final preferences = await SharedPreferences.getInstance();
    final settings = AppSettings(preferences: preferences);
    addTearDown(settings.dispose);

    expect(settings.transferMode, TransferMode.reliable);

    await settings.setDefaultMode(TransferMode.fast);

    expect(settings.transferMode, TransferMode.fast);
    expect(
      preferences.getInt(appSettingsTransferModeKey),
      TransferMode.fast.id,
    );
    expect(settings.localeTag, 'zh-Hans');

    await settings.setLocaleTag('zh_Hant');

    expect(settings.localeTag, 'zh-Hant');
    expect(preferences.getString(appSettingsLocaleTagKey), 'zh-Hant');

    await settings.setLocaleTag(null);

    expect(settings.localeTag, isNull);
    expect(preferences.containsKey(appSettingsLocaleTagKey), isFalse);
  });

  test(
    'rejects unsupported locale tags without changing the setting',
    () async {
      final settings = AppSettings();
      addTearDown(settings.dispose);

      expect(settings.localeTag, isNull);
      await expectLater(
        settings.setLocaleTag('it'),
        throwsA(isA<ArgumentError>()),
      );
      expect(settings.localeTag, isNull);
    },
  );

  test('loads and persists the selected theme mode', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      appSettingsThemeModeKey: 2,
    });
    final preferences = await SharedPreferences.getInstance();
    final settings = AppSettings(preferences: preferences);
    addTearDown(settings.dispose);

    expect(settings.themeMode, ThemeMode.dark);

    await settings.setThemeMode(ThemeMode.light);
    expect(settings.themeMode, ThemeMode.light);
    expect(preferences.getInt(appSettingsThemeModeKey), 1);

    final reloaded = AppSettings(preferences: preferences);
    addTearDown(reloaded.dispose);
    expect(reloaded.themeMode, ThemeMode.light);
  });
}
