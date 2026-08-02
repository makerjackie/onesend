/// Converts display-vsync timestamps into a stable optical frame cadence.
///
/// The caller emits one frame immediately, calls [reset], then invokes
/// [shouldEmit] for every display tick. Missed deadlines are skipped instead
/// of emitted in a burst because a camera can only observe the latest image.
class FramePacer {
  FramePacer(this.interval)
    : assert(interval > Duration.zero),
      _nextFrameMicros = interval.inMicroseconds;

  final Duration interval;
  int _nextFrameMicros;

  void reset() {
    _nextFrameMicros = interval.inMicroseconds;
  }

  bool shouldEmit(Duration elapsed) {
    final now = elapsed.inMicroseconds;
    if (now < _nextFrameMicros) return false;

    final intervalMicros = interval.inMicroseconds;
    final elapsedIntervals = ((now - _nextFrameMicros) ~/ intervalMicros) + 1;
    _nextFrameMicros += elapsedIntervals * intervalMicros;
    return true;
  }
}
