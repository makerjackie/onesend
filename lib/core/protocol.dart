import 'dart:typed_data';

const int currentProtocolVersion = 2;
const int legacyFrameHeaderLength = 20;
const int frameHeaderLength = 28;
const int frameChecksumLength = 4;

const int _legacyMagic0 = 0xd1;
const int _legacyMagic1 = 0x0c;
const int _magic0 = 0x4f; // O
const int _magic1 = 0x53; // S
const int _u32Mask = 0xffffffff;

class FrameHeader {
  const FrameHeader({
    this.protocolVersion = currentProtocolVersion,
    this.profileId = 0,
    required this.sessionId,
    required this.sequence,
    required this.blockCount,
    required this.blockLength,
    required this.totalLength,
    required this.payloadChecksum,
  });

  final int protocolVersion;
  final int profileId;
  final int sessionId;
  final int sequence;
  final int blockCount;
  final int blockLength;
  final int totalLength;
  final int payloadChecksum;

  /// Compatibility name for protocol v1 callers.
  int get payloadHash => payloadChecksum;

  bool matches(FrameHeader other) =>
      protocolVersion == other.protocolVersion &&
      profileId == other.profileId &&
      sessionId == other.sessionId &&
      blockCount == other.blockCount &&
      blockLength == other.blockLength &&
      totalLength == other.totalLength &&
      payloadChecksum == other.payloadChecksum;
}

class ParsedFrame {
  const ParsedFrame({required this.header, required this.block});

  final FrameHeader header;
  final Uint8List block;
}

/// Packs a protocol v2 frame.
///
/// Every frame has its own CRC32, so camera decode errors are discarded before
/// they can enter the fountain decoder. The complete payload has a second CRC32
/// in the header and the file envelope performs one final integrity check.
Uint8List packFrame(FrameHeader header, Uint8List block) {
  if (header.protocolVersion != currentProtocolVersion) {
    throw ArgumentError.value(
      header.protocolVersion,
      'header.protocolVersion',
      'only protocol v2 frames can be packed',
    );
  }
  if (block.isEmpty || block.length > 0xffff) {
    throw ArgumentError.value(block.length, 'block', 'must fit in a u16');
  }
  if (block.length != header.blockLength) {
    throw ArgumentError('block length does not match the frame header');
  }
  _validateGeometry(header);

  final bytes = Uint8List(
    frameHeaderLength + block.length + frameChecksumLength,
  );
  ByteData.sublistView(bytes)
    ..setUint8(0, _magic0)
    ..setUint8(1, _magic1)
    ..setUint8(2, currentProtocolVersion)
    ..setUint8(3, header.profileId & 0xff)
    ..setUint32(4, header.sessionId & _u32Mask, Endian.little)
    ..setUint32(8, header.sequence & _u32Mask, Endian.little)
    ..setUint32(12, header.blockCount & _u32Mask, Endian.little)
    ..setUint16(16, header.blockLength & 0xffff, Endian.little)
    ..setUint16(18, 0, Endian.little)
    ..setUint32(20, header.totalLength & _u32Mask, Endian.little)
    ..setUint32(24, header.payloadChecksum & _u32Mask, Endian.little);
  bytes.setRange(frameHeaderLength, frameHeaderLength + block.length, block);
  ByteData.sublistView(bytes).setUint32(
    bytes.length - frameChecksumLength,
    crc32(bytes, end: bytes.length - frameChecksumLength),
    Endian.little,
  );
  return bytes;
}

ParsedFrame? parseFrame(Uint8List bytes) {
  if (bytes.length > frameHeaderLength + frameChecksumLength &&
      bytes[0] == _magic0 &&
      bytes[1] == _magic1) {
    return _parseCurrentFrame(bytes);
  }
  if (bytes.length > legacyFrameHeaderLength &&
      bytes[0] == _legacyMagic0 &&
      bytes[1] == _legacyMagic1) {
    return _parseLegacyFrame(bytes);
  }
  return null;
}

ParsedFrame? _parseCurrentFrame(Uint8List bytes) {
  if (bytes[2] != currentProtocolVersion) return null;
  final data = ByteData.sublistView(bytes);
  final header = FrameHeader(
    protocolVersion: bytes[2],
    profileId: bytes[3],
    sessionId: data.getUint32(4, Endian.little),
    sequence: data.getUint32(8, Endian.little),
    blockCount: data.getUint32(12, Endian.little),
    blockLength: data.getUint16(16, Endian.little),
    totalLength: data.getUint32(20, Endian.little),
    payloadChecksum: data.getUint32(24, Endian.little),
  );
  final expectedLength =
      frameHeaderLength + header.blockLength + frameChecksumLength;
  if (bytes.length != expectedLength || !_hasValidGeometry(header)) {
    return null;
  }
  final expectedChecksum = data.getUint32(
    bytes.length - frameChecksumLength,
    Endian.little,
  );
  final actualChecksum = crc32(bytes, end: bytes.length - frameChecksumLength);
  if (actualChecksum != expectedChecksum) return null;

  return ParsedFrame(
    header: header,
    block: Uint8List.sublistView(
      bytes,
      frameHeaderLength,
      bytes.length - frameChecksumLength,
    ),
  );
}

ParsedFrame? _parseLegacyFrame(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final header = FrameHeader(
    protocolVersion: 1,
    profileId: 0xff,
    sessionId: data.getUint16(2, Endian.little),
    sequence: data.getUint32(4, Endian.little),
    blockCount: data.getUint16(8, Endian.little),
    blockLength: data.getUint16(10, Endian.little),
    totalLength: data.getUint32(12, Endian.little),
    payloadChecksum: data.getUint32(16, Endian.little),
  );
  if (bytes.length != legacyFrameHeaderLength + header.blockLength ||
      !_hasValidGeometry(header)) {
    return null;
  }
  return ParsedFrame(
    header: header,
    block: Uint8List.sublistView(bytes, legacyFrameHeaderLength),
  );
}

bool _hasValidGeometry(FrameHeader header) {
  if (header.blockCount <= 0 ||
      header.blockLength <= 0 ||
      header.totalLength <= 0) {
    return false;
  }
  final minimumLength = (header.blockCount - 1) * header.blockLength + 1;
  final maximumLength = header.blockCount * header.blockLength;
  return header.totalLength >= minimumLength &&
      header.totalLength <= maximumLength;
}

void _validateGeometry(FrameHeader header) {
  if (!_hasValidGeometry(header)) {
    throw ArgumentError('invalid block count, block length, or total length');
  }
  if (header.sessionId <= 0 || header.sessionId > _u32Mask) {
    throw ArgumentError.value(header.sessionId, 'header.sessionId');
  }
  if (header.sequence < 0 || header.sequence > _u32Mask) {
    throw ArgumentError.value(header.sequence, 'header.sequence');
  }
  if (header.profileId < 0 || header.profileId > 0xff) {
    throw ArgumentError.value(header.profileId, 'header.profileId');
  }
  if (header.blockCount > _u32Mask || header.totalLength > _u32Mask) {
    throw ArgumentError('frame geometry must fit in unsigned 32-bit fields');
  }
}

int crc32(Uint8List bytes, {int start = 0, int? end}) {
  final limit = end ?? bytes.length;
  if (start < 0 || limit < start || limit > bytes.length) {
    throw RangeError.range(limit, start, bytes.length, 'end');
  }
  var checksum = _u32Mask;
  for (var index = start; index < limit; index++) {
    checksum = _crc32Table[(checksum ^ bytes[index]) & 0xff] ^ (checksum >> 8);
  }
  return (checksum ^ _u32Mask) & _u32Mask;
}

final Uint32List _crc32Table = Uint32List.fromList(
  List<int>.generate(256, (index) {
    var value = index;
    for (var bit = 0; bit < 8; bit++) {
      value = (value & 1) == 1 ? 0xedb88320 ^ (value >> 1) : value >> 1;
    }
    return value & _u32Mask;
  }, growable: false),
);

int fnv1a(Uint8List bytes) {
  var hash = 0x811c9dc5;
  for (final byte in bytes) {
    hash ^= byte;
    hash = _unsigned32(hash * 0x01000193);
  }
  return hash;
}

int _signed32(int value) {
  final normalized = value & _u32Mask;
  return normalized >= 0x80000000 ? normalized - 0x100000000 : normalized;
}

int _unsigned32(int value) => value & _u32Mask;

int _imul(int left, int right) => _signed32(_signed32(left) * _signed32(right));

/// splitmix32 — integer-only and deterministic across Dart, JavaScript and
/// native runtimes.
int Function() splitmix32(int seed) {
  var state = _signed32(seed);
  return () {
    state = _signed32(state + 0x9e3779b9);
    var value = _unsigned32(state) ^ (_unsigned32(state) >> 16);
    value = _unsigned32(_imul(value, 0x21f0aaad));
    value = _unsigned32(value ^ (value >> 15));
    value = _unsigned32(_imul(value, 0x735a2d97));
    value = _unsigned32(value ^ (value >> 15));
    return value;
  };
}

int frameSeed(int sessionId, int sequence) {
  var hash = _signed32(
    _imul(sessionId + 1, 0x9e3779b1) ^ _unsigned32(sequence + 0x85ebca6b),
  );
  hash = _imul(hash ^ (_unsigned32(hash) >> 13), 0xc2b2ae35);
  return _signed32(_unsigned32(hash) ^ (_unsigned32(hash) >> 16));
}
