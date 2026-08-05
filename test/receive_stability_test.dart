import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/screens/receive_screen.dart';

void main() {
  test('duplicate QR snapshots do not request a receive UI rebuild', () {
    final current = _snapshot(framesNew: 12, framesDuplicate: 2, solved: 8);
    final duplicate = _snapshot(framesNew: 12, framesDuplicate: 3, solved: 8);

    expect(receiverSnapshotHasUsefulChange(current, duplicate), isFalse);
  });

  test('new QR data or a new session still rebuilds receive UI', () {
    final current = _snapshot(framesNew: 12, framesDuplicate: 2, solved: 8);
    final advanced = _snapshot(framesNew: 13, framesDuplicate: 2, solved: 9);
    final nextSession = _snapshot(
      sessionId: 2,
      framesNew: 1,
      framesDuplicate: 0,
      solved: 1,
    );

    expect(receiverSnapshotHasUsefulChange(null, current), isTrue);
    expect(receiverSnapshotHasUsefulChange(current, advanced), isTrue);
    expect(receiverSnapshotHasUsefulChange(current, nextSession), isTrue);
  });
}

ReceiverSnapshot _snapshot({
  int sessionId = 1,
  required int framesNew,
  required int framesDuplicate,
  required int solved,
}) => ReceiverSnapshot(
  protocolVersion: 2,
  profileId: TransferMode.fast.id,
  sessionId: sessionId,
  blockCount: 20,
  blockLength: TransferMode.fast.blockLength,
  totalLength: 20000,
  framesNew: framesNew,
  framesDuplicate: framesDuplicate,
  framesDiscarded: 0,
  solvedBlocks: solved,
);
