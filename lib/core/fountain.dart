import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'protocol.dart';

const double _ln2 = 0.6931471805599453;
const double _solitonC = 0.1;
const double _solitonDelta = 0.5;
const int sourceFramesPerGroup = 4;
const int framesPerGroup = sourceFramesPerGroup + 1;
const int _maximumRepairDegree = 64;
const int _seenSequenceWindow = 4096;
const int _maximumPendingFrameLimit = 8192;

bool isRepairSequence(int sequence) =>
    sequence % framesPerGroup == sourceFramesPerGroup;

int sourceFramesThrough(int sequence) {
  final completedGroups = sequence ~/ framesPerGroup;
  final groupPosition = sequence % framesPerGroup;
  return completedGroups * sourceFramesPerGroup +
      math.min(groupPosition + 1, sourceFramesPerGroup);
}

/// A deterministic natural logarithm used to keep the sender and receiver's
/// robust-soliton distributions bit-identical on different runtimes.
double _deterministicLog(double value) {
  var exponent = 0;
  var mantissa = value;
  while (mantissa >= 1.5) {
    mantissa /= 2;
    exponent++;
  }
  while (mantissa < 0.75) {
    mantissa *= 2;
    exponent--;
  }
  final z = (mantissa - 1) / (mantissa + 1);
  final zSquared = z * z;
  var term = z;
  var sum = 0.0;
  for (var n = 1; n <= 21; n += 2) {
    sum += term / n;
    term *= zSquared;
  }
  return exponent * _ln2 + 2 * sum;
}

Float64List _solitonCdf(int blockCount) {
  final cdf = Float64List(blockCount);
  if (blockCount == 1) {
    cdf[0] = 1;
    return cdf;
  }

  final robust = math.max(
    1.0,
    _solitonC *
        _deterministicLog(blockCount / _solitonDelta) *
        math.sqrt(blockCount),
  );
  final spike = math.min(blockCount, (blockCount / robust).ceil());
  var total = 0.0;

  for (var degree = 1; degree <= blockCount; degree++) {
    final rho = degree == 1 ? 1 / blockCount : 1 / (degree * (degree - 1));
    var tau = 0.0;
    if (degree < spike) {
      tau = robust / (degree * blockCount);
    } else if (degree == spike) {
      tau =
          (robust * math.max(0, _deterministicLog(robust / _solitonDelta))) /
          blockCount;
    }
    total += rho + tau;
    cdf[degree - 1] = total;
  }

  for (var index = 0; index < blockCount; index++) {
    cdf[index] = cdf[index] / total;
  }
  cdf[blockCount - 1] = 1;
  return cdf;
}

List<int> frameBlockIndices(
  int blockCount,
  Float64List cdf,
  int sessionId,
  int sequence, {
  int protocolVersion = currentProtocolVersion,
  bool? systematicFrames,
}) {
  final usesSystematicFrames =
      systematicFrames ?? protocolVersion >= currentProtocolVersion;
  if (usesSystematicFrames && !isRepairSequence(sequence)) {
    final group = sequence ~/ framesPerGroup;
    final sourceSlot = sequence % framesPerGroup;
    return <int>[(group * sourceFramesPerGroup + sourceSlot) % blockCount];
  }
  return _fountainIndices(
    blockCount,
    cdf,
    sessionId,
    sequence,
    capDegree: protocolVersion >= currentProtocolVersion,
  );
}

List<int> _fountainIndices(
  int blockCount,
  Float64List cdf,
  int sessionId,
  int sequence, {
  required bool capDegree,
}) {
  final random = splitmix32(frameSeed(sessionId, sequence));
  final sample = random() / 0x100000000;
  var low = 0;
  var high = blockCount - 1;
  while (low < high) {
    final middle = (low + high) >> 1;
    if (cdf[middle] >= sample) {
      high = middle;
    } else {
      low = middle + 1;
    }
  }
  final sampledDegree = math.min(blockCount, low + 1);
  final degree = capDegree
      ? math.min(sampledDegree, _maximumRepairDegree)
      : sampledDegree;

  if (degree > (blockCount >> 3)) {
    final scratch = Uint32List(blockCount);
    for (var index = 0; index < blockCount; index++) {
      scratch[index] = index;
    }
    final result = <int>[];
    for (var index = 0; index < degree; index++) {
      final swapIndex = index + (random() % (blockCount - index));
      final temporary = scratch[index];
      scratch[index] = scratch[swapIndex];
      scratch[swapIndex] = temporary;
      result.add(scratch[index]);
    }
    return result;
  }

  final result = <int>{};
  while (result.length < degree) {
    result.add(random() % blockCount);
  }
  return result.toList(growable: false);
}

void _xorInto(Uint32List target, Uint32List source) {
  for (var index = 0; index < target.length; index++) {
    target[index] = target[index] ^ source[index];
  }
}

class LTEncoder {
  LTEncoder({
    required Uint8List payload,
    required this.blockLength,
    required this.sessionId,
    int protocolVersion = currentProtocolVersion,
    bool? systematicFrames,
  }) : blockCount = blockLength > 0
           ? math.max(1, (payload.length / blockLength).ceil())
           : 1,
       protocolVersion = protocolVersion,
       usesSystematicFrames =
           systematicFrames ?? protocolVersion >= currentProtocolVersion,
       _payload = payload {
    if (payload.isEmpty) {
      throw ArgumentError.value(payload.length, 'payload', 'cannot be empty');
    }
    if (blockLength <= 0 || blockLength > 0xffff) {
      throw ArgumentError.value(blockLength, 'blockLength');
    }
    _cdf = _solitonCdf(blockCount);
  }

  final int blockLength;
  final int sessionId;
  final int protocolVersion;
  final bool usesSystematicFrames;
  final int blockCount;
  final Uint8List _payload;
  late final Float64List _cdf;

  Uint8List encode(int sequence) {
    final indices = frameBlockIndices(
      blockCount,
      _cdf,
      sessionId,
      sequence,
      protocolVersion: protocolVersion,
      systematicFrames: usesSystematicFrames,
    );
    final output = Uint8List(blockLength);
    if (indices.length == 1) {
      final start = indices.single * blockLength;
      final end = math.min(start + blockLength, _payload.length);
      if (start < end) output.setRange(0, end - start, _payload, start);
      return output;
    }

    for (final blockIndex in indices) {
      final start = blockIndex * blockLength;
      final available = math.min(blockLength, _payload.length - start);
      for (var byte = 0; byte < available; byte++) {
        output[byte] ^= _payload[start + byte];
      }
    }
    return output;
  }
}

class _PendingFrame {
  _PendingFrame(this.indices, this.words);

  final Set<int> indices;
  final Uint32List words;
}

class LTDecoder {
  LTDecoder({
    required this.blockCount,
    required this.blockLength,
    required this.sessionId,
    required this.totalLength,
    int protocolVersion = currentProtocolVersion,
    bool? systematicFrames,
  }) : _words = (blockLength / 4).ceil(),
       protocolVersion = protocolVersion,
       usesSystematicFrames =
           systematicFrames ?? protocolVersion >= currentProtocolVersion,
       _cdf = _solitonCdf(blockCount),
       _solved = List<Uint32List?>.filled(blockCount, null),
       _maximumPendingFrames = math.min(
         blockCount * 2,
         _maximumPendingFrameLimit,
       );

  final int blockCount;
  final int blockLength;
  final int sessionId;
  final int totalLength;
  final int protocolVersion;
  final bool usesSystematicFrames;
  final int _words;
  final Float64List _cdf;
  final List<Uint32List?> _solved;
  final int _maximumPendingFrames;
  final Map<int, Set<_PendingFrame>> _waitingByBlock = {};
  final Set<int> _seen = {};
  final Queue<int> _seenOrder = Queue<int>();

  int solvedCount = 0;
  int framesNew = 0;
  int framesDuplicate = 0;
  int framesDiscarded = 0;
  int _pendingFrames = 0;

  bool get isComplete => solvedCount >= blockCount;

  void addFrame(int sequence, Uint8List block) {
    if (block.length != blockLength) {
      framesDiscarded++;
      return;
    }
    if (!_seen.add(sequence)) {
      framesDuplicate++;
      return;
    }
    _seenOrder.addLast(sequence);
    if (_seenOrder.length > _seenSequenceWindow) {
      _seen.remove(_seenOrder.removeFirst());
    }
    framesNew++;
    if (isComplete) return;

    final indices = frameBlockIndices(
      blockCount,
      _cdf,
      sessionId,
      sequence,
      protocolVersion: protocolVersion,
      systematicFrames: usesSystematicFrames,
    ).toSet();
    final words = Uint32List(_words);
    Uint8List.view(words.buffer).setRange(0, blockLength, block);

    for (final blockIndex in indices.toList(growable: false)) {
      final solved = _solved[blockIndex];
      if (solved != null) {
        _xorInto(words, solved);
        indices.remove(blockIndex);
      }
    }

    if (indices.isEmpty) return;
    if (indices.length == 1) {
      _resolve(indices.first, words);
      return;
    }
    if (_pendingFrames >= _maximumPendingFrames) {
      framesDiscarded++;
      return;
    }

    final pending = _PendingFrame(indices, words);
    _pendingFrames++;
    for (final blockIndex in indices) {
      (_waitingByBlock[blockIndex] ??= <_PendingFrame>{}).add(pending);
    }
  }

  void _resolve(int firstBlock, Uint32List firstWords) {
    final queue = <(int, Uint32List)>[(firstBlock, firstWords)];
    while (queue.isNotEmpty) {
      final (blockIndex, words) = queue.removeLast();
      if (_solved[blockIndex] != null) continue;
      _solved[blockIndex] = words;
      solvedCount++;

      final waiting = _waitingByBlock.remove(blockIndex);
      if (waiting == null) continue;
      for (final pending in waiting) {
        _xorInto(pending.words, words);
        pending.indices.remove(blockIndex);
        if (pending.indices.length == 1) {
          final remaining = pending.indices.first;
          _waitingByBlock[remaining]?.remove(pending);
          _pendingFrames--;
          if (_solved[remaining] == null) {
            queue.add((remaining, pending.words));
          }
        }
      }
    }
  }

  Uint8List? assemble() {
    if (!isComplete) return null;
    final output = Uint8List(totalLength);
    for (var block = 0; block < blockCount; block++) {
      final start = block * blockLength;
      final length = math.min(blockLength, totalLength - start);
      if (length <= 0) continue;
      final solved = _solved[block];
      if (solved == null) return null;
      output.setRange(start, start + length, Uint8List.view(solved.buffer));
    }
    return output;
  }
}
