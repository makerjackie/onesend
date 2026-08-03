import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';

const String oneSendUpdatePublicKey =
    'zkX233D6ILzCJFNMMlmEY3ilrRAAG/ejsbZAMCUyBUI=';

enum OneSendDesktopPlatform { macos, windows, linux, unsupported }

extension OneSendDesktopPlatformName on OneSendDesktopPlatform {
  String? get manifestName => switch (this) {
    OneSendDesktopPlatform.macos => 'macos',
    OneSendDesktopPlatform.windows => 'windows',
    OneSendDesktopPlatform.linux => 'linux',
    OneSendDesktopPlatform.unsupported => null,
  };
}

class UpdateManifestException implements Exception {
  const UpdateManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OneSendUpdateAsset {
  const OneSendUpdateAsset({
    required this.url,
    required this.fileName,
    required this.sha256,
    required this.length,
  });

  factory OneSendUpdateAsset.fromJson(
    Map<String, Object?> json, {
    required String version,
    required String platform,
  }) {
    final urlText = json['url'];
    final fileNameValue = json['fileName'];
    final digestValue = json['sha256'];
    if (urlText is! String ||
        fileNameValue is! String ||
        digestValue is! String) {
      throw const UpdateManifestException('更新包信息格式无效。');
    }
    final url = Uri.tryParse(urlText);
    final fileName = fileNameValue;
    final digest = digestValue;
    final length = json['length'];
    final expectedPathPrefix =
        '/makerjackie/onesend/releases/download/v$version/';
    final expectedFileName = _expectedUpdateFileNames[platform];

    if (url == null ||
        url.scheme != 'https' ||
        url.host != 'github.com' ||
        url.userInfo.isNotEmpty ||
        url.hasPort ||
        url.hasQuery ||
        url.hasFragment) {
      throw const UpdateManifestException('更新包地址无效。');
    }
    if (expectedFileName == null ||
        fileName != expectedFileName ||
        url.path != '$expectedPathPrefix$fileName') {
      throw const UpdateManifestException('更新包文件名无效。');
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
      throw const UpdateManifestException('更新包校验值无效。');
    }
    if (length is! int || length <= 0 || length > _maxUpdateAssetBytes) {
      throw const UpdateManifestException('更新包长度无效。');
    }

    return OneSendUpdateAsset(
      url: url,
      fileName: fileName,
      sha256: digest,
      length: length,
    );
  }

  final Uri url;
  final String fileName;
  final String sha256;
  final int length;
}

class OneSendUpdateRelease {
  const OneSendUpdateRelease({
    required this.version,
    required this.buildNumber,
    required this.publishedAt,
    required this.releasePage,
    required this.notes,
    required this.assets,
  });

  factory OneSendUpdateRelease.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) {
      throw const UpdateManifestException('不支持的更新信息版本。');
    }

    final versionValue = json['version'];
    final buildNumber = json['buildNumber'];
    final publishedAtValue = json['publishedAt'];
    final releasePageValue = json['releasePage'];
    final notesJson = json['notes'];
    final assetsJson = json['assets'];

    if (versionValue is! String ||
        publishedAtValue is! String ||
        releasePageValue is! String) {
      throw const UpdateManifestException('更新信息字段格式无效。');
    }
    final version = versionValue;
    final publishedAt = DateTime.tryParse(publishedAtValue);
    final releasePage = Uri.tryParse(releasePageValue);
    if (!_versionPattern.hasMatch(version)) {
      throw const UpdateManifestException('更新版本号无效。');
    }
    if (buildNumber is! int || buildNumber <= 0) {
      throw const UpdateManifestException('更新构建号无效。');
    }
    if (publishedAt == null || !publishedAt.isUtc) {
      throw const UpdateManifestException('更新时间无效。');
    }
    if (releasePage == null ||
        releasePage.scheme != 'https' ||
        releasePage.host != 'github.com' ||
        releasePage.userInfo.isNotEmpty ||
        releasePage.hasPort ||
        releasePage.hasQuery ||
        releasePage.hasFragment ||
        releasePage.path != '/makerjackie/onesend/releases/tag/v$version') {
      throw const UpdateManifestException('更新说明地址无效。');
    }
    if (notesJson is! List ||
        notesJson.isEmpty ||
        notesJson.length > 12 ||
        notesJson.any((note) => !_isValidReleaseNote(note))) {
      throw const UpdateManifestException('更新说明无效。');
    }
    if (assetsJson is! Map || assetsJson.length != 3) {
      throw const UpdateManifestException('更新包列表无效。');
    }

    final assets = <String, OneSendUpdateAsset>{};
    for (final entry in assetsJson.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const UpdateManifestException('更新包列表无效。');
      }
      final platform = entry.key as String;
      if (!const {'macos', 'windows', 'linux'}.contains(platform)) {
        throw const UpdateManifestException('更新包列表无效。');
      }
      assets[platform] = OneSendUpdateAsset.fromJson(
        Map<String, Object?>.from(entry.value as Map),
        version: version,
        platform: platform,
      );
    }
    for (final platform in const ['macos', 'windows', 'linux']) {
      if (!assets.containsKey(platform)) {
        throw const UpdateManifestException('更新包列表不完整。');
      }
    }

    return OneSendUpdateRelease(
      version: version,
      buildNumber: buildNumber,
      publishedAt: publishedAt,
      releasePage: releasePage,
      notes: List<String>.unmodifiable(notesJson.cast<String>()),
      assets: Map<String, OneSendUpdateAsset>.unmodifiable(assets),
    );
  }

  final String version;
  final int buildNumber;
  final DateTime publishedAt;
  final Uri releasePage;
  final List<String> notes;
  final Map<String, OneSendUpdateAsset> assets;

  OneSendUpdateAsset assetFor(OneSendDesktopPlatform platform) {
    final name = platform.manifestName;
    final asset = name == null ? null : assets[name];
    if (asset == null) {
      throw const UpdateManifestException('当前平台没有可用的更新包。');
    }
    return asset;
  }

  bool isNewerThan(String currentVersion, int currentBuildNumber) {
    final comparison = compareOneSendVersions(version, currentVersion);
    return comparison > 0 ||
        (comparison == 0 && buildNumber > currentBuildNumber);
  }
}

Future<OneSendUpdateRelease> parseSignedUpdateManifest(
  Uint8List bytes, {
  String publicKey = oneSendUpdatePublicKey,
}) async {
  if (bytes.isEmpty || bytes.length > 256 * 1024) {
    throw const UpdateManifestException('更新信息大小无效。');
  }

  Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
  } on FormatException {
    throw const UpdateManifestException('更新信息不是有效的 JSON。');
  }
  if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
    throw const UpdateManifestException('更新信息格式无效。');
  }

  final envelope = Map<String, Object?>.from(decoded);
  if (envelope['schemaVersion'] != 1 || envelope['algorithm'] != 'ed25519') {
    throw const UpdateManifestException('不支持的更新签名格式。');
  }

  Uint8List payload;
  Uint8List signatureBytes;
  Uint8List publicKeyBytes;
  final payloadText = envelope['payload'];
  final signatureText = envelope['signature'];
  if (payloadText is! String || signatureText is! String) {
    throw const UpdateManifestException('更新签名字段格式无效。');
  }
  try {
    payload = base64Decode(payloadText);
    signatureBytes = base64Decode(signatureText);
    publicKeyBytes = base64Decode(publicKey);
  } on FormatException {
    throw const UpdateManifestException('更新签名编码无效。');
  }
  if (payload.isEmpty || payload.length > 192 * 1024) {
    throw const UpdateManifestException('更新签名载荷大小无效。');
  }
  if (signatureBytes.length != 64 || publicKeyBytes.length != 32) {
    throw const UpdateManifestException('更新签名长度无效。');
  }

  bool verified;
  try {
    verified = await Ed25519().verify(
      payload,
      signature: Signature(
        signatureBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      ),
    );
  } on Object {
    throw const UpdateManifestException('更新信息签名验证失败。');
  }
  if (!verified) {
    throw const UpdateManifestException('更新信息签名验证失败。');
  }

  Object? releaseJson;
  try {
    releaseJson = jsonDecode(utf8.decode(payload, allowMalformed: false));
  } on FormatException {
    throw const UpdateManifestException('更新签名载荷无效。');
  }
  if (releaseJson is! Map || releaseJson.keys.any((key) => key is! String)) {
    throw const UpdateManifestException('更新签名载荷格式无效。');
  }
  return OneSendUpdateRelease.fromJson(Map<String, Object?>.from(releaseJson));
}

int compareOneSendVersions(String left, String right) {
  final leftMatch = _versionPattern.firstMatch(left);
  final rightMatch = _versionPattern.firstMatch(right);
  if (leftMatch == null || rightMatch == null) {
    throw const UpdateManifestException('版本号格式无效。');
  }
  for (var index = 1; index <= 3; index++) {
    final difference =
        int.parse(leftMatch.group(index)!) -
        int.parse(rightMatch.group(index)!);
    if (difference != 0) return difference.sign;
  }
  return 0;
}

final RegExp _versionPattern = RegExp(r'^(\d{1,9})\.(\d{1,9})\.(\d{1,9})$');

const int _maxUpdateAssetBytes = 512 * 1024 * 1024;

const Map<String, String> _expectedUpdateFileNames = <String, String>{
  'macos': 'onesend-macos-universal.zip',
  'windows': 'onesend-windows-setup.exe',
  'linux': 'onesend-linux-x64.tar.gz',
};

bool _isValidReleaseNote(Object? value) {
  if (value is! String || value.trim().isEmpty || value.length > 240) {
    return false;
  }
  return !value.runes.any((rune) => rune < 0x20 || rune == 0x7f);
}
