import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'protocol.dart';

const List<int> _envelopeMagic = <int>[0x4c, 0x4d, 0x53, 0x31];
const int _currentEnvelopeVersion = 2;
const int _gzipFlag = 1;
const int _v1FixedLength = 9;
const int _v2FixedLength = 26;
const int _minimumCompressionSavings = 64;
const int _maximumGenericCompressionBytes = 16 * 1024 * 1024;
const int maxTransferFileBytes = 64 * 1024 * 1024;
const int maxTransferEnvelopeBytes = 72 * 1024 * 1024;

class TransferFile {
  const TransferFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
    this.wasCompressed = false,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
  final bool wasCompressed;
}

/// Adds sanitized filename and MIME metadata, independent checksums for the
/// stored and original data, and opportunistic gzip compression.
Uint8List encodeTransferFile(
  TransferFile file, {
  bool enableCompression = true,
}) {
  final name = utf8.encode(sanitizeFileName(file.name));
  final mime = utf8.encode(file.mimeType);
  if (name.length > 0xffff || mime.length > 0xffff) {
    throw ArgumentError('file metadata is too long');
  }
  if (file.bytes.length > maxTransferFileBytes) {
    throw ArgumentError('files must be 64 MB or smaller');
  }

  var stored = file.bytes;
  var flags = 0;
  if (enableCompression && _shouldAttemptCompression(file)) {
    final candidate = Uint8List.fromList(gzip.encode(file.bytes));
    if (candidate.length + _minimumCompressionSavings < file.bytes.length) {
      stored = candidate;
      flags |= _gzipFlag;
    }
  }

  final bytes = Uint8List(
    _v2FixedLength + name.length + mime.length + stored.length,
  );
  bytes.setRange(0, 4, _envelopeMagic);
  bytes[4] = _currentEnvelopeVersion;
  bytes[5] = flags;
  ByteData.sublistView(bytes)
    ..setUint16(6, name.length, Endian.little)
    ..setUint16(8, mime.length, Endian.little)
    ..setUint32(10, file.bytes.length, Endian.little)
    ..setUint32(14, crc32(file.bytes), Endian.little)
    ..setUint32(18, stored.length, Endian.little)
    ..setUint32(22, crc32(stored), Endian.little);
  final metadataStart = _v2FixedLength;
  final mimeStart = metadataStart + name.length;
  final dataStart = mimeStart + mime.length;
  bytes.setRange(metadataStart, mimeStart, name);
  bytes.setRange(mimeStart, dataStart, mime);
  bytes.setRange(dataStart, bytes.length, stored);
  return bytes;
}

TransferFile decodeTransferFile(Uint8List bytes) {
  if (bytes.length > maxTransferEnvelopeBytes) {
    throw const FormatException('OneSend file envelope exceeds 72 MB.');
  }
  if (!_hasMagic(bytes)) {
    if (bytes.length > maxTransferFileBytes) {
      throw const FormatException('Received file exceeds 64 MB.');
    }
    return _rawTransferFile(bytes);
  }
  if (bytes.length < 5) {
    throw const FormatException('OneSend file envelope is truncated.');
  }
  return switch (bytes[4]) {
    1 => _decodeV1(bytes),
    _currentEnvelopeVersion => _decodeV2(bytes),
    _ => throw FormatException(
      'Unsupported OneSend file envelope version ${bytes[4]}.',
    ),
  };
}

TransferFile _decodeV1(Uint8List bytes) {
  if (bytes.length < _v1FixedLength) {
    throw const FormatException('Legacy OneSend file envelope is truncated.');
  }
  final header = ByteData.sublistView(bytes);
  final nameLength = header.getUint16(5, Endian.little);
  final mimeLength = header.getUint16(7, Endian.little);
  final metadataEnd = _v1FixedLength + nameLength + mimeLength;
  if (metadataEnd > bytes.length) {
    throw const FormatException('Legacy OneSend file metadata is invalid.');
  }
  if (bytes.length - metadataEnd > maxTransferFileBytes) {
    throw const FormatException('Legacy OneSend file exceeds 64 MB.');
  }
  return TransferFile(
    name: _decodeName(bytes, _v1FixedLength, nameLength),
    mimeType: _decodeMime(bytes, _v1FixedLength + nameLength, mimeLength),
    bytes: Uint8List.sublistView(bytes, metadataEnd),
  );
}

TransferFile _decodeV2(Uint8List bytes) {
  if (bytes.length < _v2FixedLength) {
    throw const FormatException('OneSend file envelope is truncated.');
  }
  final header = ByteData.sublistView(bytes);
  final flags = bytes[5];
  if ((flags & ~_gzipFlag) != 0) {
    throw const FormatException('OneSend file envelope has unknown flags.');
  }
  final nameLength = header.getUint16(6, Endian.little);
  final mimeLength = header.getUint16(8, Endian.little);
  final originalLength = header.getUint32(10, Endian.little);
  final originalChecksum = header.getUint32(14, Endian.little);
  final storedLength = header.getUint32(18, Endian.little);
  final storedChecksum = header.getUint32(22, Endian.little);
  if (originalLength > maxTransferFileBytes) {
    throw const FormatException('Received file exceeds 64 MB.');
  }
  final dataStart = _v2FixedLength + nameLength + mimeLength;
  if (dataStart > bytes.length || bytes.length - dataStart != storedLength) {
    throw const FormatException('OneSend file envelope lengths are invalid.');
  }

  final stored = Uint8List.sublistView(bytes, dataStart);
  if (crc32(stored) != storedChecksum) {
    throw const FormatException('Stored file data failed its CRC32 check.');
  }

  final compressed = (flags & _gzipFlag) != 0;
  final Uint8List original;
  if (compressed) {
    try {
      original = _decodeGzipBounded(stored, originalLength);
    } on Object catch (error) {
      throw FormatException('Compressed file data is invalid.', error);
    }
  } else {
    original = stored;
  }
  if (original.length != originalLength ||
      crc32(original) != originalChecksum) {
    throw const FormatException('Original file failed its integrity check.');
  }

  return TransferFile(
    name: _decodeName(bytes, _v2FixedLength, nameLength),
    mimeType: _decodeMime(bytes, _v2FixedLength + nameLength, mimeLength),
    bytes: original,
    wasCompressed: compressed,
  );
}

Uint8List _decodeGzipBounded(Uint8List stored, int expectedLength) {
  final sink = _BoundedBytesSink(expectedLength);
  final conversion = gzip.decoder.startChunkedConversion(sink);
  conversion.add(stored);
  conversion.close();
  return sink.takeBytes();
}

class _BoundedBytesSink implements Sink<List<int>> {
  _BoundedBytesSink(this.maximumLength);

  final int maximumLength;
  final BytesBuilder _bytes = BytesBuilder(copy: false);
  int _length = 0;

  @override
  void add(List<int> data) {
    _length += data.length;
    if (_length > maximumLength) {
      throw const FormatException(
        'Compressed file expands beyond its declared size.',
      );
    }
    _bytes.add(data);
  }

  @override
  void close() {}

  Uint8List takeBytes() => _bytes.takeBytes();
}

bool _shouldAttemptCompression(TransferFile file) {
  if (file.bytes.length < 1024) return false;
  final mime = file.mimeType.toLowerCase();
  if (mime.startsWith('text/') ||
      mime.contains('json') ||
      mime.contains('xml') ||
      mime.contains('javascript')) {
    return true;
  }
  if (mime.startsWith('image/') ||
      mime.startsWith('audio/') ||
      mime.startsWith('video/') ||
      mime.contains('zip') ||
      mime.contains('gzip') ||
      mime.contains('7z') ||
      mime.contains('rar') ||
      mime == 'application/pdf') {
    return false;
  }
  return file.bytes.length <= _maximumGenericCompressionBytes;
}

bool _hasMagic(Uint8List bytes) =>
    bytes.length >= _envelopeMagic.length &&
    _envelopeMagic.asMap().entries.every(
      (entry) => bytes[entry.key] == entry.value,
    );

TransferFile _rawTransferFile(Uint8List bytes) => TransferFile(
  name: 'received.bin',
  mimeType: 'application/octet-stream',
  bytes: bytes,
);

String _decodeName(Uint8List bytes, int start, int length) => sanitizeFileName(
  utf8.decode(bytes.sublist(start, start + length), allowMalformed: true),
);

String _decodeMime(Uint8List bytes, int start, int length) {
  final mime = utf8.decode(
    bytes.sublist(start, start + length),
    allowMalformed: true,
  );
  return mime.isEmpty ? 'application/octet-stream' : mime;
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
    'gz': 'application/gzip',
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
    'rar': 'application/vnd.rar',
    'svg': 'image/svg+xml',
    'tar': 'application/x-tar',
    'txt': 'text/plain',
    'wav': 'audio/wav',
    'webp': 'image/webp',
    'zip': 'application/zip',
  };
  return types[extension] ?? 'application/octet-stream';
}
