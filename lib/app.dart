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
    const scheme = ColorScheme.light(
      primary: oneSendInk,
      onPrimary: Colors.white,
      secondary: oneSendLime,
      onSecondary: oneSendInk,
      surface: oneSendPaper,
      onSurface: oneSendInk,
      error: Color(0xffa32820),
      onError: Colors.white,
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: oneSendPaper,
        appBarTheme: const AppBarTheme(
          backgroundColor: oneSendPaper,
          foregroundColor: oneSendInk,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          margin: EdgeInsets.zero,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            side: BorderSide(color: oneSendInk, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: oneSendInk,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            side: const BorderSide(color: oneSendInk, width: 2),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: oneSendInk,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            side: const BorderSide(color: oneSendInk, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: oneSendInk,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xffc9cec4),
          thickness: 1,
          space: 1,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            side: BorderSide(color: oneSendInk, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: oneSendInk,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
          titleLarge: TextStyle(
            color: oneSendInk,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: TextStyle(
            color: oneSendInk,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: oneSendInk, height: 1.45),
          bodyMedium: TextStyle(color: oneSendMuted, height: 1.45),
        ),
      ),
      home: HomeScreen(
        store: widget.store,
        settings: _settings,
        updates: widget.updates ?? DisabledUpdateManager.instance,
      ),
    );
  }
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
