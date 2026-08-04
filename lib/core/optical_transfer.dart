import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'fountain.dart';
import 'protocol.dart';

const int maxOpticalPayloadBytes = 72 * 1024 * 1024;
const int maxOpticalBlocks = maxFountainBlockCount;
const int minOpticalBlockLength = 64;
// QR V40-L carries at most 2953 byte-mode bytes. The v2 frame spends 28
// bytes on its header and 4 bytes on its per-frame CRC, leaving 2921 bytes
// for the fountain block. Keep this limit here as a receiver-side guard too.
const int maxOpticalBlockLength = 2921;
const int opticalFrameOverheadBytes = frameHeaderLength + frameChecksumLength;
const int maxOpticalFrameLength =
    maxOpticalBlockLength + opticalFrameOverheadBytes;
const int maxRatelessFountainBlocks = 8192;
const Duration opticalReceiverDefaultSessionIdleTimeout = Duration(seconds: 15);

enum TransferMode {
  reliable(
    id: 0,
    label: '兼容',
    blockLength: 720,
    frameInterval: Duration(milliseconds: 125),
  ),
  fast(
    id: 2,
    label: '标准',
    blockLength: 1700,
    frameInterval: Duration(microseconds: 41667),
  ),
  turbo(
    id: 3,
    label: '快速',
    blockLength: 2921,
    frameInterval: Duration(microseconds: 41667),
  );

  const TransferMode({
    required this.id,
    required this.label,
    required this.blockLength,
    required this.frameInterval,
  });

  final int id;
  final String label;
  final int blockLength;
  final Duration frameInterval;

  int get framesPerSecond =>
      (Duration.microsecondsPerSecond / frameInterval.inMicroseconds).round();

  /// Net fountain-block bytes offered by the raw frame stream per second.
  int get rawBytesPerSecond => blockLength * framesPerSecond;

  /// Full protocol bytes put into QR per second, including the v2 frame
  /// header and CRC. This is a code-stream figure, not useful file throughput.
  int get theoreticalCodeStreamBytesPerSecond =>
      (blockLength + opticalFrameOverheadBytes) * framesPerSecond;

  /// Conservative net file throughput: reserve one of every five frame slots
  /// for repair/recovery. It is a protocol estimate, not a camera measurement.
  double get usefulBytesPerSecond =>
      rawBytesPerSecond * sourceFramesPerGroup / framesPerGroup;

  bool usesRatelessFountainFor(int blockCount) =>
      (this == fast || this == turbo) &&
      blockCount <= maxRatelessFountainBlocks;

  static TransferMode? fromId(int id) {
    return switch (id) {
      0 => reliable,
      1 || 2 => fast,
      3 => turbo,
      _ => null,
    };
  }

  static TransferMode? fromProfile(int id, int blockLength) {
    return switch ((id, blockLength)) {
      (0, 720) => reliable,
      // OneSend 1.1 fast streams remain readable after the 1.2 speed upgrade.
      (1, 1320) => fast,
      (2, 1700) => fast,
      (3, 2921) => turbo,
      _ => null,
    };
  }
}

class OpticalSender {
  OpticalSender({
    required this.payload,
    required this.fileName,
    required this.mimeType,
    required this.onFrame,
    this.mode = TransferMode.reliable,
    int? blockLength,
    Duration? frameInterval,
    this.useInternalClock = true,
    this.onError,
  }) : blockLength = blockLength ?? mode.blockLength,
       frameInterval = frameInterval ?? mode.frameInterval {
    if (payload.isEmpty || payload.length > maxOpticalPayloadBytes) {
      throw ArgumentError.value(
        payload.length,
        'payload',
        'must be between 1 byte and 72 MiB',
      );
    }
    if (this.blockLength != mode.blockLength) {
      throw ArgumentError.value(
        this.blockLength,
        'blockLength',
        'must match the selected transfer mode profile',
      );
    }
    if (this.frameInterval <= Duration.zero) {
      throw ArgumentError.value(
        this.frameInterval,
        'frameInterval',
        'must be positive',
      );
    }
    sessionId = math.Random.secure().nextInt(0xffffffff) + 1;
    payloadChecksum = crc32(payload);
    final expectedBlockCount = math.max(
      1,
      (payload.length + this.blockLength - 1) ~/ this.blockLength,
    );
    usesRatelessFountain = mode.usesRatelessFountainFor(expectedBlockCount);
    _encoder = LTEncoder(
      payload: payload,
      blockLength: this.blockLength,
      sessionId: sessionId,
      systematicFrames: !usesRatelessFountain,
    );
  }

  final Uint8List payload;
  final String fileName;
  final String mimeType;
  final void Function(Uint8List frame, int sequence) onFrame;
  final void Function(Object error)? onError;
  final TransferMode mode;
  final int blockLength;
  final Duration frameInterval;
  final bool useInternalClock;
  late final int sessionId;
  late final int payloadChecksum;
  late final bool usesRatelessFountain;
  late final LTEncoder _encoder;

  Timer? _timer;
  bool _running = false;
  bool _paused = true;
  int _sequence = 0;
  int framesEmitted = 0;
  int sourceFramesEmitted = 0;
  int repairFramesEmitted = 0;

  int get blockCount => _encoder.blockCount;
  bool get isRunning => _running;
  bool get isPaused => _paused;
  int get passNumber =>
      (usesRatelessFountain ? framesEmitted : sourceFramesEmitted) ~/
          blockCount +
      1;
  double get passProgress =>
      ((usesRatelessFountain ? framesEmitted : sourceFramesEmitted) %
          blockCount) /
      blockCount;

  void start() {
    if (_running) return;
    _running = true;
    resume();
  }

  void pause() {
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    if (!_running || !_paused) return;
    _paused = false;
    _emit();
    if (useInternalClock) {
      _timer = Timer.periodic(frameInterval, (_) => _emit());
    }
  }

  /// Emits the next frame when playback is driven by display vsync.
  void emitNext() => _emit();

  void stop() {
    _running = false;
    pause();
  }

  void dispose() => stop();

  void _emit() {
    if (!_running || _paused) return;
    try {
      final sequence = _sequence;
      final repair = usesRatelessFountain || isRepairSequence(sequence);
      final block = _encoder.encode(sequence);
      final frame = packFrame(
        FrameHeader(
          profileId: mode.id,
          sessionId: sessionId,
          sequence: sequence,
          blockCount: blockCount,
          blockLength: blockLength,
          totalLength: payload.length,
          payloadChecksum: payloadChecksum,
        ),
        block,
      );
      _sequence = (_sequence + 1) & 0xffffffff;
      framesEmitted++;
      if (repair) {
        repairFramesEmitted++;
      } else {
        sourceFramesEmitted++;
      }
      onFrame(frame, sequence);
    } catch (error) {
      onError?.call(error);
      stop();
    }
  }
}

class ReceiverSnapshot {
  const ReceiverSnapshot({
    required this.protocolVersion,
    required this.profileId,
    required this.sessionId,
    required this.blockCount,
    required this.blockLength,
    required this.totalLength,
    required this.framesNew,
    required this.framesDuplicate,
    required this.framesDiscarded,
    required this.solvedBlocks,
  });

  final int protocolVersion;
  final int profileId;
  final int sessionId;
  final int blockCount;
  final int blockLength;
  final int totalLength;
  final int framesNew;
  final int framesDuplicate;
  final int framesDiscarded;
  final int solvedBlocks;

  TransferMode? get mode => TransferMode.fromProfile(profileId, blockLength);
  bool get usesRatelessFountain {
    if (protocolVersion < currentProtocolVersion) return false;
    final transferMode = mode;
    return transferMode?.usesRatelessFountainFor(blockCount) ?? false;
  }

  double get progress {
    if (blockCount == 0) return 0;
    if (!usesRatelessFountain) {
      return math.min(1, solvedBlocks / blockCount).toDouble();
    }
    if (solvedBlocks >= blockCount) return 1;
    // LT peeling resolves most blocks near the end. Accepted-frame progress is
    // linear and avoids a progress bar that appears frozen before completion.
    return math.min(0.95, framesNew / (blockCount * 1.25)).toDouble();
  }
}

class ReceiverEvent {
  const ReceiverEvent({
    required this.snapshot,
    this.payload,
    this.verified = false,
    this.error,
  });

  final ReceiverSnapshot snapshot;
  final Uint8List? payload;
  final bool verified;
  final String? error;
}

class OpticalReceiver {
  OpticalReceiver({
    this.sessionIdleTimeout = opticalReceiverDefaultSessionIdleTimeout,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    if (sessionIdleTimeout <= Duration.zero) {
      throw ArgumentError.value(
        sessionIdleTimeout,
        'sessionIdleTimeout',
        'must be positive',
      );
    }
  }

  final Duration sessionIdleTimeout;
  final DateTime Function() _clock;
  LTDecoder? _decoder;
  FrameHeader? _configuration;
  DateTime? _startedAt;
  DateTime? _lastFrameAt;
  bool _delivered = false;

  ReceiverSnapshot? get snapshot {
    final decoder = _decoder;
    final configuration = _configuration;
    if (decoder == null || configuration == null) return null;
    return ReceiverSnapshot(
      protocolVersion: configuration.protocolVersion,
      profileId: configuration.profileId,
      sessionId: decoder.sessionId,
      blockCount: decoder.blockCount,
      blockLength: decoder.blockLength,
      totalLength: decoder.totalLength,
      framesNew: decoder.framesNew,
      framesDuplicate: decoder.framesDuplicate,
      framesDiscarded: decoder.framesDiscarded,
      solvedBlocks: decoder.solvedCount,
    );
  }

  DateTime? get startedAt => _startedAt;

  ReceiverEvent? consume(Uint8List bytes) {
    final parsed = parseFrame(bytes);
    if (parsed == null) return null;
    final header = parsed.header;
    if (header.totalLength > maxOpticalPayloadBytes ||
        header.blockLength < minOpticalBlockLength ||
        header.blockLength > maxOpticalBlockLength ||
        header.blockCount > maxOpticalBlocks) {
      return null;
    }
    TransferMode? mode;
    if (header.protocolVersion == currentProtocolVersion) {
      mode = TransferMode.fromProfile(header.profileId, header.blockLength);
      if (mode == null) return null;
    }
    final usesRatelessFountain =
        header.protocolVersion >= currentProtocolVersion &&
        (mode?.usesRatelessFountainFor(header.blockCount) ?? false);

    final now = _clock();
    final configuration = _configuration;
    if (configuration != null && !configuration.matches(header)) {
      // A camera can keep an old session locked forever after a sender has
      // disappeared. Retain the protection against live cross-talk, but allow
      // a new sender to take over after a genuine idle period.
      if (!_isSessionIdle(now)) return null;
      reset();
    }

    if (_decoder == null) {
      _configuration = header;
      _decoder = LTDecoder(
        blockCount: header.blockCount,
        blockLength: header.blockLength,
        sessionId: header.sessionId,
        totalLength: header.totalLength,
        protocolVersion: header.protocolVersion,
        systematicFrames: !usesRatelessFountain,
      );
      _startedAt = now;
      _lastFrameAt = now;
      _delivered = false;
    }

    final decoder = _decoder!;
    decoder.addFrame(header.sequence, parsed.block);
    _lastFrameAt = now;
    final current = snapshot!;
    if (!decoder.isComplete || _delivered) {
      return ReceiverEvent(snapshot: current);
    }

    final payload = decoder.assemble();
    if (payload == null) return ReceiverEvent(snapshot: current);
    final verified = header.protocolVersion == 1
        ? fnv1a(payload) == header.payloadChecksum
        : crc32(payload) == header.payloadChecksum;
    if (!verified) {
      return ReceiverEvent(snapshot: current, error: '文件整体校验失败，请重新开始传输。');
    }
    _delivered = true;
    return ReceiverEvent(snapshot: current, payload: payload, verified: true);
  }

  void reset() {
    _decoder = null;
    _configuration = null;
    _startedAt = null;
    _lastFrameAt = null;
    _delivered = false;
  }

  bool _isSessionIdle(DateTime now) {
    final lastFrameAt = _lastFrameAt;
    return lastFrameAt != null &&
        now.difference(lastFrameAt) >= sessionIdleTimeout;
  }
}
