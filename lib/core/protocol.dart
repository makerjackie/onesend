import 'dart:typed_data';

/// The wire format used by every animated QR frame.
///
/// This is intentionally kept compatible with the open-source
/// decimen-optical-transfer proof of concept: a frame is self-describing, so
/// a receiver can join a stream at any point and a sender never needs a
/// network back-channel.
const int frameHeaderLength = 20;
const int _magic0 = 0xd1;
const int _magic1 = 0x0c;
const int _u32Mask = 0xffffffff;

class FrameHeader {
  const FrameHeader({
    required this.sessionId,
    required this.sequence,
    required this.blockCount,
    required this.blockLength,
    required this.totalLength,
    required this.payloadHash,
  });

  final int sessionId;
  final int sequence;
  final int blockCount;
  final int blockLength;
  final int totalLength;
  final int payloadHash;

  bool matches(FrameHeader other) =>
      sessionId == other.sessionId &&
      blockCount == other.blockCount &&
      blockLength == other.blockLength &&
      totalLength == other.totalLength &&
      payloadHash == other.payloadHash;
}

class ParsedFrame {
  const ParsedFrame({required this.header, required this.block});

  final FrameHeader header;
  final Uint8List block;
}

Uint8List packFrame(FrameHeader header, Uint8List block) {
  if (block.isEmpty || block.length > 0xffff) {
    throw ArgumentError.value(block.length, 'block', 'must fit in a u16');
  }
  final bytes = Uint8List(frameHeaderLength + block.length);
  ByteData.sublistView(bytes)
    ..setUint8(0, _magic0)
    ..setUint8(1, _magic1)
    ..setUint16(2, header.sessionId & 0xffff, Endian.little)
    ..setUint32(4, header.sequence & _u32Mask, Endian.little)
    ..setUint16(8, header.blockCount & 0xffff, Endian.little)
    ..setUint16(10, header.blockLength & 0xffff, Endian.little)
    ..setUint32(12, header.totalLength & _u32Mask, Endian.little)
    ..setUint32(16, header.payloadHash & _u32Mask, Endian.little);
  bytes.setRange(frameHeaderLength, bytes.length, block);
  return bytes;
}

ParsedFrame? parseFrame(Uint8List bytes) {
  if (bytes.length <= frameHeaderLength ||
      bytes[0] != _magic0 ||
      bytes[1] != _magic1) {
    return null;
  }

  final data = ByteData.sublistView(bytes);
  final header = FrameHeader(
    sessionId: data.getUint16(2, Endian.little),
    sequence: data.getUint32(4, Endian.little),
    blockCount: data.getUint16(8, Endian.little),
    blockLength: data.getUint16(10, Endian.little),
    totalLength: data.getUint32(12, Endian.little),
    payloadHash: data.getUint32(16, Endian.little),
  );

  if (header.blockCount == 0 ||
      header.blockLength == 0 ||
      header.totalLength == 0 ||
      bytes.length != frameHeaderLength + header.blockLength) {
    return null;
  }

  return ParsedFrame(
    header: header,
    block: Uint8List.sublistView(bytes, frameHeaderLength),
  );
}

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
