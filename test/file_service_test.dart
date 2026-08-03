import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onesend/core/envelope.dart';
import 'package:onesend/core/optical_transfer.dart';
import 'package:onesend/services/file_service.dart';

void main() {
  test('safeStorageFileName keeps one safe path component', () {
    expect(safeStorageFileName('../CON.txt'), '.._CON.txt');
    expect(safeStorageFileName('  report?.txt  '), 'report_.txt');
    expect(safeStorageFileName('..'), 'received.bin');
  });

  test('location descriptions and desktop reveal commands are displayable', () {
    expect(
      describeStoredFileLocation('/tmp/OneSend/a.txt', mobile: false),
      '已保存到：/tmp/OneSend/a.txt',
    );
    final command = desktopRevealCommand(
      '/tmp/OneSend/a.txt',
      operatingSystem: 'macos',
    );
    expect(command.executable, 'open');
    expect(command.arguments, <String>['-R', '/tmp/OneSend/a.txt']);
  });

  test('received directories stay inside the platform base directory', () {
    const base = '/tmp/onesend-base';

    expect(
      receivedDirectoryPath(base, operatingSystem: 'ios'),
      '$base/Received',
    );
    expect(
      receivedDirectoryPath(base, operatingSystem: 'android'),
      '$base/Received',
    );
    expect(
      receivedDirectoryPath(base, operatingSystem: 'macos'),
      '$base/OneSend/Received',
    );
  });

  test('mobile locations hide sandbox paths and explain how to export', () {
    const iosSandbox =
        '/private/var/mobile/Containers/Data/Application/ABC/Documents/Received/notes.txt';
    final iosLocation = describeStoredFileLocation(
      iosSandbox,
      operatingSystem: 'ios',
    );
    expect(iosLocation, contains('notes.txt'));
    expect(iosLocation, isNot(contains('/private/var/mobile')));

    const androidSandbox = '/data/user/0/com.example.onesend/files/notes.txt';
    final androidLocation = describeStoredFileLocation(
      androidSandbox,
      operatingSystem: 'android',
    );
    expect(androidLocation, contains('notes.txt'));
    expect(androidLocation, contains('另存副本'));
    expect(androidLocation, isNot(contains('/data/user/0')));
  });

  test('transfer speed labels use the transport mode useful throughput', () {
    expect(
      formatTransferSpeed(TransferMode.fast.usefulBytesPerSecond),
      '33 KB/s',
    );
    expect(
      formatTransferSpeed(TransferMode.reliable.usefulBytesPerSecond),
      '4.7 KB/s',
    );
  });

  test('received files are saved with a safe unique name', () async {
    final baseDirectory = await Directory.systemTemp.createTemp(
      'onesend-file-service-test-',
    );
    addTearDown(() => baseDirectory.delete(recursive: true));

    final file = TransferFile(
      name: '../notes?.txt',
      mimeType: 'text/plain',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );
    final first = await saveReceivedFile(file, baseDirectory: baseDirectory);
    final second = await saveReceivedFile(file, baseDirectory: baseDirectory);

    expect(first.name, '.._notes_.txt');
    expect(second.name, '.._notes_ (2).txt');
    expect(first.locationDescription, contains(first.path));
    expect(await File(first.path).readAsBytes(), <int>[1, 2, 3]);
  });

  test('opening a missing file fails with a clear message', () async {
    expect(
      () => openStoredPath('/tmp/onesend-file-service-missing-file'),
      throwsA(
        predicate<Object>((error) => error.toString().contains('打开文件失败：文件不存在')),
      ),
    );
  });
}
