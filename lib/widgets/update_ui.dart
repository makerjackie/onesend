import 'package:flutter/material.dart';

import '../app.dart';
import '../services/update_service.dart';

Future<void> showOneSendUpdateSettings(
  BuildContext context,
  UpdateManager updates,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => _UpdateSettingsDialog(updates: updates),
  );
}

Future<void> showOneSendUpdateDialog(
  BuildContext context,
  UpdateManager updates,
) {
  if (updates.availableRelease == null) return Future<void>.value();
  return showDialog<void>(
    context: context,
    // The barrier behavior cannot change after showDialog is created. Keep it
    // non-dismissible so a click outside cannot abandon a download halfway.
    barrierDismissible: false,
    builder: (context) => _AvailableUpdateDialog(updates: updates),
  );
}

class _UpdateSettingsDialog extends StatefulWidget {
  const _UpdateSettingsDialog({required this.updates});

  final UpdateManager updates;

  @override
  State<_UpdateSettingsDialog> createState() => _UpdateSettingsDialogState();
}

class _UpdateSettingsDialogState extends State<_UpdateSettingsDialog> {
  String? _message;

  Future<void> _check() async {
    setState(() => _message = null);
    try {
      final outcome = await widget.updates.checkForUpdates();
      if (!mounted) return;
      switch (outcome) {
        case UpdateCheckOutcome.updateAvailable:
          Navigator.of(context).pop();
          break;
        case UpdateCheckOutcome.upToDate:
          setState(() => _message = '已经是最新版本。');
          break;
        case UpdateCheckOutcome.nativeWindowOpened:
          setState(() => _message = '更新检查窗口已打开。');
          break;
        case UpdateCheckOutcome.unsupported:
          setState(() => _message = '当前平台不支持应用内更新。');
          break;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = widget.updates.lastError ?? '检查更新失败，请稍后重试。');
    }
  }

  Future<void> _toggleAutomaticChecks(bool enabled) async {
    try {
      await widget.updates.setAutomaticChecksEnabled(enabled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = widget.updates.lastError ?? '无法修改自动更新设置。');
    }
  }

  Future<void> _openReleasePage() async {
    try {
      await widget.updates.openReleasePage();
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = widget.updates.lastError ?? '无法打开下载页面。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.updates,
      builder: (context, _) {
        return AlertDialog(
          title: const Text('OneSend · 扫传'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '屏幕与摄像头之间的离线文件传输。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _InfoLine(
                  label: '当前版本',
                  value: widget.updates.currentVersionLabel,
                ),
                if (widget.updates.supportsUpdates) ...[
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('自动检查更新'),
                    subtitle: const Text('每天静默检查一次；发现新版本时再提示。'),
                    value: widget.updates.automaticChecksEnabled,
                    onChanged: widget.updates.checking
                        ? null
                        : _toggleAutomaticChecks,
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          _message!.contains('失败') || _message!.contains('无法')
                          ? Theme.of(context).colorScheme.error
                          : oneSendMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: _openReleasePage, child: const Text('下载页面')),
            if (widget.updates.supportsUpdates)
              FilledButton.tonalIcon(
                onPressed: widget.updates.checking ? null : _check,
                icon: widget.updates.checking
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(widget.updates.checking ? '检查中' : '检查更新'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('完成'),
            ),
          ],
        );
      },
    );
  }
}

class _AvailableUpdateDialog extends StatefulWidget {
  const _AvailableUpdateDialog({required this.updates});

  final UpdateManager updates;

  @override
  State<_AvailableUpdateDialog> createState() => _AvailableUpdateDialogState();
}

class _AvailableUpdateDialogState extends State<_AvailableUpdateDialog> {
  String? _error;

  Future<void> _openReleasePage() async {
    try {
      await widget.updates.openReleasePage();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = widget.updates.lastError ?? '无法打开发布页面。');
    }
  }

  Future<void> _download() async {
    setState(() => _error = null);
    try {
      await widget.updates.downloadAvailableUpdate();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = widget.updates.lastError ?? '更新包下载失败，请稍后重试。');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.updates,
      builder: (context, _) {
        final release = widget.updates.availableRelease;
        if (release == null) return const SizedBox.shrink();
        final progress = widget.updates.downloadProgress;
        return PopScope(
          canPop: !widget.updates.downloading,
          child: AlertDialog(
            title: Text('OneSend ${release.version} 可用'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('更新内容', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  for (final note in release.notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(note)),
                        ],
                      ),
                    ),
                  if (widget.updates.downloading) ...[
                    const SizedBox(height: 14),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      progress == null
                          ? '正在下载并校验…'
                          : '正在下载并校验 ${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: widget.updates.downloading ? null : _openReleasePage,
                child: const Text('查看发布页'),
              ),
              TextButton(
                onPressed: widget.updates.downloading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('稍后'),
              ),
              FilledButton.icon(
                onPressed: widget.updates.downloading ? null : _download,
                icon: const Icon(Icons.download_rounded),
                label: const Text('下载更新'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 24),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
