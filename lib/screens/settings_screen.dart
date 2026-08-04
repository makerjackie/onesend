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

const Color _settingsInk = Color(0xff10130f);
const Color _settingsPaper = Color(0xfff5f6f0);
const Color _settingsPanel = Color(0xffffffff);
const Color _settingsMuted = Color(0xff667066);
const BorderRadius _settingsRadius = BorderRadius.all(Radius.circular(6));

/// Settings page: language and desktop updates only.
/// Transfer mode is chosen on the send/receive screens.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.settings,
    this.updates,
    this.onLanguageTap,
    this.isDesktop,
    super.key,
  });

  final AppSettings settings;
  final UpdateManager? updates;
  final VoidCallback? onLanguageTap;

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

  Future<void> _openUpdateSettings() async {
    final updates = widget.updates;
    if (!_showUpdateSettings || updates == null) return;
    await showOneSendUpdateSettings(context, updates);
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
                      style: const TextStyle(
                        color: _settingsMuted,
                        height: 1.4,
                      ),
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
    return Scaffold(
      backgroundColor: _settingsPaper,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? '设置'),
        backgroundColor: _settingsPaper,
        foregroundColor: _settingsInk,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsIntroTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _settingsInk,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.settingsIntroBody,
                    style: TextStyle(color: _settingsMuted, height: 1.45),
                  ),
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
                  const SizedBox(height: 28),
                  _SectionLabel(label: l10n.appSection),
                  const SizedBox(height: 8),
                  _SettingsPanel(
                    child: Column(
                      children: [
                        _SettingRow(
                          key: const ValueKey<String>('settings-language'),
                          icon: Icons.translate_rounded,
                          title: l10n.language,
                          subtitle: l10n.languageSubtitle(
                            _selectedLanguageLabel(l10n),
                          ),
                          onTap: _openLanguageEntry,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _settingsMuted,
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _settingsPanel,
        border: Border.fromBorderSide(
          BorderSide(color: _settingsInk, width: 2),
        ),
        borderRadius: _settingsRadius,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: _settingsInk, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _settingsInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _settingsMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded, color: _settingsInk),
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
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 48,
      color: Color(0xffd6dbd2),
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
