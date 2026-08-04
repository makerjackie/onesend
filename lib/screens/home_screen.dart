import 'package:flutter/material.dart';

import '../app.dart';
import '../core/envelope.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/file_service.dart';
import '../services/transfer_store.dart';
import '../services/update_service.dart';
import '../widgets/brand_mark.dart';
import '../widgets/file_tile.dart';
import '../widgets/stored_file_actions.dart';
import '../widgets/update_ui.dart';
import 'about_screen.dart';
import 'receive_screen.dart';
import 'send_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.store,
    required this.updates,
    this.settings,
    super.key,
  });

  final TransferStore store;
  final UpdateManager updates;
  final AppSettings? settings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _presentedUpdateVersion;
  AppSettings? _fallbackSettings;

  AppSettings get _settings =>
      widget.settings ?? (_fallbackSettings ??= AppSettings());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performStartupUpdateCheck();
    });
  }

  Future<void> _performStartupUpdateCheck() async {
    await widget.updates.performStartupCheck();
    if (!mounted) return;
    await _showAvailableUpdateIfNeeded();
  }

  Future<void> _showAvailableUpdateIfNeeded() async {
    final release = widget.updates.availableRelease;
    final releaseIdentifier = release == null
        ? null
        : '${release.version}+${release.buildNumber}';
    if (release == null || releaseIdentifier == _presentedUpdateVersion) return;
    _presentedUpdateVersion = releaseIdentifier;
    await showOneSendUpdateDialog(context, widget.updates);
  }

  Future<void> _openSettings() async {
    await _open(SettingsScreen(settings: _settings, updates: widget.updates));
  }

  Future<void> _openAbout() async {
    await _open(const AboutScreen());
  }

  @override
  void dispose() {
    _fallbackSettings?.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Future<void> _clearHistory() async {
    if (widget.store.records.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearHistoryQuestion),
        content: Text(l10n.clearHistoryDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clearAction),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.store.clear();
      if (mounted) setState(() {});
    }
  }

  /// Always open the shared send/receive routes. Transfer mode (QR profiles
  /// and experimental CIMBAR color codes) is switched inside those screens so
  /// users never jump into a separate experiment window.
  Widget _sendRoute() {
    return SendScreen(store: widget.store, settings: _settings);
  }

  Widget _receiveRoute() {
    return ReceiveScreen(store: widget.store, settings: _settings);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final records = widget.store.records;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: BrandMark(),
                            ),
                          ),
                          IconButton(
                            key: const ValueKey<String>('home-settings'),
                            tooltip: l10n.settings,
                            onPressed: _openSettings,
                            icon: const Icon(Icons.settings_outlined),
                          ),
                          IconButton(
                            key: const ValueKey<String>('home-about'),
                            tooltip: l10n.about,
                            onPressed: _openAbout,
                            icon: const Icon(Icons.info_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),
                      Text(
                        l10n.homeHeadline,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: horizontal ? 52 : 42,
                              height: 1.04,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.homeSubtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: oneSendMuted),
                      ),
                      const SizedBox(height: 34),
                      Flex(
                        direction: horizontal ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: horizontal
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.stretch,
                        children: [
                          ExpandedIf(
                            enabled: horizontal,
                            child: _ActionCard(
                              icon: Icons.north_east_rounded,
                              eyebrow: l10n.sendEyebrow,
                              title: l10n.sendFile,
                              description: l10n.sendCardDescription,
                              accent: oneSendLime,
                              onTap: () => _open(_sendRoute()),
                            ),
                          ),
                          SizedBox(
                            width: horizontal ? 16 : 0,
                            height: horizontal ? 0 : 16,
                          ),
                          ExpandedIf(
                            enabled: horizontal,
                            child: _ActionCard(
                              icon: Icons.center_focus_strong_rounded,
                              eyebrow: l10n.receiveEyebrow,
                              title: l10n.receiveFile,
                              description: l10n.receiveCardDescription,
                              accent: const Color(0xffe2e5de),
                              onTap: () => _open(_receiveRoute()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 42),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.recentTransfers,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (records.isNotEmpty) ...[
                            Text(
                              l10n.recordCount(records.length),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              key: const ValueKey<String>('home-clear-history'),
                              onPressed: _clearHistory,
                              child: Text(l10n.clearHistory),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (records.isEmpty)
                        const _EmptyHistory()
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 6,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < records.length; i++) ...[
                                  _HistoryRow(record: records[i]),
                                  if (i != records.length - 1)
                                    const Divider(height: 1),
                                ],
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          l10n.historyFooter,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: oneSendMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ExpandedIf extends StatelessWidget {
  const ExpandedIf({required this.enabled, required this.child, super.key});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      enabled ? Expanded(child: child) : child;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $description',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
            side: BorderSide(color: oneSendInk, width: 2),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accent,
                          border: Border.all(color: oneSendInk, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(icon, color: oneSendInk, size: 25),
                      ),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        color: oneSendMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: oneSendMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        border: Border.all(color: oneSendInk, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined, color: oneSendMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.emptyHistory,
              style: TextStyle(color: oneSendMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record});

  final TransferRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final received = record.direction == TransferDirection.received;
    final when = _relativeTime(record.createdAt, l10n);
    final directionLabel = received
        ? l10n.receivedAndVerified
        : record.status == 'broadcast-ended'
        ? l10n.sendEnded
        : l10n.sent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: FileTile(
        name: record.fileName,
        bytes: record.bytes,
        icon: received ? Icons.south_west_rounded : Icons.north_east_rounded,
        subtitle: '$directionLabel · $when',
        onTap: received ? () => _showActions(context) : null,
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final path = record.path ?? '';
    final stored = StoredTransfer(
      name: record.fileName,
      mimeType: guessMimeType(record.fileName),
      bytes: record.bytes,
      path: path,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.receivedFileActions,
                          style: const TextStyle(
                            color: oneSendInk,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.close,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FileTile(
                    name: record.fileName,
                    bytes: record.bytes,
                    icon: Icons.south_west_rounded,
                  ),
                  const SizedBox(height: 12),
                  StoredFileActions(file: stored),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime date, AppLocalizations l10n) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return l10n.justNow;
    if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    }
    if (difference.inDays < 1) return l10n.hoursAgo(difference.inHours);
    if (difference.inDays < 7) return l10n.daysAgo(difference.inDays);
    return l10n.monthDay(date.day, date.month);
  }
}
