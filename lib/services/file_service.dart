import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/envelope.dart';

const int maxTransferBytes = maxTransferFileBytes;
const int bytesPerKilobyte = 1024;

class PickedTransfer {
  const PickedTransfer({
    required this.name,
    required this.bytes,
    required this.mimeType,
    this.sourcePath,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;
  final String? sourcePath;
}

class StoredTransfer {
  const StoredTransfer({
    required this.name,
    required this.mimeType,
    required this.bytes,
    required this.path,
    this.locationDescriptionOverride,
  });

  final String name;
  final String mimeType;
  final int bytes;
  final String path;
  final String? locationDescriptionOverride;

  String get locationDescription =>
      locationDescriptionOverride ?? describeStoredFileLocation(path);
}

Future<PickedTransfer?> pickTransferFile() async {
  try {
    final picked = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'All files', extensions: <String>[]),
      ],
    );
    if (picked == null) return null;

    if (await picked.length() > maxTransferBytes) {
      throw StateError('文件不能超过 64 MB。');
    }
    final bytes = await picked.readAsBytes();
    if (bytes.length > maxTransferBytes) {
      throw StateError('文件不能超过 64 MB。');
    }

    return PickedTransfer(
      name: safeStorageFileName(picked.name),
      bytes: bytes,
      mimeType: picked.mimeType ?? guessMimeType(picked.name),
      sourcePath: picked.path,
    );
  } catch (error) {
    throw _userError(error, fallback: '无法选择文件，请重试。');
  }
}

Future<StoredTransfer> saveReceivedFile(
  TransferFile file, {
  Directory? baseDirectory,
  String? operatingSystem,
}) async {
  try {
    if (file.bytes.length > maxTransferBytes) {
      throw StateError('文件不能超过 64 MB。');
    }
    final resolvedBaseDirectory =
        baseDirectory ?? await _defaultBaseDirectory();
    final directory = Directory(
      receivedDirectoryPath(
        resolvedBaseDirectory.path,
        operatingSystem: operatingSystem,
      ),
    );
    await directory.create(recursive: true);
    final path = await _uniquePath(directory.path, file.name);
    await File(path).writeAsBytes(file.bytes, flush: true);
    return StoredTransfer(
      name: p.basename(path),
      mimeType: file.mimeType,
      bytes: file.bytes.length,
      path: path,
      locationDescriptionOverride: operatingSystem == null
          ? null
          : describeStoredFileLocation(path, operatingSystem: operatingSystem),
    );
  } catch (error) {
    throw _userError(error, fallback: '无法保存接收的文件，请重试。');
  }
}

Future<void> shareStoredFile(StoredTransfer file) async {
  try {
    await _requireExistingFile(file.path, '分享文件');
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile(
            file.path,
            name: safeStorageFileName(file.name),
            mimeType: file.mimeType,
          ),
        ],
        text: 'Sent with OneSend',
      ),
    );
  } catch (error) {
    throw _userError(error, fallback: '无法分享这个文件，请重试。');
  }
}

Future<void> openStoredFile(StoredTransfer file) => openStoredPath(file.path);

Future<void> openStoredPath(String path) async {
  try {
    await _requireExistingFile(path, '打开文件');
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw StateError('系统无法打开这个文件。');
    }
  } catch (error) {
    throw _userError(error, fallback: '系统无法打开这个文件。');
  }
}

/// Opens a native save dialog and exports an independent copy of [file].
///
/// On desktop it opens the native save dialog in the source file's directory.
Future<StoredTransfer?> saveStoredFileAs(StoredTransfer file) async {
  try {
    await _requireExistingFile(file.path, '导出文件');
    final bytes = await File(file.path).readAsBytes();
    final defaultName = safeStorageFileName(
      file.name.isEmpty ? p.basename(file.path) : file.name,
    );
    final location = await getSaveLocation(
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'All files', extensions: <String>[]),
      ],
      suggestedName: defaultName,
      initialDirectory: _saveDialogDirectory(file.path),
    );
    if (location == null) return null;

    final outputPath = _validateSelectedPath(location.path);
    await File(outputPath).writeAsBytes(bytes, flush: true);
    if (!Platform.isAndroid && !await File(outputPath).exists()) {
      throw StateError('导出失败：系统未生成目标文件。');
    }
    return StoredTransfer(
      name: safeStorageFileName(p.basename(outputPath)),
      mimeType: file.mimeType,
      bytes: bytes.length,
      path: outputPath,
      locationDescriptionOverride: _exportLocationDescription(outputPath),
    );
  } catch (error) {
    throw _userError(error, fallback: '无法导出文件，请重试。');
  }
}

Future<void> revealStoredFile(StoredTransfer file) =>
    revealStoredPath(file.path);

/// Returns whether a stored transfer still points to a regular file.
///
/// History may outlive a file that the user moved or deleted, so callers can
/// disable actions while still showing the original location and a clear
/// explanation.
Future<bool> storedPathExists(String path) async {
  final cleanPath = path.trim();
  if (cleanPath.isEmpty) return false;
  try {
    return await FileSystemEntity.type(cleanPath, followLinks: true) ==
        FileSystemEntityType.file;
  } catch (_) {
    return false;
  }
}

/// Reveals a file in the native desktop file manager.
Future<void> revealStoredPath(
  String path, {
  Future<ProcessResult> Function(String, List<String>)? processRunner,
}) async {
  try {
    await _requireExistingFile(path, '显示文件所在文件夹');
    final command = desktopRevealCommand(path);
    final run =
        processRunner ??
        (String executable, List<String> arguments) =>
            Process.run(executable, arguments);
    final result = await run(command.executable, command.arguments);
    if (result.exitCode != 0) {
      throw StateError('无法打开文件所在文件夹。');
    }
  } catch (error) {
    throw _userError(error, fallback: '无法打开文件所在文件夹，请重试。');
  }
}

/// The command used by [revealStoredPath]. This is pure when [operatingSystem]
/// is supplied, which keeps platform-specific behavior unit-testable.
DesktopRevealCommand desktopRevealCommand(
  String path, {
  String? operatingSystem,
}) {
  final cleanPath = path.trim();
  if (cleanPath.isEmpty) {
    throw StateError('显示文件所在文件夹失败：文件路径为空。');
  }
  final system = operatingSystem ?? Platform.operatingSystem;
  switch (system) {
    case 'macos':
      return DesktopRevealCommand('open', <String>['-R', cleanPath]);
    case 'windows':
      return DesktopRevealCommand('explorer.exe', <String>[
        '/select,$cleanPath',
      ]);
    case 'linux':
      return DesktopRevealCommand('xdg-open', <String>[
        p.posix.dirname(cleanPath),
      ]);
    default:
      throw StateError('当前设备不支持显示文件所在文件夹。');
  }
}

class DesktopRevealCommand {
  const DesktopRevealCommand(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}

/// Sanitizes a received or exported filename for use as one path component.
String safeStorageFileName(String name) {
  var safeName = sanitizeFileName(name).replaceAll(RegExp(r'[ .]+$'), '');
  if (safeName.isEmpty || safeName == '.' || safeName == '..') {
    safeName = 'received.bin';
  }

  final stem = p.basenameWithoutExtension(safeName);
  if (RegExp(
    r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
    caseSensitive: false,
  ).hasMatch(stem)) {
    safeName = '_$safeName';
  }

  if (safeName.length > 255) {
    final extension = p.extension(safeName);
    final maximumStemLength = 255 - extension.length;
    if (maximumStemLength <= 0) {
      safeName = safeName.substring(0, 255);
    } else {
      final originalStem = p.basenameWithoutExtension(safeName);
      safeName = '${originalStem.substring(0, maximumStemLength)}$extension';
    }
  }
  return safeName;
}

String describeStoredFileLocation(
  String path, {
  bool? mobile,
  String? operatingSystem,
}) {
  final cleanPath = path.trim();
  if (cleanPath.isEmpty) return '保存位置未知。';
  final system =
      (operatingSystem ??
              (mobile == null
                  ? Platform.operatingSystem
                  : mobile
                  ? 'android'
                  : 'desktop'))
          .toLowerCase();
  switch (system) {
    case 'ios':
      final name = safeStorageFileName(p.basename(cleanPath));
      return '文件 App > 我的 iPhone/iPad > OneSend > Received > $name';
    case 'android':
      final name = safeStorageFileName(p.basename(cleanPath));
      return '已保存到应用存储：$name；点“另存副本”选择可见文件夹。';
    default:
      return '已保存到：$cleanPath';
  }
}

/// Returns the app's received-files directory for a platform-independent base
/// directory. iOS and Android already expose the app's Documents directory as
/// the app container, while desktop keeps the visible Downloads/OneSend tree.
String receivedDirectoryPath(String basePath, {String? operatingSystem}) {
  final cleanBasePath = basePath.trim();
  if (cleanBasePath.isEmpty) {
    throw ArgumentError.value(basePath, 'basePath', 'must not be empty');
  }
  final system = (operatingSystem ?? Platform.operatingSystem).toLowerCase();
  if (system == 'android' || system == 'ios') {
    return p.join(cleanBasePath, 'Received');
  }
  final baseName = p.basename(cleanBasePath).toLowerCase();
  final oneSendRoot = baseName == 'onesend'
      ? cleanBasePath
      : p.join(cleanBasePath, 'OneSend');
  return p.join(oneSendRoot, 'Received');
}

String friendlyFileOperationError(
  Object error, {
  String fallback = '文件操作失败，请重试。',
}) {
  if (error is StateError) {
    final message = error.message.toString().trim();
    if (message.contains(RegExp(r'[\u3400-\u9fff]'))) return message;
  }
  final text = error.toString().toLowerCase();
  if (text.contains('no such file') ||
      text.contains('not found') ||
      text.contains('cannot find')) {
    return '文件不存在。';
  }
  if (text.contains('permission') || text.contains('access denied')) {
    return '没有权限访问这个文件。';
  }
  if (text.contains('cancel')) return '操作已取消。';
  if (text.contains('unsupported') || text.contains('unimplemented')) {
    return '当前设备不支持这个操作。';
  }
  return fallback;
}

Future<String> _uniquePath(String directory, String fileName) async {
  final safeName = safeStorageFileName(fileName);
  var path = p.join(directory, safeName);
  if (!await File(path).exists()) return path;

  final extension = p.extension(safeName);
  final stem = extension.isEmpty
      ? safeName
      : safeName.substring(0, safeName.length - extension.length);
  for (var index = 2; index < 10000; index++) {
    path = p.join(directory, '$stem ($index)$extension');
    if (!await File(path).exists()) return path;
  }
  return p.join(
    directory,
    '${DateTime.now().microsecondsSinceEpoch}-$safeName',
  );
}

Future<Directory> _defaultBaseDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return getApplicationDocumentsDirectory();
  }
  return await getDownloadsDirectory() ?? getApplicationDocumentsDirectory();
}

String? _saveDialogDirectory(String path) {
  if (Platform.isAndroid || Platform.isIOS) return null;
  return p.dirname(path);
}

String _validateSelectedPath(String path) {
  final cleanPath = path.trim();
  if (cleanPath.isEmpty) throw StateError('导出失败：没有选择保存位置。');
  if (cleanPath.contains(RegExp(r'[\u0000-\u001f]'))) {
    throw StateError('导出失败：保存位置无效。');
  }
  final name = p.basename(cleanPath);
  if (name.isEmpty || name == '.' || name == '..') {
    throw StateError('导出失败：请选择有效的文件名。');
  }
  return cleanPath;
}

String _exportLocationDescription(String path) {
  if (Platform.isAndroid || Platform.isIOS) {
    return '副本已导出：${safeStorageFileName(p.basename(path))}（位置由系统文件选择器决定）';
  }
  return '副本已导出到：$path';
}

Future<void> _requireExistingFile(String path, String action) async {
  final cleanPath = path.trim();
  if (cleanPath.isEmpty) throw StateError('$action失败：文件路径为空。');
  try {
    final type = await FileSystemEntity.type(cleanPath, followLinks: true);
    if (type == FileSystemEntityType.notFound) {
      throw StateError('$action失败：文件不存在。');
    }
    if (type != FileSystemEntityType.file) {
      throw StateError('$action失败：目标不是一个文件。');
    }
  } catch (error) {
    throw _userError(error, fallback: '$action失败：无法访问文件。');
  }
}

StateError _userError(Object error, {required String fallback}) =>
    StateError(friendlyFileOperationError(error, fallback: fallback));

/// Formats a transfer rate using the decimal KB/s shown in the product UI.
String formatTransferSpeed(double bytesPerSecond) {
  final kilobytes = bytesPerSecond / 1000;
  final display = kilobytes < 10
      ? ((kilobytes * 10).ceil() / 10).toStringAsFixed(1)
      : kilobytes.round().toString();
  return '$display KB/s';
}

String formatBytes(int bytes) {
  if (bytes < bytesPerKilobyte) return '$bytes B';
  if (bytes < bytesPerKilobyte * bytesPerKilobyte) {
    return '${(bytes / bytesPerKilobyte).toStringAsFixed(1)} KB';
  }
  if (bytes < bytesPerKilobyte * bytesPerKilobyte * bytesPerKilobyte) {
    return '${(bytes / (bytesPerKilobyte * bytesPerKilobyte)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (bytesPerKilobyte * bytesPerKilobyte * bytesPerKilobyte)).toStringAsFixed(1)} GB';
}
