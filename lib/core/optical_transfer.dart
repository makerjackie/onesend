import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'envelope.dart';
import 'fountain.dart';
import 'protocol.dart';

const int defaultBlockLength = 1450;
const double expectedFrameOverhead = 1.18;

class OpticalSender {
  OpticalSender({
    required this.payload,
    required this.fileName,
    required this.mimeType,
    required this.onFrame,
    this.blockLength = defaultBlockLength,
    this.frameInterval = const Duration(milliseconds: 42),
    this.onError,
  }) {
    sessionId = math.Random.secure().nextInt(0xffff) + 1;
    _encoder = LTEncoder(
      payload: payload,
      blockLength: blockLength,
      sessionId: sessionId,
    );
  }

  final Uint8List payload;
  final String fileName;
  final String mimeType;
  final void Function(Uint8List frame, int sequence) onFrame;
  final void Function(Object error)? onError;
  final int blockLength;
  final Duration frameInterval;
  late final int sessionId;
  late final LTEncoder _encoder;

  Timer? _timer;
  bool _running = false;
  bool _paused = true;
  int _sequence = 0;
  int framesEmitted = 0;

  int get blockCount => _encoder.blockCount;
  bool get isRunning => _running;
  bool get isPaused => _paused;

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
      final block = _encoder.encode(sequence);
      final frame = packFrame(
        FrameHeader(
          sessionId: sessionId,
          sequence: sequence,
          blockCount: blockCount,
          blockLength: blockLength,
          totalLength: payload.length,
          payloadHash: fnv1a(payload),
        ),
        block,
      );
      _sequence = (_sequence + 1) & 0xffffffff;
      framesEmitted++;
      onFrame(frame, sequence);
    } catch (error) {
      onError?.call(error);
      stop();
    }
  }
}

class ReceiverSnapshot {
  const ReceiverSnapshot({
    required this.sessionId,
    required this.blockCount,
    required this.blockLength,
    required this.totalLength,
    required this.framesNew,
    required this.framesDuplicate,
    required this.solvedBlocks,
  });

  final int sessionId;
  final int blockCount;
  final int blockLength;
  final int totalLength;
  final int framesNew;
  final int framesDuplicate;
  final int solvedBlocks;

  double get progress => math
      .min(0.99, framesNew / math.max(1, blockCount * expectedFrameOverhead))
      .toDouble();
}

class ReceiverEvent {
  const ReceiverEvent({
    required this.snapshot,
    this.file,
    this.verified = false,
  });

  final ReceiverSnapshot snapshot;
  final TransferFile? file;
  final bool verified;
}

class OpticalReceiver {
  LTDecoder? _decoder;
  FrameHeader? _configuration;
  DateTime? _startedAt;

  ReceiverSnapshot? get snapshot {
    final decoder = _decoder;
    if (decoder == null) return null;
    return ReceiverSnapshot(
      sessionId: decoder.sessionId,
      blockCount: decoder.blockCount,
      blockLength: decoder.blockLength,
      totalLength: decoder.totalLength,
      framesNew: decoder.framesNew,
      framesDuplicate: decoder.framesDuplicate,
      solvedBlocks: decoder.solvedCount,
    );
  }

  DateTime? get startedAt => _startedAt;

  ReceiverEvent? consume(Uint8List bytes) {
    final parsed = parseFrame(bytes);
    if (parsed == null) return null;
    final header = parsed.header;
    if (header.blockCount > 0xffff ||
        header.totalLength > 128 * 1024 * 1024 ||
        header.blockLength == 0) {
      return null;
    }

    if (_decoder == null || !_configuration!.matches(header)) {
      _configuration = header;
      _decoder = LTDecoder(
        blockCount: header.blockCount,
        blockLength: header.blockLength,
        sessionId: header.sessionId,
        totalLength: header.totalLength,
      );
      _startedAt = DateTime.now();
    }

    final decoder = _decoder!;
    decoder.addFrame(header.sequence, parsed.block);
    final current = snapshot!;
    if (!decoder.isComplete) return ReceiverEvent(snapshot: current);

    final payload = decoder.assemble();
    if (payload == null) return ReceiverEvent(snapshot: current);
    final verified = fnv1a(payload) == header.payloadHash;
    if (!verified) {
      return ReceiverEvent(snapshot: current, verified: false);
    }
    return ReceiverEvent(
      snapshot: current,
      file: decodeTransferFile(payload),
      verified: true,
    );
  }

  void reset() {
    _decoder = null;
    _configuration = null;
    _startedAt = null;
  }
}
