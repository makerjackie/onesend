import 'package:flutter/material.dart';

import '../app.dart';
import '../services/file_service.dart';
import '../services/transfer_store.dart';
import '../widgets/brand_mark.dart';
import '../widgets/file_tile.dart';
import 'receive_screen.dart';
import 'send_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.store, super.key});

  final TransferStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Future<void> _clearHistory() async {
    if (widget.store.records.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空记录？'),
        content: const Text('只会清除 OneSend 里的传输记录，不会删除已经保存的文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空'),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const BrandMark(),
                          IconButton(
                            onPressed: records.isEmpty ? null : _clearHistory,
                            tooltip: '清空记录',
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),
                      Text(
                        '文件，\n用光传过去。',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: horizontal ? 52 : 42,
                              height: 1.04,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'OneSend · 扫传\n无需网络、无需配对，只要一块屏幕和一枚摄像头。',
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
                              eyebrow: 'SEND',
                              title: '发送文件',
                              description: '把二维码放到屏幕上，另一台设备对准它。',
                              accent: oneSendLime,
                              onTap: () =>
                                  _open(SendScreen(store: widget.store)),
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
                              eyebrow: 'RECEIVE',
                              title: '扫描接收',
                              description: '打开摄像头，持续扫描变化中的二维码。',
                              accent: const Color(0xffdce9ff),
                              onTap: () =>
                                  _open(ReceiveScreen(store: widget.store)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 42),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '最近传输',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (records.isNotEmpty)
                            Text(
                              '${records.length} 条',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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
                          '屏幕 ↔ 摄像头 · 文件只在两台设备之间经过光传递',
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
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
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(icon, color: oneSendInk, size: 25),
                  ),
                  const Icon(Icons.arrow_outward_rounded, color: oneSendMuted),
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
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdfe3da)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.wb_sunny_outlined, color: oneSendMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '还没有传输记录。选一个文件，开始第一次光传。',
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
    final received = record.direction == TransferDirection.received;
    final when = _relativeTime(record.createdAt);
    final canOpen = received && record.path != null;
    final directionLabel = received
        ? '收到并校验'
        : record.status == 'broadcast-ended'
        ? '发送已结束'
        : '发出';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: FileTile(
        name: record.fileName,
        bytes: record.bytes,
        icon: received ? Icons.south_west_rounded : Icons.north_east_rounded,
        subtitle: '$directionLabel · $when',
        onTap: canOpen ? () => _openFile(context, record.path!) : null,
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String path) async {
    try {
      await openStoredPath(path);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  String _relativeTime(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return '刚刚';
    if (difference.inHours < 1) return '${difference.inMinutes} 分钟前';
    if (difference.inDays < 1) return '${difference.inHours} 小时前';
    if (difference.inDays < 7) return '${difference.inDays} 天前';
    return '${date.month}/${date.day}';
  }
}
