import 'dart:convert';
import 'dart:typed_data';

const List<int> _envelopeMagic = <int>[0x4c, 0x4d, 0x53, 0x31];

class TransferFile {
  const TransferFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

/// Adds filename and MIME metadata without changing the upstream 20-byte
/// optical frame header. Receivers can still open a raw upstream payload as
/// `received.bin` when no envelope is present.
Uint8List encodeTransferFile(TransferFile file) {
  final name = utf8.encode(sanitizeFileName(file.name));
  final mime = utf8.encode(file.mimeType);
  if (name.length > 0xffff || mime.length > 0xffff) {
    throw ArgumentError('file metadata is too long');
  }

  const fixedLength = 9;
  final bytes = Uint8List(
    fixedLength + name.length + mime.length + file.bytes.length,
  );
  bytes.setRange(0, 4, _envelopeMagic);
  bytes[4] = 1;
  ByteData.sublistView(bytes)
    ..setUint16(5, name.length, Endian.little)
    ..setUint16(7, mime.length, Endian.little);
  bytes.setRange(fixedLength, fixedLength + name.length, name);
  bytes.setRange(
    fixedLength + name.length,
    fixedLength + name.length + mime.length,
    mime,
  );
  bytes.setRange(
    fixedLength + name.length + mime.length,
    bytes.length,
    file.bytes,
  );
  return bytes;
}

TransferFile decodeTransferFile(Uint8List bytes) {
  const fixedLength = 9;
  final hasEnvelope =
      bytes.length >= fixedLength &&
      _envelopeMagic.asMap().entries.every(
        (entry) => bytes[entry.key] == entry.value,
      ) &&
      bytes[4] == 1;
  if (!hasEnvelope) {
    return TransferFile(
      name: 'received.bin',
      mimeType: 'application/octet-stream',
      bytes: bytes,
    );
  }

  final header = ByteData.sublistView(bytes);
  final nameLength = header.getUint16(5, Endian.little);
  final mimeLength = header.getUint16(7, Endian.little);
  final metadataEnd = fixedLength + nameLength + mimeLength;
  if (metadataEnd > bytes.length) {
    return TransferFile(
      name: 'received.bin',
      mimeType: 'application/octet-stream',
      bytes: bytes,
    );
  }

  final name = utf8.decode(
    bytes.sublist(fixedLength, fixedLength + nameLength),
    allowMalformed: true,
  );
  final mime = utf8.decode(
    bytes.sublist(fixedLength + nameLength, metadataEnd),
    allowMalformed: true,
  );
  return TransferFile(
    name: sanitizeFileName(name),
    mimeType: mime.isEmpty ? 'application/octet-stream' : mime,
    bytes: Uint8List.sublistView(bytes, metadataEnd),
  );
}

String sanitizeFileName(String name) {
  final normalized = name
      .replaceAll(RegExp(r'[\\/:*?"<>|\u0000-\u001F]'), '_')
      .trim();
  return normalized.isEmpty ? 'received.bin' : normalized;
}

String guessMimeType(String fileName) {
  final extension = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
  const types = <String, String>{
    '7z': 'application/x-7z-compressed',
    'avi': 'video/x-msvideo',
    'csv': 'text/csv',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'jpeg': 'image/jpeg',
    'jpg': 'image/jpeg',
    'json': 'application/json',
    'm4a': 'audio/mp4',
    'mkv': 'video/x-matroska',
    'mp3': 'audio/mpeg',
    'mp4': 'video/mp4',
    'pdf': 'application/pdf',
    'png': 'image/png',
    'svg': 'image/svg+xml',
    'tar': 'application/x-tar',
    'txt': 'text/plain',
    'wav': 'audio/wav',
    'webp': 'image/webp',
    'zip': 'application/zip',
  };
  return types[extension] ?? 'application/octet-stream';
}
