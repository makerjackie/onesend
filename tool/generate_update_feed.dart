import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (!await options.signingTool.exists()) {
    throw StateError(
      'Missing Sparkle signing tool: ${options.signingTool.path}',
    );
  }
  if (!await options.privateKey.exists()) {
    throw StateError('Missing Ed25519 private key: ${options.privateKey.path}');
  }
  await options.output.create(recursive: true);

  final macos = await _asset(options.macos, 'macos');
  final windows = await _asset(options.windows, 'windows');
  final linux = await _asset(options.linux, 'linux');
  final macSignature = await _signArchive(options, options.macos);
  final windowsSignature = await _signArchive(options, options.windows);

  final publishedAt = options.publishedAt ?? DateTime.now().toUtc();
  final releaseUrl =
      'https://github.com/makerjackie/onesend/releases/tag/v${options.version}';
  final downloadPrefix =
      'https://github.com/makerjackie/onesend/releases/download/v${options.version}';
  final notesHtml =
      '<ul>${options.notes.map((note) => '<li>${_htmlEscape(note)}</li>').join()}</ul>';
  final pubDate = _rfc822(publishedAt);

  final appcast =
      '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>OneSend stable updates</title>
    <link>https://onesend.01mvp.com</link>
    <description>Stable desktop releases for OneSend · 扫传</description>
    <language>zh-cn</language>
    <item>
      <title>OneSend ${options.version}</title>
      <link>$releaseUrl</link>
      <sparkle:version>${options.buildNumber}</sparkle:version>
      <sparkle:shortVersionString>${options.version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>10.15</sparkle:minimumSystemVersion>
      <description><![CDATA[$notesHtml]]></description>
      <pubDate>$pubDate</pubDate>
      <enclosure
        url="$downloadPrefix/${macos.fileName}"
        sparkle:edSignature="${macSignature.signature}"
        sparkle:os="macos"
        length="${macos.length}"
        type="application/octet-stream" />
    </item>
    <item>
      <title>OneSend ${options.version}</title>
      <link>$releaseUrl</link>
      <sparkle:version>${options.buildNumber}</sparkle:version>
      <sparkle:shortVersionString>${options.version}</sparkle:shortVersionString>
      <description><![CDATA[$notesHtml]]></description>
      <pubDate>$pubDate</pubDate>
      <enclosure
        url="$downloadPrefix/${windows.fileName}"
        sparkle:edSignature="${windowsSignature.signature}"
        sparkle:installerArguments="/SILENT /SP- /NOICONS /NORESTART /ONESENDUPDATE=1"
        sparkle:os="windows-x64"
        length="${windows.length}"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
''';

  final appcastFile = File('${options.output.path}/appcast.xml');
  await appcastFile.writeAsString(appcast, flush: true);
  await _runSigningTool(options, [appcastFile.path]);

  final payload = utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'version': options.version,
      'buildNumber': options.buildNumber,
      'publishedAt': publishedAt.toIso8601String(),
      'releasePage': releaseUrl,
      'notes': options.notes,
      'assets': {
        'macos': macos.toJson('$downloadPrefix/${macos.fileName}'),
        'windows': windows.toJson('$downloadPrefix/${windows.fileName}'),
        'linux': linux.toJson('$downloadPrefix/${linux.fileName}'),
      },
    }),
  );
  final payloadFile = File('${options.output.path}/.latest.payload.json');
  await payloadFile.writeAsBytes(payload, flush: true);
  final payloadSignature = (await _runSigningTool(options, [
    '-p',
    payloadFile.path,
  ])).trim();
  await payloadFile.delete();
  _validateSignature(payloadSignature);

  final latestFile = File('${options.output.path}/latest.json');
  await latestFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'algorithm': 'ed25519',
      'payload': base64Encode(payload),
      'signature': payloadSignature,
    }),
    flush: true,
  );

  stdout.writeln('Generated signed update feed for ${options.version}.');
  stdout.writeln('  ${appcastFile.path}');
  stdout.writeln('  ${latestFile.path}');
}

Future<_ReleaseAsset> _asset(File file, String platform) async {
  if (!await file.exists()) {
    throw StateError('Missing $platform artifact: ${file.path}');
  }
  final length = await file.length();
  if (length <= 0 || length > _maxArtifactBytes) {
    throw StateError('$platform artifact has an invalid size: $length');
  }
  final fileName = file.uri.pathSegments.last;
  if (fileName != _expectedArtifactNames[platform]) {
    throw StateError('$platform artifact has an unstable filename: $fileName');
  }
  final digest = await sha256.bind(file.openRead()).first;
  return _ReleaseAsset(
    fileName: fileName,
    sha256: digest.toString(),
    length: length,
  );
}

Future<_ArchiveSignature> _signArchive(_Options options, File file) async {
  final output = await _runSigningTool(options, [file.path]);
  final signature = RegExp(
    r'sparkle:edSignature="([A-Za-z0-9+/=]+)"',
  ).firstMatch(output)?.group(1);
  final lengthText = RegExp(r'length="(\d+)"').firstMatch(output)?.group(1);
  if (signature == null || lengthText == null) {
    throw StateError('The signing tool returned an unexpected result.');
  }
  _validateSignature(signature);
  final signedLength = int.parse(lengthText);
  if (signedLength != await file.length()) {
    throw StateError('The signing tool reported the wrong artifact length.');
  }
  return _ArchiveSignature(signature);
}

Future<String> _runSigningTool(_Options options, List<String> arguments) async {
  final result = await Process.run(options.signingTool.path, [
    '--ed-key-file',
    options.privateKey.path,
    ...arguments,
  ]);
  if (result.exitCode != 0) {
    throw ProcessException(
      options.signingTool.path,
      arguments,
      result.stderr.toString(),
      result.exitCode,
    );
  }
  return result.stdout.toString();
}

void _validateSignature(String value) {
  List<int> bytes;
  try {
    bytes = base64Decode(value);
  } on FormatException {
    throw StateError('The signing tool returned invalid base64.');
  }
  if (bytes.length != 64) {
    throw StateError('The signing tool returned an invalid Ed25519 signature.');
  }
}

String _rfc822(DateTime value) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final utc = value.toUtc();
  return '${weekdays[utc.weekday - 1]}, '
      '${utc.day.toString().padLeft(2, '0')} ${months[utc.month - 1]} '
      '${utc.year} ${utc.hour.toString().padLeft(2, '0')}:'
      '${utc.minute.toString().padLeft(2, '0')}:'
      '${utc.second.toString().padLeft(2, '0')} +0000';
}

String _htmlEscape(String value) => const HtmlEscape().convert(value);

class _ArchiveSignature {
  const _ArchiveSignature(this.signature);

  final String signature;
}

class _ReleaseAsset {
  const _ReleaseAsset({
    required this.fileName,
    required this.sha256,
    required this.length,
  });

  final String fileName;
  final String sha256;
  final int length;

  Map<String, Object> toJson(String url) => {
    'url': url,
    'fileName': fileName,
    'sha256': sha256,
    'length': length,
  };
}

class _Options {
  const _Options({
    required this.version,
    required this.buildNumber,
    required this.macos,
    required this.windows,
    required this.linux,
    required this.output,
    required this.signingTool,
    required this.privateKey,
    required this.notes,
    this.publishedAt,
  });

  factory _Options.parse(List<String> arguments) {
    final values = <String, String>{};
    final notes = <String>[];
    const knownOptions = <String>{
      '--version',
      '--build',
      '--macos',
      '--windows',
      '--linux',
      '--output',
      '--sign-tool',
      '--private-key',
      '--published-at',
      '--note',
    };
    for (var index = 0; index < arguments.length; index++) {
      final name = arguments[index];
      if (!name.startsWith('--') || index + 1 >= arguments.length) {
        throw const FormatException('Every option requires a value.');
      }
      if (!knownOptions.contains(name)) {
        throw FormatException('Unknown option: $name');
      }
      final value = arguments[++index];
      if (name == '--note') {
        final note = value.trim();
        if (note.isEmpty ||
            note.length > 240 ||
            note.runes.any((rune) => rune < 0x20 || rune == 0x7f)) {
          throw const FormatException(
            'Each --note must be one line containing 1 to 240 characters.',
          );
        }
        notes.add(note);
      } else {
        values[name] = value;
      }
    }

    String requiredValue(String name) {
      final value = values[name];
      if (value == null || value.isEmpty) {
        throw FormatException('$name is required.');
      }
      return value;
    }

    final version = requiredValue('--version');
    if (!RegExp(r'^\d{1,9}\.\d{1,9}\.\d{1,9}$').hasMatch(version)) {
      throw const FormatException('--version must use major.minor.patch.');
    }
    final buildNumber = int.tryParse(requiredValue('--build'));
    if (buildNumber == null || buildNumber <= 0) {
      throw const FormatException('--build must be a positive integer.');
    }
    if (notes.isEmpty) {
      throw const FormatException('At least one --note is required.');
    }
    if (notes.length > 12) {
      throw const FormatException('No more than 12 --note values are allowed.');
    }
    DateTime? publishedAt;
    final publishedAtValue = values['--published-at'];
    if (publishedAtValue != null) {
      publishedAt = DateTime.parse(publishedAtValue);
      if (!publishedAt.isUtc) {
        throw const FormatException(
          '--published-at must include a UTC suffix.',
        );
      }
    }

    return _Options(
      version: version,
      buildNumber: buildNumber,
      macos: File(requiredValue('--macos')),
      windows: File(requiredValue('--windows')),
      linux: File(requiredValue('--linux')),
      output: Directory(requiredValue('--output')),
      signingTool: File(requiredValue('--sign-tool')),
      privateKey: File(requiredValue('--private-key')),
      notes: List.unmodifiable(notes),
      publishedAt: publishedAt,
    );
  }

  final String version;
  final int buildNumber;
  final File macos;
  final File windows;
  final File linux;
  final Directory output;
  final File signingTool;
  final File privateKey;
  final List<String> notes;
  final DateTime? publishedAt;
}

const Map<String, String> _expectedArtifactNames = <String, String>{
  'macos': 'onesend-macos-universal.zip',
  'windows': 'onesend-windows-setup.exe',
  'linux': 'onesend-linux-x64.tar.gz',
};

const int _maxArtifactBytes = 512 * 1024 * 1024;
