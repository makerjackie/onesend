import 'package:flutter/material.dart';

import '../app.dart';
import '../core/envelope.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_settings.dart';
import '../services/file_service.dart';
import '../services/transfer_store.dart';
import '../services/update_service.dart';
import '../widgets/brand_mark.dart';
import '../widgets/stored_file_actions.dart';
import '../widgets/update_ui.dart';
import 'receive_screen.dart';
import 'send_screen.dart';
import 'settings_screen.dart';

const double oneSendWideBreakpoint = 760;

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
  int _selectedTab = 0;
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
        : '${release.version}|${release.publishedAt.toIso8601String()}';
    if (release == null || releaseIdentifier == _presentedUpdateVersion) return;
    _presentedUpdateVersion = releaseIdentifier;
    await showOneSendUpdateDialog(context, widget.updates);
  }

  @override
  void dispose() {
    _fallbackSettings?.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Widget _sendRoute() {
    return SendScreen(store: widget.store, settings: _settings);
  }

  Widget _receiveRoute() {
    return ReceiveScreen(store: widget.store, settings: _settings);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= oneSendWideBreakpoint;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide) _buildNavigationRail(context, l10n),
            Expanded(child: _buildCurrentTab(context)),
          ],
        ),
      ),
      bottomNavigationBar: wide ? null : _buildNavigationBar(l10n),
    );
  }

  NavigationBar _buildNavigationBar(AppLocalizations l10n) {
    return NavigationBar(
      selectedIndex: _selectedTab,
      onDestinationSelected: _selectTab,
      destinations: [
        NavigationDestination(
          key: const ValueKey<String>('home-tab-transfer'),
          icon: const Icon(Icons.swap_horiz_rounded),
          selectedIcon: const Icon(Icons.swap_horiz_rounded),
          label: l10n.transferTab,
        ),
        NavigationDestination(
          key: const ValueKey<String>('home-tab-files'),
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder_rounded),
          label: l10n.filesTab,
        ),
        NavigationDestination(
          key: const ValueKey<String>('home-tab-settings'),
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: l10n.settings,
        ),
      ],
    );
  }

  Widget _buildNavigationRail(BuildContext context, AppLocalizations l10n) {
    final extended = MediaQuery.sizeOf(context).width >= 1040;
    return NavigationRail(
      selectedIndex: _selectedTab,
      onDestinationSelected: _selectTab,
      extended: extended,
      groupAlignment: -0.8,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: const SizedBox.square(dimension: 34),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(
            Icons.swap_horiz_rounded,
            key: ValueKey<String>('home-tab-transfer'),
          ),
          selectedIcon: const Icon(Icons.swap_horiz_rounded),
          label: Text(l10n.transferTab),
        ),
        NavigationRailDestination(
          icon: const Icon(
            Icons.folder_outlined,
            key: ValueKey<String>('home-tab-files'),
          ),
          selectedIcon: const Icon(Icons.folder_rounded),
          label: Text(l10n.filesTab),
        ),
        NavigationRailDestination(
          icon: const Icon(
            Icons.settings_outlined,
            key: ValueKey<String>('home-tab-settings'),
          ),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: Text(l10n.settings),
        ),
      ],
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    return switch (_selectedTab) {
      0 => _buildTransferTab(context),
      1 => _buildFilesTab(context),
      _ => SettingsScreen(settings: _settings, updates: widget.updates),
    };
  }

  Widget _buildTransferTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrandMark(context),
                  SizedBox(height: horizontal ? 88 : 64),
                  Text(
                    l10n.homeHeadline,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: horizontal ? 54 : 42,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Flex(
                    direction: horizontal ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: horizontal
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.stretch,
                    children: [
                      ExpandedIf(
                        enabled: horizontal,
                        child: _TransferEntry(
                          key: const ValueKey<String>('home-send'),
                          icon: Icons.north_east_rounded,
                          title: l10n.sendFile,
                          description: l10n.sendCardDescription,
                          primary: true,
                          onTap: () => _open(_sendRoute()),
                        ),
                      ),
                      SizedBox(
                        width: horizontal ? 16 : 0,
                        height: horizontal ? 0 : 14,
                      ),
                      ExpandedIf(
                        enabled: horizontal,
                        child: _TransferEntry(
                          key: const ValueKey<String>('home-receive'),
                          icon: Icons.south_west_rounded,
                          title: l10n.receiveFile,
                          description: l10n.receiveCardDescription,
                          onTap: () => _open(_receiveRoute()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilesTab(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final records = widget.store.records;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TabHeader(
                title: l10n.filesTitle,
                subtitle: l10n.filesSubtitle,
                action: records.isEmpty
                    ? null
                    : TextButton(
                        key: const ValueKey<String>('home-clear-history'),
                        onPressed: _clearHistory,
                        child: Text(l10n.clearHistory),
                      ),
              ),
              const SizedBox(height: 24),
              if (records.isEmpty)
                const _EmptyHistory()
              else
                _HistoryList(records: records),
              const SizedBox(height: 28),
              Text(
                l10n.historyFooter,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandMark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const _ThemedBrandMark()
        : const BrandMark();
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

class _ThemedBrandMark extends StatelessWidget {
  const _ThemedBrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandIcon(size: 42, borderRadius: 9),
        const SizedBox(width: 10),
        Text(
          oneSendBrandName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _TransferEntry extends StatelessWidget {
  const _TransferEntry({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.primary = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = primary
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final foreground = primary ? scheme.onPrimary : scheme.onSurface;
    return Semantics(
      button: true,
      label: '$title. $description',
      child: Material(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Icon(icon, color: foreground, size: 25),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.records});

  final List<TransferRecord> records;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < records.length; i++) ...[
              _HistoryRow(record: records[i]),
              if (i != records.length - 1) const Divider(height: 1),
            ],
          ],
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_open_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.emptyHistory,
              style: Theme.of(context).textTheme.bodyMedium,
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
    final scheme = Theme.of(context).colorScheme;
    final received = record.direction == TransferDirection.received;
    final when = _relativeTime(record.createdAt, l10n);
    final directionLabel = received
        ? l10n.receivedAndVerified
        : record.status == 'broadcast-ended'
        ? l10n.sendEnded
        : l10n.sent;
    return InkWell(
      onTap: received ? () => _showActions(context) : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: oneSendLime.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  received
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  color: scheme.onSurface,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$directionLabel · $when',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatBytes(record.bytes),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (received) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final stored = StoredTransfer(
      name: record.fileName,
      mimeType: guessMimeType(record.fileName),
      bytes: record.bytes,
      path: record.path ?? '',
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                          style: Theme.of(context).textTheme.titleLarge,
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
                  Text(
                    record.fileName,
                    style: Theme.of(context).textTheme.titleMedium,
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
