import 'dart:io';

Future<void> main() async {
  final repoRoot = File.fromUri(Platform.script).parent.parent;
  stdout.writeln(
    'Running the native QR self-test through the prebuilt OneSend macOS app.',
  );

  final executable = File(
    '${repoRoot.path}/build/macos/Build/Products/Release/'
    'OneSend.app/Contents/MacOS/OneSend',
  );
  if (!executable.existsSync()) {
    stderr.writeln(
      'Build the self-test app first:\n'
      'flutter build macos --release '
      '--dart-define=ONESEND_NATIVE_QR_SELF_TEST=true',
    );
    exit(1);
  }

  exit(
    // Keep a small non-Dart launcher between this tool and the Flutter GUI
    // binary. A direct Dart child can return 255 before Flutter initializes on
    // macOS, while the same executable reliably completes from Python/shell.
    await _runViaPython(executable.path, const [], workingDirectory: repoRoot),
  );
}

Future<int> _runViaPython(
  String executable,
  List<String> arguments, {
  required Directory workingDirectory,
}) {
  return _runProcess('/usr/bin/python3', <String>[
    '-c',
    'import os, subprocess, sys; '
        '[os.environ.pop(k, None) for k in list(os.environ) '
        "if k.startswith(('DART_', 'FLUTTER_', 'PUB_'))]; "
        'sys.exit(subprocess.run(sys.argv[1:], env=os.environ).returncode)',
    executable,
    ...arguments,
  ], workingDirectory: workingDirectory);
}

Future<int> _runProcess(
  String executable,
  List<String> arguments, {
  required Directory workingDirectory,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory.path,
  );
  final output = Future.wait<void>([
    process.stdout.pipe(stdout),
    process.stderr.pipe(stderr),
  ]);
  final exitCode = await process.exitCode;
  await output;
  return exitCode;
}
