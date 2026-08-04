import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/optical_transfer.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/locale_support.dart';
import '../services/app_settings.dart';
import '../services/update_service.dart';
import '../widgets/transfer_mode_selector.dart';
import '../widgets/update_ui.dart';
import 'about_screen.dart';

/// Settings embedded in the app shell.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    this.updates,
    this.onLanguageTap,
    this.onAboutTap,
    this.isDesktop,
    super.key,
  });

  final AppSettings settings;
  final UpdateManager? updates;
  final VoidCallback? onLanguageTap;
  final VoidCallback? onAboutTap;

  /// Overrides platform detection in previews and tests.
  final bool? isDesktop;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _savingMode = false;

  bool get _desktop => widget.isDesktop ?? _isDesktopPlatform();

  bool get _showUpdateSettings =>
      _desktop && widget.updates?.supportsUpdates == true;

  Future<void> _openLanguageEntry() async {
    final callback = widget.onLanguageTap;
    if (callback != null) {
      callback();
      return;
    }

    const systemValue = '__system__';
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final currentTag = widget.settings.localeTag;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Text(
                  l10n.languagePickerTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _LanguageChoiceTile(
                title: l10n.followSystem,
                selected: currentTag == null,
                onTap: () => Navigator.of(context).pop(systemValue),
              ),
              for (final option in LocaleSupport.options)
                _LanguageChoiceTile(
                  title: option.nativeLabel,
                  selected: currentTag == option.tag,
                  onTap: () => Navigator.of(context).pop(option.tag),
                ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    try {
      await widget.settings.setLocaleTag(
        selected == systemValue ? null : selected,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.languageSaveError)));
    }
  }

  Future<void> _openThemeEntry() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.theme,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              _ThemeChoiceTile(
                key: const ValueKey<String>('theme-system'),
                icon: Icons.settings_suggest_outlined,
                title: l10n.themeSystem,
                selected: widget.settings.themeMode == ThemeMode.system,
                onTap: () => Navigator.of(context).pop(ThemeMode.system),
              ),
              _ThemeChoiceTile(
                key: const ValueKey<String>('theme-light'),
                icon: Icons.light_mode_outlined,
                title: l10n.themeLight,
                selected: widget.settings.themeMode == ThemeMode.light,
                onTap: () => Navigator.of(context).pop(ThemeMode.light),
              ),
              _ThemeChoiceTile(
                key: const ValueKey<String>('theme-dark'),
                icon: Icons.dark_mode_outlined,
                title: l10n.themeDark,
                selected: widget.settings.themeMode == ThemeMode.dark,
                onTap: () => Navigator.of(context).pop(ThemeMode.dark),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    try {
      await widget.settings.setThemeMode(selected);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.themeSaveError)));
    }
  }

  Future<void> _openUpdateSettings() async {
    final updates = widget.updates;
    if (!_showUpdateSettings || updates == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _DesktopUpdateSettingsDialog(updates: updates),
    );
  }

  Future<void> _openAbout() async {
    final callback = widget.onAboutTap;
    if (callback != null) {
      callback();
      return;
    }
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));
  }

  Future<void> _openTransferModeEntry() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: AnimatedBuilder(
          animation: widget.settings,
          builder: (context, _) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.defaultTransferAlgorithm,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.algorithmDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TransferModeSelector(
                      key: const ValueKey<String>('settings-mode-selector'),
                      algorithm: widget.settings.transferAlgorithm,
                      mode: widget.settings.transferMode,
                      enabled: !_savingMode,
                      dense: true,
                      keyPrefix: 'settings',
                      onQrModeSelected: (mode) => unawaited(
                        _selectTransfer(
                          sheetContext,
                          algorithm: TransferAlgorithm.qr,
                          mode: mode,
                        ),
                      ),
                      onCimbarSelected: () => unawaited(
                        _selectTransfer(
                          sheetContext,
                          algorithm: TransferAlgorithm.cimbar,
                        ),
                      ),
                    ),
                    if (_savingMode) ...[
                      const SizedBox(height: 14),
                      const LinearProgressIndicator(minHeight: 3),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTransfer(
    BuildContext sheetContext, {
    required TransferAlgorithm algorithm,
    TransferMode? mode,
  }) async {
    final alreadySelected =
        widget.settings.transferAlgorithm == algorithm &&
        (algorithm == TransferAlgorithm.cimbar ||
            widget.settings.transferMode == mode);
    if (_savingMode || alreadySelected) return;
    setState(() => _savingMode = true);
    try {
      await widget.settings.setDefaultAlgorithm(algorithm);
      if (mode != null) await widget.settings.setDefaultMode(mode);
      if (mounted && sheetContext.mounted) Navigator.of(sheetContext).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.modeSaveError)),
      );
    } finally {
      if (mounted) setState(() => _savingMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.settings,
          builder: (context, _) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsIntroTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(l10n.settingsIntroBody),
              const SizedBox(height: 28),
              _SectionLabel(label: l10n.transportSection),
              const SizedBox(height: 8),
              _SettingsPanel(
                child: _SettingRow(
                  key: const ValueKey<String>('settings-transfer-mode'),
                  icon:
                      widget.settings.transferAlgorithm ==
                          TransferAlgorithm.cimbar
                      ? Icons.palette_outlined
                      : Icons.qr_code_2_rounded,
                  title: l10n.defaultTransferAlgorithm,
                  subtitle: _selectedTransferLabel(l10n),
                  onTap: _openTransferModeEntry,
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(label: l10n.appSection),
              const SizedBox(height: 8),
              _SettingsPanel(
                child: Column(
                  children: [
                    _SettingRow(
                      key: const ValueKey<String>('settings-language'),
                      icon: Icons.translate_rounded,
                      title: l10n.language,
                      subtitle: _selectedLanguageLabel(l10n),
                      onTap: _openLanguageEntry,
                    ),
                    const _PanelDivider(),
                    _SettingRow(
                      key: const ValueKey<String>('settings-theme'),
                      icon: _themeIcon(widget.settings.themeMode),
                      title: l10n.theme,
                      subtitle: _selectedThemeLabel(l10n),
                      onTap: _openThemeEntry,
                    ),
                    if (_showUpdateSettings) ...[
                      const _PanelDivider(),
                      _SettingRow(
                        key: const ValueKey<String>('settings-updates'),
                        icon: Icons.system_update_alt_rounded,
                        title: l10n.desktopUpdates,
                        subtitle: l10n.desktopUpdatesSubtitle,
                        onTap: _openUpdateSettings,
                      ),
                    ],
                    const _PanelDivider(),
                    _SettingRow(
                      key: const ValueKey<String>('settings-about'),
                      icon: Icons.info_outline_rounded,
                      title: l10n.about,
                      subtitle: l10n.aboutSubtitle,
                      onTap: _openAbout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _selectedLanguageLabel(AppLocalizations l10n) {
    final tag = widget.settings.localeTag;
    if (tag == null) return l10n.followSystem;
    for (final option in LocaleSupport.options) {
      if (option.tag == tag) return option.nativeLabel;
    }
    return l10n.followSystem;
  }

  String _selectedTransferLabel(AppLocalizations l10n) {
    if (widget.settings.transferAlgorithm == TransferAlgorithm.cimbar) {
      return l10n.modeCimbar;
    }
    return switch (widget.settings.transferMode) {
      TransferMode.reliable => l10n.modeReliable,
      TransferMode.fast => l10n.modeFast,
      TransferMode.turbo => l10n.modeTurboQr,
    };
  }

  String _selectedThemeLabel(AppLocalizations l10n) {
    return switch (widget.settings.themeMode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };
  }
}

IconData _themeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => Icons.settings_suggest_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _LanguageChoiceTile extends StatelessWidget {
  const _LanguageChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      selected: selected,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.secondary.withValues(alpha: 0.18),
      onTap: onTap,
      trailing: selected ? const Icon(Icons.check_rounded) : null,
    );
  }
}

class _ThemeChoiceTile extends StatelessWidget {
  const _ThemeChoiceTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.secondary.withValues(alpha: 0.18),
      onTap: onTap,
      trailing: selected ? const Icon(Icons.check_rounded) : null,
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: scheme.onSurface, size: 22),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 51,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _DesktopUpdateSettingsDialog extends StatefulWidget {
  const _DesktopUpdateSettingsDialog({required this.updates});

  final UpdateManager updates;

  @override
  State<_DesktopUpdateSettingsDialog> createState() =>
      _DesktopUpdateSettingsDialogState();
}

class _DesktopUpdateSettingsDialogState
    extends State<_DesktopUpdateSettingsDialog> {
  String? _message;

  Future<void> _check() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _message = null);
    try {
      final outcome = await widget.updates.checkForUpdates();
      if (!mounted) return;
      switch (outcome) {
        case UpdateCheckOutcome.updateAvailable:
          Navigator.of(context).pop();
          await showOneSendUpdateDialog(context, widget.updates);
        case UpdateCheckOutcome.upToDate:
          setState(() => _message = l10n.latestVersion);
        case UpdateCheckOutcome.nativeWindowOpened:
          setState(() => _message = l10n.updateCheckWindowOpened);
        case UpdateCheckOutcome.unsupported:
          setState(() => _message = l10n.unsupportedUpdate);
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _message = widget.updates.lastError ?? l10n.updateCheckFailed,
      );
    }
  }

  Future<void> _toggleAutomaticChecks(bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.updates.setAutomaticChecksEnabled(enabled);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = widget.updates.lastError ?? l10n.automaticUpdateError;
      });
    }
  }

  Future<void> _openReleasePage() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.updates.openReleasePage();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _message = widget.updates.lastError ?? l10n.downloadPageError,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: widget.updates,
      builder: (context, _) => AlertDialog(
        title: Text(l10n.desktopUpdates),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.updateAppDescription),
              const SizedBox(height: 18),
              if (widget.updates.supportsUpdates)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.automaticChecks),
                  subtitle: Text(l10n.automaticChecksSubtitle),
                  value: widget.updates.automaticChecksEnabled,
                  onChanged: widget.updates.checking
                      ? null
                      : _toggleAutomaticChecks,
                ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(_message!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _openReleasePage,
            child: Text(l10n.downloadPage),
          ),
          if (widget.updates.supportsUpdates)
            FilledButton.tonalIcon(
              onPressed: widget.updates.checking ? null : _check,
              icon: widget.updates.checking
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                widget.updates.checking ? l10n.checking : l10n.checkForUpdates,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}

bool _isDesktopPlatform() {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => true,
    _ => false,
  };
}
