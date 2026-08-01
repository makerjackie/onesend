import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'fountain.dart';
import 'protocol.dart';

const int maxOpticalPayloadBytes = 72 * 1024 * 1024;
const int maxOpticalBlocks = 110000;
const int minOpticalBlockLength = 64;
const int maxOpticalBlockLength = 2048;

enum TransferMode {
  reliable(
    id: 0,
    label: '可靠',
    blockLength: 720,
    frameInterval: Duration(milliseconds: 125),
  ),
  fast(
    id: 1,
    label: '快速',
    blockLength: 1320,
    frameInterval: Duration(milliseconds: 67),
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
      (Duration.millisecondsPerSecond / frameInterval.inMilliseconds).round();

  static TransferMode? fromId(int id) {
    for (final mode in values) {
      if (mode.id == id) return mode;
    }
    return null;
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
    this.onError,
  }) : blockLength = blockLength ?? mode.blockLength,
       frameInterval = frameInterval ?? mode.frameInterval {
    sessionId = math.Random.secure().nextInt(0xffffffff) + 1;
    payloadChecksum = crc32(payload);
    _encoder = LTEncoder(
      payload: payload,
      blockLength: this.blockLength,
      sessionId: sessionId,
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
  late final int sessionId;
  late final int payloadChecksum;
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
  int get sourcePassNumber => sourceFramesEmitted ~/ blockCount + 1;
  double get sourcePassProgress =>
      (sourceFramesEmitted % blockCount) / blockCount;

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
    _timer = Timer.periodic(frameInterval, (_) => _emit());
  }

  void stop() {
    _running = false;
    pause();
  }

  void dispose() => stop();

  void _emit() {
    if (!_running || _paused) return;
    try {
      final sequence = _sequence;
      final repair = isRepairSequence(sequence);
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

  TransferMode? get mode => TransferMode.fromId(profileId);
  double get progress =>
      blockCount == 0 ? 0 : math.min(1, solvedBlocks / blockCount).toDouble();
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
  LTDecoder? _decoder;
  FrameHeader? _configuration;
  DateTime? _startedAt;
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
    if (header.protocolVersion == currentProtocolVersion) {
      final mode = TransferMode.fromId(header.profileId);
      if (mode == null || header.blockLength != mode.blockLength) return null;
    }

    if (_decoder == null) {
      _configuration = header;
      _decoder = LTDecoder(
        blockCount: header.blockCount,
        blockLength: header.blockLength,
        sessionId: header.sessionId,
        totalLength: header.totalLength,
        protocolVersion: header.protocolVersion,
      );
      _startedAt = DateTime.now();
      _delivered = false;
    } else if (!_configuration!.matches(header)) {
      // Do not let a different QR session destroy an in-progress transfer.
      // The user can explicitly restart when they want to switch senders.
      return null;
    }

    final decoder = _decoder!;
    decoder.addFrame(header.sequence, parsed.block);
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
    _delivered = false;
  }
}
