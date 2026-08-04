import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/optical_transfer.dart';
import '../l10n/locale_support.dart';

/// The preference key used for the mode selected for new transfers.
const String appSettingsTransferModeKey = 'default_transfer_mode';

/// The preference key used for the algorithm selected for new transfers.
const String appSettingsTransferAlgorithmKey = 'default_transfer_algorithm';
const String appSettingsLocaleTagKey = 'locale_tag';
const String appSettingsThemeModeKey = 'theme_mode';

/// The visual transport family used for new transfers.
///
/// QR profiles remain represented by [TransferMode]. Keeping this choice
/// separate means the CIMBAR experiment never becomes a QR profile or changes
/// the meaning of the existing `default_transfer_mode` preference.
enum TransferAlgorithm {
  qr(id: 0),
  cimbar(id: 1);

  const TransferAlgorithm({required this.id});

  final int id;

  static TransferAlgorithm? fromId(int id) {
    return switch (id) {
      0 => qr,
      1 => cimbar,
      _ => null,
    };
  }
}

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
    TransferAlgorithm initialTransferAlgorithm = TransferAlgorithm.qr,
    TransferAlgorithm? initialAlgorithm,
    String? initialLocaleTag,
    ThemeMode initialThemeMode = ThemeMode.system,
    ThemeMode? initialThemePreference,
  }) : _preferences = preferences,
       _transferMode = _readTransferMode(preferences) ?? initialTransferMode,
       _transferAlgorithm =
           _readTransferAlgorithm(preferences) ??
           initialAlgorithm ??
           initialTransferAlgorithm,
       _localeTag =
           _readLocaleTag(preferences) ?? _validateLocaleTag(initialLocaleTag),
       _themeMode =
           _readThemeMode(preferences) ??
           initialThemePreference ??
           initialThemeMode;

  /// The first-run mode, chosen for the best default throughput.
  static const TransferMode defaultTransferMode = TransferMode.fast;

  /// The key exposed for callers that need to inspect or migrate preferences.
  static const String transferModePreferenceKey = appSettingsTransferModeKey;
  static const String transferAlgorithmPreferenceKey =
      appSettingsTransferAlgorithmKey;
  static const String localeTagPreferenceKey = appSettingsLocaleTagKey;
  static const String themeModePreferenceKey = appSettingsThemeModeKey;

  /// The first-run algorithm. QR is the stable, broadly compatible default.
  static const TransferAlgorithm defaultTransferAlgorithm =
      TransferAlgorithm.qr;

  final SharedPreferences? _preferences;
  TransferMode _transferMode;
  TransferAlgorithm _transferAlgorithm;
  String? _localeTag;
  ThemeMode _themeMode;
  Future<void> _transferWriteTail = Future<void>.value();

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

  /// The visual transport family used by new transfers.
  TransferAlgorithm get transferAlgorithm => _transferAlgorithm;

  /// Alias for callers that refer to the preference as the default algorithm.
  TransferAlgorithm get algorithm => _transferAlgorithm;

  /// The explicitly selected locale tag, or null to follow the system.
  String? get localeTag => _localeTag;

  /// The visual theme selected for the application.
  ThemeMode get themeMode => _themeMode;

  /// Alias for settings UIs that call this a theme preference.
  ThemeMode get themePreference => _themeMode;

  static bool isValidLocaleTag(String? localeTag) {
    return localeTag == null || LocaleSupport.isSupportedTag(localeTag);
  }

  /// Changes and persists the default transfer mode.
  ///
  /// The in-memory value is updated immediately so listening screens respond
  /// without waiting on platform I/O. If persistence fails, the previous mode
  /// is restored and the error is rethrown for the caller to surface.
  Future<void> setTransferMode(TransferMode mode) {
    final previousMode = _transferMode;
    final changed = previousMode != mode;
    if (changed) {
      _transferMode = mode;
      notifyListeners();
    }

    final preferences = _preferences;
    if (preferences == null ||
        (!changed &&
            preferences.getInt(transferModePreferenceKey) == mode.id)) {
      return Future<void>.value();
    }

    final operation = _enqueueTransferWrite(() async {
      final persisted = await preferences.setInt(
        transferModePreferenceKey,
        mode.id,
      );
      if (!persisted) {
        throw StateError('无法保存默认传输模式。');
      }
    });
    return operation.catchError((Object error, StackTrace stackTrace) {
      if (changed && _transferMode == mode) {
        _transferMode = previousMode;
        notifyListeners();
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  /// More explicit alias for integrations that call the setting a default.
  Future<void> setDefaultMode(TransferMode mode) => setTransferMode(mode);

  /// Changes and persists the default visual transport family.
  ///
  /// QR remains the default even when no preference store is available. A
  /// failed write restores the in-memory value, matching [setTransferMode].
  Future<void> setTransferAlgorithm(TransferAlgorithm algorithm) {
    final previousAlgorithm = _transferAlgorithm;
    final changed = previousAlgorithm != algorithm;
    if (changed) {
      _transferAlgorithm = algorithm;
      notifyListeners();
    }

    final preferences = _preferences;
    if (preferences == null ||
        (!changed &&
            preferences.getInt(transferAlgorithmPreferenceKey) ==
                algorithm.id)) {
      return Future<void>.value();
    }

    final operation = _enqueueTransferWrite(() async {
      final persisted = await preferences.setInt(
        transferAlgorithmPreferenceKey,
        algorithm.id,
      );
      if (!persisted) {
        throw StateError('无法保存默认传输算法。');
      }
    });
    return operation.catchError((Object error, StackTrace stackTrace) {
      if (changed && _transferAlgorithm == algorithm) {
        _transferAlgorithm = previousAlgorithm;
        notifyListeners();
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> setDefaultAlgorithm(TransferAlgorithm algorithm) =>
      setTransferAlgorithm(algorithm);

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

  /// Changes and persists the visual theme. [ThemeMode.system] follows the
  /// operating system and is the default for new installs.
  Future<void> setThemeMode(ThemeMode mode) {
    final previousMode = _themeMode;
    final changed = previousMode != mode;
    if (changed) {
      _themeMode = mode;
      notifyListeners();
    }

    final preferences = _preferences;
    if (preferences == null ||
        (!changed &&
            preferences.getInt(themeModePreferenceKey) == _themeModeId(mode))) {
      return Future<void>.value();
    }

    final operation = _enqueueTransferWrite(() async {
      final persisted = await preferences.setInt(
        themeModePreferenceKey,
        _themeModeId(mode),
      );
      if (!persisted) {
        throw StateError('无法保存主题设置。');
      }
    });
    return operation.catchError((Object error, StackTrace stackTrace) {
      if (changed && _themeMode == mode) {
        _themeMode = previousMode;
        notifyListeners();
      }
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> setThemePreference(ThemeMode mode) => setThemeMode(mode);

  Future<void> _enqueueTransferWrite(Future<void> Function() write) {
    final operation = _transferWriteTail.then<void>((_) => write());
    // A failed write must not poison later user selections. The individual
    // operation still reports the original error to its caller.
    _transferWriteTail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

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

  static TransferAlgorithm? _readTransferAlgorithm(
    SharedPreferences? preferences,
  ) {
    try {
      final id = preferences?.getInt(transferAlgorithmPreferenceKey);
      return id == null ? null : TransferAlgorithm.fromId(id);
    } catch (_) {
      return null;
    }
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

  static ThemeMode? _readThemeMode(SharedPreferences? preferences) {
    try {
      final id = preferences?.getInt(themeModePreferenceKey);
      return switch (id) {
        0 => ThemeMode.system,
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  static int _themeModeId(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 0,
      ThemeMode.light => 1,
      ThemeMode.dark => 2,
    };
  }
}
