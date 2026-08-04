import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/generated/app_localizations.dart';
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

  /// Called when Save a copy returns the exported copy.
  final ValueChanged<StoredTransfer>? onSaved;

  @override
  State<StoredFileActions> createState() => _StoredFileActionsState();
}

class _StoredFileActionsState extends State<StoredFileActions> {
  late StoredTransfer _file = widget.file;
  bool _busy = false;
  bool? _exists;
  String? _message;
  bool _messageIsError = false;

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
    final l10n = AppLocalizations.of(context)!;
    await _run(() async {
      await openStoredFile(_file);
      return null;
    }, errorMessage: l10n.openFileError);
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context)!;
    await _run(() async {
      await shareStoredFile(_file);
      return null;
    }, errorMessage: l10n.shareFileError);
  }

  Future<void> _saveCopy() async {
    final l10n = AppLocalizations.of(context)!;
    await _run(
      () => saveStoredFileAs(_file),
      successMessageBuilder: (exported) => _desktop
          ? l10n.copyExportedDesktop(exported.path)
          : l10n.copyExported(exported.name),
      errorMessage: l10n.saveFileError,
    );
  }

  Future<void> _reveal() async {
    final l10n = AppLocalizations.of(context)!;
    await _run(() async {
      await revealStoredFile(_file);
      return null;
    }, errorMessage: l10n.revealFileError);
  }

  Future<void> _run(
    Future<StoredTransfer?> Function() operation, {
    String? successMessage,
    String Function(StoredTransfer exported)? successMessageBuilder,
    String? errorMessage,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
      _messageIsError = false;
    });
    try {
      final exported = await operation();
      if (!mounted) return;
      if (exported != null) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _message =
              successMessageBuilder?.call(exported) ??
              successMessage ??
              _localizedLocation(l10n, exported);
          _messageIsError = false;
        });
        widget.onSaved?.call(exported);
      } else if (successMessage != null) {
        setState(() {
          _message = successMessage;
          _messageIsError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _message = localizedTransferError(
            context,
            error,
            fallback: errorMessage ?? l10n.fileOperationError,
          );
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = _localizedLocation(l10n, _file);
    return Semantics(
      container: true,
      label: l10n.fileActions,
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
            Text(
              l10n.saveLocation,
              style: TextStyle(color: oneSendInk, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            SelectableText(
              location,
              style: const TextStyle(color: oneSendInk, height: 1.4),
            ),
            if (_exists == false) ...[
              const SizedBox(height: 6),
              Text(
                l10n.fileMissing,
                style: TextStyle(color: Color(0xffa32820), height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Semantics(
                  button: true,
                  label: l10n.openFile,
                  child: Tooltip(
                    message: l10n.openFile,
                    child: IconButton(
                      key: const ValueKey<String>('stored-file-preview'),
                      onPressed: _busy || _exists != true ? null : _open,
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('stored-file-open'),
                  onPressed: _busy || _exists != true ? null : _open,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.openFile),
                ),
                OutlinedButton.icon(
                  key: const ValueKey<String>('stored-file-share'),
                  onPressed: _busy || _exists != true ? null : _share,
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(l10n.shareFile),
                ),
                FilledButton.icon(
                  key: const ValueKey<String>('stored-file-save-as'),
                  onPressed: _busy || _exists != true ? null : _saveCopy,
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: Text(l10n.saveCopy),
                ),
                if (_desktop)
                  OutlinedButton.icon(
                    key: const ValueKey<String>('stored-file-reveal'),
                    onPressed: _busy || _exists != true ? null : _reveal,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: Text(l10n.revealInFolder),
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
                  color: _messageIsError
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

  String _localizedLocation(AppLocalizations l10n, StoredTransfer file) {
    final path = file.path.trim();
    if (path.isEmpty) return l10n.unrecordedLocation;

    if (_desktop) return l10n.savedTo(path);
    if (!kIsWeb) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          return l10n.iosSavedLocation(file.name);
        case TargetPlatform.android:
          return l10n.androidSavedLocation(file.name);
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          break;
      }
    }
    return l10n.savedTo(path);
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
