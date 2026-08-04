import 'dart:convert';
import 'dart:typed_data';

import '../core/envelope.dart';
import '../core/protocol.dart';
import 'file_service.dart';

/// Maximum payload accepted from the libcimbar WebView bridge.
///
/// libcimbar's fountain decoder has a roughly 33.55 MiB in-memory limit. The
/// mobile experiment deliberately stays below that limit so that the Dart
/// side never allocates an unbounded receive buffer.
const int cimbarMaxEnvelopeBytes = 33 * 1024 * 1024;
const int cimbarMaxPayloadBytes = cimbarMaxEnvelopeBytes;
const int cimbarMaxTransferBytes = cimbarMaxEnvelopeBytes;

/// The CIMBAR wire envelope is intentionally separate from the QR transfer
/// envelope. libcimbar already applies its own zstd/fountain framing, so this
/// layer only carries the original metadata and an end-to-end CRC32.
const List<int> cimbarEnvelopeMagic = <int>[0x4f, 0x53, 0x43, 0x45]; // OSCE
const int cimbarEnvelopeVersion = 1;
const int cimbarEnvelopeHeaderBytes = 17;
const int cimbarMaxFilenameBytes = 4096;
const int cimbarMaxMimeTypeBytes = 256;

/// The bridge uses this fixed size for base64 messages to keep individual
/// JavaScript-channel calls bounded.
const int cimbarBridgeChunkBytes = 128 * 1024;

const String cimbarBridgeChannelName = 'OneSendCimbarBridge';

/// Encodes the bytes handed to libcimbar on both mobile and web.
///
/// Layout (all integer fields little-endian):
///
/// ```text
/// 0..3   magic "OSCE"
/// 4      version (1)
/// 5..6   filename UTF-8 length
/// 7..8   MIME UTF-8 length
/// 9..12  payload length
/// 13..16 payload CRC32
/// 17..   filename, MIME, payload
/// ```
Uint8List encodeCimbarEnvelope(TransferFile file) {
  final name = _encodeCimbarText(
    file.name,
    label: '文件名',
    maxBytes: cimbarMaxFilenameBytes,
  );
  final mime = _encodeCimbarText(
    file.mimeType.isEmpty ? 'application/octet-stream' : file.mimeType,
    label: 'MIME 类型',
    maxBytes: cimbarMaxMimeTypeBytes,
  );
  final payload = file.bytes;
  if (payload.length > cimbarMaxPayloadBytes) {
    throw ArgumentError('CIMBAR payload cannot exceed 33 MiB.');
  }

  final payloadStart = cimbarEnvelopeHeaderBytes + name.length + mime.length;
  final totalLength = payloadStart + payload.length;
  if (totalLength > cimbarMaxEnvelopeBytes) {
    throw ArgumentError('CIMBAR envelope cannot exceed 33 MiB.');
  }

  final envelope = Uint8List(totalLength);
  envelope.setRange(0, cimbarEnvelopeMagic.length, cimbarEnvelopeMagic);
  envelope[cimbarEnvelopeMagic.length] = cimbarEnvelopeVersion;
  final header = ByteData.sublistView(envelope);
  header
    ..setUint16(5, name.length, Endian.little)
    ..setUint16(7, mime.length, Endian.little)
    ..setUint32(9, payload.length, Endian.little)
    ..setUint32(13, crc32(payload), Endian.little);
  envelope.setRange(
    cimbarEnvelopeHeaderBytes,
    cimbarEnvelopeHeaderBytes + name.length,
    name,
  );
  envelope.setRange(
    cimbarEnvelopeHeaderBytes + name.length,
    payloadStart,
    mime,
  );
  envelope.setRange(payloadStart, envelope.length, payload);
  return envelope;
}

/// Decodes and verifies a complete CIMBAR envelope.
///
/// There is deliberately no raw-payload fallback. A CIMBAR completion is
/// usable only after the version, exact lengths, strict UTF-8 metadata and
/// payload CRC32 have all passed.
TransferFile decodeCimbarEnvelope(Uint8List envelope) {
  if (envelope.length > cimbarMaxEnvelopeBytes) {
    throw const FormatException('CIMBAR envelope exceeds 33 MiB.');
  }
  if (envelope.length < cimbarEnvelopeMagic.length ||
      !_matchesCimbarMagic(envelope)) {
    throw const FormatException('CIMBAR envelope magic is invalid.');
  }
  if (envelope.length < cimbarEnvelopeHeaderBytes) {
    throw const FormatException('CIMBAR envelope is truncated.');
  }
  if (envelope[4] != cimbarEnvelopeVersion) {
    throw FormatException('Unsupported CIMBAR envelope version ${envelope[4]}');
  }

  final header = ByteData.sublistView(envelope);
  final nameLength = header.getUint16(5, Endian.little);
  final mimeLength = header.getUint16(7, Endian.little);
  final payloadLength = header.getUint32(9, Endian.little);
  final expectedChecksum = header.getUint32(13, Endian.little);
  if (nameLength == 0 || nameLength > cimbarMaxFilenameBytes) {
    throw const FormatException('CIMBAR filename length is invalid.');
  }
  if (mimeLength == 0 || mimeLength > cimbarMaxMimeTypeBytes) {
    throw const FormatException('CIMBAR MIME length is invalid.');
  }
  if (payloadLength > cimbarMaxPayloadBytes) {
    throw const FormatException('CIMBAR payload exceeds 33 MiB.');
  }

  final payloadStart = cimbarEnvelopeHeaderBytes + nameLength + mimeLength;
  if (payloadStart > envelope.length ||
      envelope.length - payloadStart != payloadLength) {
    throw const FormatException('CIMBAR envelope lengths are invalid.');
  }

  final name = _decodeCimbarText(
    envelope,
    start: cimbarEnvelopeHeaderBytes,
    length: nameLength,
    label: '文件名',
    maxBytes: cimbarMaxFilenameBytes,
  );
  final mimeType = _decodeCimbarText(
    envelope,
    start: cimbarEnvelopeHeaderBytes + nameLength,
    length: mimeLength,
    label: 'MIME 类型',
    maxBytes: cimbarMaxMimeTypeBytes,
  );
  final payload = Uint8List.fromList(envelope.sublist(payloadStart));
  if (crc32(payload) != expectedChecksum) {
    throw const FormatException('CIMBAR payload CRC32 check failed.');
  }

  return TransferFile(name: name, mimeType: mimeType, bytes: payload);
}

Uint8List _encodeCimbarText(
  String value, {
  required String label,
  required int maxBytes,
}) {
  if (value.isEmpty) throw ArgumentError('$label cannot be empty.');
  _validateCimbarText(value, label);
  final bytes = Uint8List.fromList(utf8.encode(value));
  if (bytes.length > maxBytes) {
    throw ArgumentError('$label exceeds $maxBytes UTF-8 bytes.');
  }
  return bytes;
}

String _decodeCimbarText(
  Uint8List bytes, {
  required int start,
  required int length,
  required String label,
  required int maxBytes,
}) {
  if (length == 0 || length > maxBytes) {
    throw FormatException('$label length is invalid.');
  }
  final encoded = bytes.sublist(start, start + length);
  final value = utf8.decode(encoded, allowMalformed: false);
  try {
    _validateCimbarText(value, label);
  } on ArgumentError catch (error) {
    throw FormatException('$label contains invalid text.', error);
  }
  if (utf8.encode(value).length != length) {
    throw FormatException('$label UTF-8 length is not canonical.');
  }
  return value;
}

void _validateCimbarText(String value, String label) {
  for (var index = 0; index < value.length; index++) {
    final codeUnit = value.codeUnitAt(index);
    if (codeUnit >= 0xd800 && codeUnit <= 0xdbff) {
      if (index + 1 >= value.length) {
        throw ArgumentError('$label contains an unpaired UTF-16 surrogate.');
      }
      final next = value.codeUnitAt(index + 1);
      if (next < 0xdc00 || next > 0xdfff) {
        throw ArgumentError('$label contains an unpaired UTF-16 surrogate.');
      }
      index += 1;
    } else if (codeUnit >= 0xdc00 && codeUnit <= 0xdfff) {
      throw ArgumentError('$label contains an unpaired UTF-16 surrogate.');
    }
    if (codeUnit <= 0x1f || codeUnit == 0x7f) {
      throw ArgumentError('$label contains a control character.');
    }
  }
}

bool _matchesCimbarMagic(Uint8List bytes) {
  for (var index = 0; index < cimbarEnvelopeMagic.length; index++) {
    if (bytes[index] != cimbarEnvelopeMagic[index]) return false;
  }
  return true;
}

const Set<String> _knownEventTypes = <String>{
  'send-ready',
  'send-prepared',
  'send-progress',
  'send-paused',
  'send-complete',
  'receive-ready',
  'receive-started',
  // Fired when WebView getUserMedia OR Flutter native camera is live.
  // Missing this from the allow-list aborts receive right after start.
  'receive-camera-live',
  'decode-progress',
  'receive-file-start',
  'receive-file-chunk',
  'receive-file-complete',
  'receive-complete',
  'error',
};

/// A malformed or unsafe message from the WebView bridge.
class CimbarBridgeFormatException implements Exception {
  const CimbarBridgeFormatException(this.message);

  final String message;

  @override
  String toString() => 'CimbarBridgeFormatException: $message';
}

/// Parsed, structured data received from the independent JavaScript wrapper.
class CimbarBridgeEvent {
  const CimbarBridgeEvent._(this.type, this.fields);

  factory CimbarBridgeEvent.parse(String rawMessage) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(rawMessage);
    } on Object catch (error) {
      throw CimbarBridgeFormatException('事件不是有效 JSON：$error');
    }
    if (decoded is! Map) {
      throw const CimbarBridgeFormatException('事件必须是 JSON 对象。');
    }

    final fields = <String, dynamic>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String) {
        throw const CimbarBridgeFormatException('事件字段名必须是字符串。');
      }
      fields[entry.key as String] = entry.value;
    }

    final type = fields['type'];
    if (type is! String || type.trim().isEmpty) {
      throw const CimbarBridgeFormatException('事件缺少 type。');
    }
    if (!_knownEventTypes.contains(type)) {
      throw CimbarBridgeFormatException('不支持的事件类型：$type');
    }

    if (_fileEventTypes.contains(type)) {
      _requireSession(fields);
    }
    if (type == 'receive-file-start') {
      _requireString(fields, 'name');
      _requireString(fields, 'mimeType');
      _requireInteger(fields, 'size');
      _requireInteger(fields, 'totalChunks');
      _requireVerified(fields);
      _requireUint32(fields, 'crc32');
    } else if (type == 'receive-file-chunk') {
      _requireInteger(fields, 'index');
      _requireInteger(fields, 'size');
      _requireInteger(fields, 'totalChunks');
      _requireString(fields, 'data');
    } else if (type == 'receive-file-complete') {
      _requireInteger(fields, 'size');
      _requireInteger(fields, 'totalChunks');
      _requireVerified(fields);
      _requireUint32(fields, 'crc32');
    }

    return CimbarBridgeEvent._(type, Map<String, dynamic>.unmodifiable(fields));
  }

  static const Set<String> _fileEventTypes = <String>{
    'receive-file-start',
    'receive-file-chunk',
    'receive-file-complete',
    'receive-complete',
  };

  final String type;
  final Map<String, dynamic> fields;

  String? stringValue(String key) {
    final value = fields[key];
    return value is String ? value : null;
  }

  int? integerValue(String key) {
    final value = fields[key];
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return null;
  }

  bool? booleanValue(String key) {
    final value = fields[key];
    return value is bool ? value : null;
  }

  List<double>? progressValues() {
    final value = fields['progress'];
    if (value is! List) return null;
    final result = <double>[];
    for (final item in value) {
      if (item is! num || !item.isFinite) return null;
      result.add(item.toDouble());
    }
    return List<double>.unmodifiable(result);
  }

  String requireString(String key) {
    final value = stringValue(key);
    if (value == null) {
      throw CimbarBridgeFormatException('事件字段 $key 必须是字符串。');
    }
    return value;
  }

  int requireInteger(String key) {
    final value = integerValue(key);
    if (value == null) {
      throw CimbarBridgeFormatException('事件字段 $key 必须是整数。');
    }
    return value;
  }

  String requireSession() {
    final session = requireString('session');
    _validateSession(session);
    return session;
  }

  bool requireVerified() {
    if (booleanValue('verified') != true) {
      throw const CimbarBridgeFormatException(
        '文件事件只有在 CIMBAR envelope CRC32 通过后才能 verified。',
      );
    }
    return true;
  }

  int requireUint32(String key) {
    final value = requireInteger(key);
    if (value < 0 || value > 0xffffffff) {
      throw CimbarBridgeFormatException('事件字段 $key 超出 uint32 范围。');
    }
    return value;
  }
}

/// Facade used by the screen and by tests to parse and consume channel data.
class CimbarBridge {
  CimbarBridge({CimbarChunkAssembler? assembler})
    : assembler = assembler ?? CimbarChunkAssembler();

  final CimbarChunkAssembler assembler;

  CimbarBridgeEvent parse(String rawMessage) =>
      CimbarBridgeEvent.parse(rawMessage);

  /// Consumes a download event. Returns a complete [TransferFile] only after
  /// every expected chunk has arrived and passed all size/index checks.
  TransferFile? accept(String rawMessage) {
    final event = parse(rawMessage);
    return assembler.accept(event);
  }

  void reset() => assembler.reset();
}

/// Reassembles a strict, out-of-order-safe libcimbar download session.
class CimbarChunkAssembler {
  CimbarChunkAssembler({
    this.maxFileBytes = cimbarMaxTransferBytes,
    this.chunkBytes = cimbarBridgeChunkBytes,
  }) {
    if (maxFileBytes < 0) {
      throw ArgumentError.value(maxFileBytes, 'maxFileBytes');
    }
    if (chunkBytes <= 0) {
      throw ArgumentError.value(chunkBytes, 'chunkBytes');
    }
  }

  final int maxFileBytes;
  final int chunkBytes;
  _CimbarDownloadSession? _session;

  bool get hasSession => _session != null;
  String? get sessionId => _session?.session;
  int get receivedBytes => _session?.receivedBytes ?? 0;
  int? get expectedBytes => _session?.size;

  TransferFile? accept(CimbarBridgeEvent event) {
    switch (event.type) {
      case 'receive-file-start':
        _start(event);
        return null;
      case 'receive-file-chunk':
        _addChunk(event);
        return null;
      case 'receive-file-complete':
        return _finish(event);
      default:
        return null;
    }
  }

  void reset() {
    _session = null;
  }

  void _start(CimbarBridgeEvent event) {
    if (_session != null) {
      throw const CimbarBridgeFormatException('已有接收 session，拒绝覆盖。');
    }
    final session = event.requireSession();
    final name = event.requireString('name');
    final mimeType = event.requireString('mimeType');
    final size = event.requireInteger('size');
    final totalChunks = event.requireInteger('totalChunks');
    event.requireVerified();
    final checksum = event.requireUint32('crc32');
    _validateMetadata(name, mimeType, size, totalChunks);
    _session = _CimbarDownloadSession(
      session: session,
      name: safeStorageFileName(name),
      mimeType: mimeType,
      size: size,
      totalChunks: totalChunks,
      checksum: checksum,
    );
  }

  void _addChunk(CimbarBridgeEvent event) {
    final session = _requireActiveSession(event.requireSession());
    final declaredSize = event.requireInteger('size');
    final declaredTotalChunks = event.requireInteger('totalChunks');
    if (declaredSize != session.size ||
        declaredTotalChunks != session.totalChunks) {
      throw const CimbarBridgeFormatException(
        'chunk 的 session 大小声明与 start 不一致。',
      );
    }

    final index = event.requireInteger('index');
    if (index < 0 || index >= session.totalChunks) {
      throw const CimbarBridgeFormatException('chunk index 越界。');
    }
    if (session.chunks.containsKey(index)) {
      throw CimbarBridgeFormatException('重复的 chunk index：$index');
    }

    final bytes = _decodeBase64(event.requireString('data'));
    final start = index * chunkBytes;
    final expectedLength = session.size == 0
        ? 0
        : (session.size - start).clamp(0, chunkBytes);
    if (bytes.length != expectedLength) {
      throw CimbarBridgeFormatException(
        'chunk $index 长度为 ${bytes.length}，应为 $expectedLength。',
      );
    }
    if (session.receivedBytes + bytes.length > session.size) {
      throw const CimbarBridgeFormatException('chunk 总大小越界。');
    }
    session.chunks[index] = bytes;
    session.receivedBytes += bytes.length;
  }

  TransferFile _finish(CimbarBridgeEvent event) {
    final session = _requireActiveSession(event.requireSession());
    final declaredSize = event.requireInteger('size');
    final declaredTotalChunks = event.requireInteger('totalChunks');
    event.requireVerified();
    final checksum = event.requireUint32('crc32');
    if (declaredSize != session.size ||
        declaredTotalChunks != session.totalChunks ||
        checksum != session.checksum) {
      throw const CimbarBridgeFormatException('complete 的大小声明与 start 不一致。');
    }
    if (session.receivedBytes != session.size ||
        session.chunks.length != session.totalChunks) {
      throw const CimbarBridgeFormatException('文件仍缺少 chunk，不能标记完成。');
    }

    final result = Uint8List(session.size);
    var offset = 0;
    for (var index = 0; index < session.totalChunks; index++) {
      final bytes = session.chunks[index];
      if (bytes == null) {
        throw CimbarBridgeFormatException('文件缺少 chunk $index。');
      }
      result.setRange(offset, offset + bytes.length, bytes);
      offset += bytes.length;
    }
    if (crc32(result) != session.checksum) {
      throw const CimbarBridgeFormatException('CIMBAR envelope CRC32 校验失败。');
    }
    final file = TransferFile(
      name: safeStorageFileName(session.name),
      mimeType: session.mimeType,
      bytes: result,
    );
    _session = null;
    return file;
  }

  _CimbarDownloadSession _requireActiveSession(String session) {
    final active = _session;
    if (active == null) {
      throw const CimbarBridgeFormatException('chunk 没有对应的 active session。');
    }
    if (active.session != session) {
      throw CimbarBridgeFormatException(
        'chunk session 不匹配：期待 ${active.session}，收到 $session。',
      );
    }
    return active;
  }

  void _validateMetadata(
    String name,
    String mimeType,
    int size,
    int totalChunks,
  ) {
    try {
      _encodeCimbarText(name, label: '文件名', maxBytes: cimbarMaxFilenameBytes);
      _encodeCimbarText(
        mimeType,
        label: 'MIME 类型',
        maxBytes: cimbarMaxMimeTypeBytes,
      );
    } on Object catch (error) {
      throw CimbarBridgeFormatException('文件 envelope 元数据无效：$error');
    }
    if (size < 0 || size > maxFileBytes) {
      throw const CimbarBridgeFormatException('文件大小超过 33 MiB 或无效。');
    }
    final expectedChunks = size == 0
        ? 0
        : (size + chunkBytes - 1) ~/ chunkBytes;
    if (totalChunks != expectedChunks) {
      throw CimbarBridgeFormatException(
        'totalChunks 为 $totalChunks，应为 $expectedChunks。',
      );
    }
  }

  Uint8List _decodeBase64(String encoded) {
    if (encoded.length > ((chunkBytes + 2) ~/ 3) * 4 ||
        encoded.length % 4 != 0 ||
        !RegExp(
          r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$',
        ).hasMatch(encoded)) {
      throw const CimbarBridgeFormatException('chunk base64 编码无效。');
    }
    try {
      final bytes = Uint8List.fromList(base64.decode(encoded));
      if (base64.encode(bytes) != encoded) {
        throw const CimbarBridgeFormatException('chunk base64 不是规范编码。');
      }
      if (bytes.length > chunkBytes) {
        throw const CimbarBridgeFormatException('chunk 超过 128 KiB。');
      }
      return bytes;
    } on CimbarBridgeFormatException {
      rethrow;
    } on Object catch (error) {
      throw CimbarBridgeFormatException('chunk base64 解码失败：$error');
    }
  }
}

class _CimbarDownloadSession {
  _CimbarDownloadSession({
    required this.session,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.totalChunks,
    required this.checksum,
  });

  final String session;
  final String name;
  final String mimeType;
  final int size;
  final int totalChunks;
  final int checksum;
  final Map<int, Uint8List> chunks = <int, Uint8List>{};
  int receivedBytes = 0;
}

void _requireSession(Map<String, dynamic> fields) {
  final session = fields['session'];
  if (session is! String || session.isEmpty) {
    throw const CimbarBridgeFormatException('文件事件缺少 session。');
  }
  _validateSession(session);
}

void _validateSession(String session) {
  if (session.length > 128 ||
      !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(session)) {
    throw const CimbarBridgeFormatException('session 格式无效。');
  }
}

void _requireString(Map<String, dynamic> fields, String key) {
  if (fields[key] is! String) {
    throw CimbarBridgeFormatException('事件字段 $key 必须是字符串。');
  }
}

void _requireInteger(Map<String, dynamic> fields, String key) {
  final value = fields[key];
  if (value is int) return;
  if (value is num && value.isFinite && value == value.roundToDouble()) return;
  throw CimbarBridgeFormatException('事件字段 $key 必须是整数。');
}

void _requireUint32(Map<String, dynamic> fields, String key) {
  final value = fields[key];
  if (value is int && value >= 0 && value <= 0xffffffff) return;
  if (value is num &&
      value.isFinite &&
      value == value.roundToDouble() &&
      value >= 0 &&
      value <= 0xffffffff) {
    return;
  }
  throw CimbarBridgeFormatException('事件字段 $key 必须是 uint32。');
}

void _requireVerified(Map<String, dynamic> fields) {
  if (fields['verified'] != true) {
    throw const CimbarBridgeFormatException(
      '文件事件只有在 CIMBAR envelope CRC32 通过后才能 verified。',
    );
  }
}
