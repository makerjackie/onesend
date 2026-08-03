import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/optical_transfer.dart';
import '../l10n/locale_support.dart';

/// The preference key used for the mode selected for new transfers.
const String appSettingsTransferModeKey = 'default_transfer_mode';
const String appSettingsLocaleTagKey = 'locale_tag';

/// Lightweight persisted settings shared by the app's screens.
///
/// Use [AppSettings.load] at app startup so the stored mode is available before
/// constructing the transfer UI. The public constructor is also useful for
/// previews and tests; when [preferences] is supplied it reads the persisted
/// value synchronously.
class AppSettings extends ChangeNotifier {
  AppSettings({
    SharedPreferences? preferences,
    TransferMode initialTransferMode = TransferMode.fast,
    String? initialLocaleTag,
  }) : _preferences = preferences,
       _transferMode = _readTransferMode(preferences) ?? initialTransferMode,
       _localeTag =
           _readLocaleTag(preferences) ?? _validateLocaleTag(initialLocaleTag);

  /// The first-run mode, chosen for the best default throughput.
  static const TransferMode defaultTransferMode = TransferMode.fast;

  /// The key exposed for callers that need to inspect or migrate preferences.
  static const String transferModePreferenceKey = appSettingsTransferModeKey;
  static const String localeTagPreferenceKey = appSettingsLocaleTagKey;

  final SharedPreferences? _preferences;
  TransferMode _transferMode;
  String? _localeTag;

  /// Loads settings from [preferences], or from the platform preferences.
  static Future<AppSettings> load({SharedPreferences? preferences}) async {
    final resolvedPreferences =
        preferences ?? await SharedPreferences.getInstance();
    return AppSettings(preferences: resolvedPreferences);
  }

  /// The mode used by new transfers until the sender overrides it.
  TransferMode get transferMode => _transferMode;

  /// Alias that reads naturally at call sites that treat this as a default.
  TransferMode get defaultMode => _transferMode;

  /// The explicitly selected locale tag, or null to follow the system.
  String? get localeTag => _localeTag;

  static bool isValidLocaleTag(String? localeTag) {
    return localeTag == null || LocaleSupport.isSupportedTag(localeTag);
  }

  /// Changes and persists the default transfer mode.
  ///
  /// The in-memory value is updated immediately so listening screens respond
  /// without waiting on platform I/O. If persistence fails, the previous mode
  /// is restored and the error is rethrown for the caller to surface.
  Future<void> setTransferMode(TransferMode mode) async {
    final previousMode = _transferMode;
    final changed = previousMode != mode;
    if (changed) {
      _transferMode = mode;
      notifyListeners();
    }

    final preferences = _preferences;
    if (preferences == null ||
        preferences.getInt(transferModePreferenceKey) == mode.id) {
      return;
    }

    try {
      final persisted = await preferences.setInt(
        transferModePreferenceKey,
        mode.id,
      );
      if (!persisted) {
        throw StateError('无法保存默认传输模式。');
      }
    } catch (_) {
      if (changed && _transferMode == mode) {
        _transferMode = previousMode;
        notifyListeners();
      }
      rethrow;
    }
  }

  /// More explicit alias for integrations that call the setting a default.
  Future<void> setDefaultMode(TransferMode mode) => setTransferMode(mode);

  /// Changes and persists the selected locale. Null means follow the system.
  Future<void> setLocaleTag(String? localeTag) async {
    final nextLocaleTag = _validateLocaleTag(localeTag);
    final previousLocaleTag = _localeTag;
    final changed = previousLocaleTag != nextLocaleTag;
    if (changed) {
      _localeTag = nextLocaleTag;
      notifyListeners();
    }

    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    final storedLocaleTag = preferences.getString(localeTagPreferenceKey);
    final persistedAlready = nextLocaleTag == null
        ? !preferences.containsKey(localeTagPreferenceKey)
        : storedLocaleTag == nextLocaleTag;
    if (persistedAlready) {
      return;
    }

    try {
      final persisted = nextLocaleTag == null
          ? await preferences.remove(localeTagPreferenceKey)
          : await preferences.setString(localeTagPreferenceKey, nextLocaleTag);
      if (!persisted) {
        throw StateError('无法保存语言设置。');
      }
    } catch (_) {
      if (changed && _localeTag == nextLocaleTag) {
        _localeTag = previousLocaleTag;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> setLocale(String? localeTag) => setLocaleTag(localeTag);

  static String? _validateLocaleTag(String? localeTag) {
    if (localeTag == null) {
      return null;
    }
    final canonicalTag = LocaleSupport.canonicalTag(localeTag);
    if (canonicalTag == null) {
      throw ArgumentError.value(localeTag, 'localeTag', '不支持的语言标签。');
    }
    return canonicalTag;
  }

  static TransferMode? _readTransferMode(SharedPreferences? preferences) {
    final id = preferences?.getInt(transferModePreferenceKey);
    return id == null ? null : TransferMode.fromId(id);
  }

  static String? _readLocaleTag(SharedPreferences? preferences) {
    try {
      return LocaleSupport.canonicalTag(
        preferences?.getString(localeTagPreferenceKey),
      );
    } catch (_) {
      return null;
    }
  }
}
