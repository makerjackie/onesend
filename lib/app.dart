import 'package:flutter/material.dart';

import 'core/optical_transfer.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/locale_support.dart';
import 'screens/home_screen.dart';
import 'services/app_settings.dart';
import 'services/transfer_store.dart';
import 'services/update_service.dart';

const Color oneSendInk = Color(0xff10130f);
const Color oneSendLime = Color(0xffd9f866);
const Color oneSendPaper = Color(0xfff5f6f0);
const Color oneSendMuted = Color(0xff737970);

class OneSendApp extends StatefulWidget {
  const OneSendApp({
    required this.store,
    this.settings,
    this.updates,
    super.key,
  });

  final TransferStore store;
  final AppSettings? settings;
  final UpdateManager? updates;

  @override
  State<OneSendApp> createState() => _OneSendAppState();
}

class _OneSendAppState extends State<OneSendApp> {
  late final AppSettings _fallbackSettings = AppSettings();

  AppSettings get _settings => widget.settings ?? _fallbackSettings;

  @override
  void dispose() {
    if (widget.settings == null) _fallbackSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settings,
      builder: (context, _) => _buildMaterialApp(context),
    );
  }

  Widget _buildMaterialApp(BuildContext context) {
    const lightScheme = ColorScheme.light(
      primary: oneSendInk,
      onPrimary: Colors.white,
      secondary: oneSendLime,
      onSecondary: oneSendInk,
      surface: oneSendPaper,
      onSurface: oneSendInk,
      error: Color(0xffa32820),
      onError: Colors.white,
    );
    const darkScheme = ColorScheme.dark(
      primary: oneSendLime,
      onPrimary: oneSendInk,
      secondary: oneSendLime,
      onSecondary: oneSendInk,
      surface: Color(0xff121512),
      onSurface: oneSendPaper,
      error: Color(0xffffaaa0),
      onError: oneSendInk,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OneSend',
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'OneSend',
      locale: LocaleSupport.parseTag(_settings.localeTag),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: LocaleSupport.supportedLocales,
      localeListResolutionCallback: (locales, supportedLocales) {
        for (final locale in locales ?? const <Locale>[]) {
          if (LocaleSupport.isKnownLanguageCode(locale.languageCode)) {
            return LocaleSupport.resolveDeviceLocale(locale);
          }
        }
        return const Locale('en');
      },
      theme: _buildOneSendTheme(lightScheme),
      darkTheme: _buildOneSendTheme(darkScheme),
      themeMode: _settings.themeMode,
      home: HomeScreen(
        store: widget.store,
        settings: _settings,
        updates: widget.updates ?? DisabledUpdateManager.instance,
      ),
    );
  }
}

ThemeData _buildOneSendTheme(ColorScheme scheme) {
  final baseTextTheme =
      ThemeData(brightness: scheme.brightness, useMaterial3: true).textTheme
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  final textTheme = baseTextTheme.copyWith(
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      color: scheme.onSurface,
      height: 1.45,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.72),
      height: 1.45,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerHighest,
      margin: EdgeInsets.zero,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        side: BorderSide(color: scheme.outline, width: 1.2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerHighest,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      indicatorColor: scheme.secondary,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      indicatorColor: scheme.secondary,
      selectedIconTheme: IconThemeData(color: scheme.onSecondary),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
  );
}

String localizedTransferModeName(AppLocalizations l10n, TransferMode mode) {
  return mode == TransferMode.fast ? l10n.modeFast : l10n.modeReliable;
}

String localizedTransferError(
  BuildContext context,
  Object error, {
  String? fallback,
}) {
  final l10n = AppLocalizations.of(context);
  final raw = error
      .toString()
      .replaceFirst('FormatException: ', '')
      .replaceFirst('Bad state: ', '')
      .replaceFirst('StateError: ', '')
      .trim();
  if (l10n == null) return fallback ?? raw;

  final lower = raw.toLowerCase();
  if (raw.contains('64 MB') || lower.contains('64 mb')) {
    return l10n.fileTooLarge('64 MB');
  }
  if (raw.contains('无法读取') || lower.contains('could not read')) {
    return l10n.cannotReadFile;
  }
  if (raw.contains('测试视频为空')) return l10n.sampleVideoEmpty;
  if (raw.contains('测试视频超过')) {
    return l10n.sampleVideoTooLarge('64 MB');
  }
  if (raw.contains('文件不存在') ||
      lower.contains('file does not exist') ||
      lower.contains('no such file') ||
      lower.contains('not found')) {
    return l10n.fileNotFound;
  }
  if (raw.contains('权限') ||
      lower.contains('permission') ||
      lower.contains('access denied')) {
    return l10n.fileAccessDenied;
  }
  if (raw.contains('取消') || lower.contains('cancel')) {
    return l10n.operationCancelled;
  }
  if (raw.contains('不支持') ||
      lower.contains('unsupported') ||
      lower.contains('unimplemented')) {
    return l10n.unsupportedOperation;
  }
  if (raw.contains('打开') && raw.contains('文件')) return l10n.openFileError;
  if (lower.contains('could not open')) return l10n.openFileError;
  return fallback ?? l10n.genericTransferError;
}
