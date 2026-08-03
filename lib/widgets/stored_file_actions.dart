import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../services/file_service.dart';

/// A small, reusable action panel for a file that has already been stored.
///
/// Keeping the async file operations here gives the receive screen and history
/// the same error handling, while [Wrap] keeps the actions usable on narrow
/// phones and small desktop windows.
class StoredFileActions extends StatefulWidget {
  const StoredFileActions({
    required this.file,
    this.isDesktop,
    this.pathExists = storedPathExists,
    this.onSaved,
    super.key,
  });

  final StoredTransfer file;

  /// Overrides platform detection for previews and widget tests.
  final bool? isDesktop;

  /// Checks whether the stored path still points to a file.
  final Future<bool> Function(String) pathExists;

  /// Called when “另存副本” returns the exported copy.
  final ValueChanged<StoredTransfer>? onSaved;

  @override
  State<StoredFileActions> createState() => _StoredFileActionsState();
}

class _StoredFileActionsState extends State<StoredFileActions> {
  late StoredTransfer _file = widget.file;
  bool _busy = false;
  bool? _exists;
  String? _message;

  bool get _desktop => widget.isDesktop ?? _isDesktopPlatform();

  @override
  void initState() {
    super.initState();
    unawaited(_checkFile());
  }

  @override
  void didUpdateWidget(covariant StoredFileActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path ||
        oldWidget.file.name != widget.file.name) {
      _file = widget.file;
      unawaited(_checkFile());
    }
  }

  Future<void> _checkFile() async {
    final path = _file.path.trim();
    if (path.isEmpty) {
      if (mounted) setState(() => _exists = false);
      return;
    }
    try {
      final exists = await widget.pathExists(path);
      if (mounted) setState(() => _exists = exists);
    } catch (_) {
      if (mounted) setState(() => _exists = false);
    }
  }

  Future<void> _open() async {
    await _run(() async {
      await openStoredFile(_file);
      return null;
    });
  }

  Future<void> _share() async {
    await _run(() async {
      await shareStoredFile(_file);
      return null;
    });
  }

  Future<void> _saveCopy() async {
    await _run(() => saveStoredFileAs(_file));
  }

  Future<void> _reveal() async {
    await _run(() async {
      await revealStoredFile(_file);
      return null;
    });
  }

  Future<void> _run(
    Future<StoredTransfer?> Function() operation, {
    String? successMessage,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final exported = await operation();
      if (!mounted) return;
      if (exported != null) {
        setState(
          () => _message = successMessage ?? exported.locationDescription,
        );
        widget.onSaved?.call(exported);
      } else if (successMessage != null) {
        setState(() => _message = successMessage);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = friendlyFileOperationError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = _file.path.trim();
    final location = path.isEmpty ? '未记录保存路径。' : _file.locationDescription;
    return Semantics(
      container: true,
      label: '文件操作',
      child: Container(
        key: const ValueKey<String>('stored-file-actions'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xfff0f2eb),
          border: Border.all(color: oneSendInk, width: 2),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '保存位置',
              style: TextStyle(color: oneSendInk, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            SelectableText(
              location,
              style: const TextStyle(color: oneSendInk, height: 1.4),
            ),
            if (_exists == false) ...[
              const SizedBox(height: 6),
              const Text(
                '文件不存在，可能已被移动或删除。',
                style: TextStyle(color: Color(0xffa32820), height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey<String>('stored-file-open'),
                  onPressed: _busy || _exists != true ? null : _open,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('打开'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('stored-file-share'),
                  onPressed: _busy || _exists != true ? null : _share,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('分享/转发'),
                ),
                FilledButton.icon(
                  key: const ValueKey<String>('stored-file-save-as'),
                  onPressed: _busy || _exists != true ? null : _saveCopy,
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text('另存副本'),
                ),
                if (_desktop)
                  OutlinedButton.icon(
                    key: const ValueKey<String>('stored-file-reveal'),
                    onPressed: _busy || _exists != true ? null : _reveal,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('在文件夹中显示'),
                  ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(
                _message!,
                style: TextStyle(
                  color:
                      _message!.contains('失败') ||
                          _message!.contains('不存在') ||
                          _message!.contains('无法')
                      ? Theme.of(context).colorScheme.error
                      : oneSendMuted,
                ),
              ),
            ],
          ],
        ),
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
