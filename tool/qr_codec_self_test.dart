import 'dart:io';

const _nativeQrCodecSelfTestDefine = 'ONESEND_NATIVE_QR_SELF_TEST=true';

Future<void> main() async {
  final repoRoot = File.fromUri(Platform.script).parent.parent;
  stdout.writeln(
    'Running the native QR self-test through the standard OneSend macOS app.',
  );

  final buildExitCode = await _runProcess(
    'flutter',
    const [
      'build',
      'macos',
      '--release',
      '--dart-define=$_nativeQrCodecSelfTestDefine',
    ],
    workingDirectory: repoRoot,
    runInShell: true,
  );
  if (buildExitCode != 0) exit(buildExitCode);

  final executable = File(
    '${repoRoot.path}/build/macos/Build/Products/Release/'
    'OneSend.app/Contents/MacOS/OneSend',
  );
  if (!executable.existsSync()) {
    stderr.writeln('Standard OneSend.app executable was not produced.');
    exit(1);
  }

  exit(
    await _runProcess(executable.path, const [], workingDirectory: repoRoot),
  );
}

Future<int> _runProcess(
  String executable,
  List<String> arguments, {
  required Directory workingDirectory,
  bool runInShell = false,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory.path,
    runInShell: runInShell,
  );
  final output = Future.wait<void>([
    process.stdout.pipe(stdout),
    process.stderr.pipe(stderr),
  ]);
  final exitCode = await process.exitCode;
  await output;
  return exitCode;
}
