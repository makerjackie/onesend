import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/optical_transfer.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/locale_support.dart';
import '../services/app_settings.dart';
import '../services/file_service.dart';
import '../services/update_service.dart';
import '../widgets/update_ui.dart';

const Color _settingsInk = Color(0xff10130f);
const Color _settingsPaper = Color(0xfff5f6f0);
const Color _settingsPanel = Color(0xffffffff);
const Color _settingsMuted = Color(0xff667066);
const Color _settingsSelected = Color(0xffe8ebe3);
const BorderRadius _settingsRadius = BorderRadius.all(Radius.circular(6));

/// Returns the theoretical useful transfer speed in the unit shown in the UI.
///
/// This deliberately reports KB/s rather than a display cadence. The value is
/// derived from the same transport profile used by [OpticalSender].
String transferModeSpeedLabel(TransferMode mode) {
  return formatTransferSpeed(mode.usefulBytesPerSecond);
}

/// Settings page that can be pushed directly by a parent route.
///
/// [settings] is intentionally supplied by the caller so HomeScreen can share
/// one persisted [AppSettings] instance with future send flows. [updates] is
/// only used for desktop update settings. [onLanguageTap] remains an
/// injectable seam for narrow widget tests and host integrations.
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
  bool _saving = false;
  String? _message;

  bool get _desktop => widget.isDesktop ?? _isDesktopPlatform();

  bool get _showUpdateSettings =>
      _desktop && widget.updates?.supportsUpdates == true;

  Future<void> _selectMode(TransferMode mode) async {
    if (_saving || widget.settings.transferMode == mode) return;

    final modeSaveError = AppLocalizations.of(context)?.modeSaveError;
    setState(() {
      _saving = true;
      _message = null;
    });
    String? errorMessage;
    try {
      await widget.settings.setDefaultMode(mode);
    } catch (_) {
      errorMessage = modeSaveError;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = errorMessage;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _settingsPaper,
      appBar: AppBar(
        title: const Text('设置'),
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
    final mode = widget.settings.transferMode;
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
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.defaultTransferAlgorithm,
                            style: TextStyle(
                              color: _settingsInk,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.algorithmDescription,
                            style: TextStyle(
                              color: _settingsMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ModeOption(
                            key: const ValueKey<String>('settings-fast'),
                            mode: TransferMode.fast,
                            title: l10n.modeFast,
                            description: l10n.fastModeDescription(
                              l10n.theoreticalSpeed(
                                formatTransferSpeed(
                                  TransferMode.fast.usefulBytesPerSecond,
                                ),
                              ),
                            ),
                            selected: mode == TransferMode.fast,
                            enabled: !_saving,
                            onTap: () => _selectMode(TransferMode.fast),
                          ),
                          const SizedBox(height: 10),
                          _ModeOption(
                            key: const ValueKey<String>('settings-reliable'),
                            mode: TransferMode.reliable,
                            title: l10n.modeReliable,
                            description: l10n.reliableModeDescription(
                              l10n.theoreticalSpeed(
                                formatTransferSpeed(
                                  TransferMode.reliable.usefulBytesPerSecond,
                                ),
                              ),
                            ),
                            selected: mode == TransferMode.reliable,
                            enabled: !_saving,
                            onTap: () => _selectMode(TransferMode.reliable),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _message!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
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
                  if (constraints.maxWidth < 420) const SizedBox(height: 4),
                  if (!_desktop) ...[
                    const SizedBox(height: 28),
                    Text(
                      l10n.mobileOfflineNote,
                      style: TextStyle(color: _settingsMuted, height: 1.45),
                    ),
                  ],
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

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.title,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final TransferMode mode;
  final String title;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: AppLocalizations.of(context)!.modeAccessibilityLabel(
        title,
        formatTransferSpeed(mode.usefulBytesPerSecond),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: _settingsRadius,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: selected ? _settingsSelected : _settingsPanel,
              border: Border.all(color: _settingsInk, width: 2),
              borderRadius: _settingsRadius,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectionMark(selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _settingsInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: _settingsMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? _settingsInk : Colors.transparent,
        border: Border.all(color: _settingsInk, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
      child: selected
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
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
