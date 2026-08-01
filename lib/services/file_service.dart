import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/envelope.dart';

const int maxTransferBytes = maxTransferFileBytes;

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
  });

  final String name;
  final String mimeType;
  final int bytes;
  final String path;
}

Future<PickedTransfer?> pickTransferFile() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    withData: false,
    type: FileType.any,
  );
  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.single;
  if (picked.size > maxTransferBytes) {
    throw StateError('文件不能超过 64 MB。');
  }
  Uint8List? bytes = picked.bytes;
  final path = picked.path;
  if (bytes == null && path != null) {
    bytes = await File(path).readAsBytes();
  }
  if (bytes == null) {
    throw StateError('OneSend 无法读取这个文件。');
  }
  if (bytes.length > maxTransferBytes) {
    throw StateError('文件不能超过 64 MB。');
  }

  return PickedTransfer(
    name: sanitizeFileName(picked.name),
    bytes: bytes,
    mimeType: guessMimeType(picked.name),
    sourcePath: path,
  );
}

Future<StoredTransfer> saveReceivedFile(TransferFile file) async {
  final Directory baseDirectory;
  if (Platform.isAndroid || Platform.isIOS) {
    baseDirectory = await getApplicationDocumentsDirectory();
  } else {
    baseDirectory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
  }

  final directory = Directory(
    p.join(baseDirectory.path, 'OneSend', 'Received'),
  );
  await directory.create(recursive: true);
  final path = await _uniquePath(directory.path, sanitizeFileName(file.name));
  await File(path).writeAsBytes(file.bytes, flush: true);
  return StoredTransfer(
    name: p.basename(path),
    mimeType: file.mimeType,
    bytes: file.bytes.length,
    path: path,
  );
}

Future<void> shareStoredFile(StoredTransfer file) async {
  await SharePlus.instance.share(
    ShareParams(files: <XFile>[XFile(file.path)], text: 'Sent with OneSend'),
  );
}

Future<void> openStoredFile(StoredTransfer file) => openStoredPath(file.path);

Future<void> openStoredPath(String path) async {
  final result = await OpenFilex.open(path);
  if (result.type != ResultType.done) {
    throw StateError(result.message.isEmpty ? '系统无法打开这个文件。' : result.message);
  }
}

Future<String> _uniquePath(String directory, String fileName) async {
  var path = p.join(directory, fileName);
  if (!await File(path).exists()) return path;

  final extension = p.extension(fileName);
  final stem = extension.isEmpty
      ? fileName
      : fileName.substring(0, fileName.length - extension.length);
  for (var index = 2; index < 10000; index++) {
    path = p.join(directory, '$stem ($index)$extension');
    if (!await File(path).exists()) return path;
  }
  return p.join(
    directory,
    '${DateTime.now().microsecondsSinceEpoch}-$fileName',
  );
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
