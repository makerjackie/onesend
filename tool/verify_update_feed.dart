import 'dart:io';

import 'package:onesend/core/update_manifest.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/verify_update_feed.dart '
      '<latest.json> <version> <build-number>',
    );
    exitCode = 2;
    return;
  }

  final file = File(arguments[0]);
  final expectedVersion = arguments[1];
  final expectedBuild = int.tryParse(arguments[2]);
  if (!await file.exists() || expectedBuild == null || expectedBuild <= 0) {
    stderr.writeln('The feed path or expected build number is invalid.');
    exitCode = 2;
    return;
  }

  try {
    final release = await parseSignedUpdateManifest(await file.readAsBytes());
    if (release.version != expectedVersion ||
        release.buildNumber != expectedBuild) {
      throw StateError(
        'Expected $expectedVersion ($expectedBuild), got '
        '${release.version} (${release.buildNumber}).',
      );
    }
    for (final platform in const <OneSendDesktopPlatform>[
      OneSendDesktopPlatform.macos,
      OneSendDesktopPlatform.windows,
      OneSendDesktopPlatform.linux,
    ]) {
      final asset = release.assetFor(platform);
      stdout.writeln(
        '${platform.manifestName}: ${asset.fileName} '
        '(${asset.length} bytes, ${asset.sha256})',
      );
    }
    stdout.writeln('Signed update feed is valid.');
  } on Object catch (error) {
    stderr.writeln('Update feed verification failed: $error');
    exitCode = 1;
  }
}
