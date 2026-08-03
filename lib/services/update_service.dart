import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:onesend_macos_updater/onesend_macos_updater.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/update_manifest.dart';

const _updateManifestUrl = 'https://onesend.01mvp.com/updates/latest.json';
const _lastLinuxCheckKey = 'desktop_update_last_check';
const _linuxAutomaticChecksKey = 'desktop_update_automatic_checks';
const _automaticCheckInterval = Duration(hours: 24);

enum UpdateCheckOutcome {
  nativeWindowOpened,
  updateAvailable,
  upToDate,
  unsupported,
}

abstract class UpdateManager extends ChangeNotifier {
  /// Initializes platform-specific update services, if any.
  ///
  /// Mobile managers intentionally keep the default no-op implementation so
  /// startup cannot touch update preferences or create network clients.
  Future<void> initialize() async {}

  bool get supportsUpdates;
  String get currentVersionLabel;
  bool get automaticChecksEnabled;
  bool get checking;
  bool get downloading;
  double? get downloadProgress;
  String? get lastError;
  OneSendUpdateRelease? get availableRelease;

  Future<UpdateCheckOutcome> checkForUpdates({bool userInitiated = true});
  Future<void> performStartupCheck();
  Future<void> setAutomaticChecksEnabled(bool enabled);
  Future<void> downloadAvailableUpdate();
  Future<void> openReleasePage();
}

class DisabledUpdateManager extends UpdateManager {
  DisabledUpdateManager._();

  static final DisabledUpdateManager instance = DisabledUpdateManager._();

  @override
  bool get automaticChecksEnabled => false;

  @override
  OneSendUpdateRelease? get availableRelease => null;

  @override
  bool get checking => false;

  @override
  String get currentVersionLabel => '—';

  @override
  double? get downloadProgress => null;

  @override
  bool get downloading => false;

  @override
  String? get lastError => null;

  @override
  bool get supportsUpdates => false;

  @override
  Future<UpdateCheckOutcome> checkForUpdates({
    bool userInitiated = true,
  }) async => UpdateCheckOutcome.unsupported;

  @override
  Future<void> downloadAvailableUpdate() async {}

  @override
  Future<void> openReleasePage() async {}

  @override
  Future<void> performStartupCheck() async {}

  @override
  Future<void> setAutomaticChecksEnabled(bool enabled) async {}
}

abstract interface class NativeUpdateBridge {
  Future<void> checkForUpdates();
  Future<bool> getAutomaticChecksEnabled();
  Future<void> setAutomaticChecksEnabled(bool enabled);
}

typedef UpdateManifestParser =
    Future<OneSendUpdateRelease> Function(Uint8List bytes);

/// Maps a Flutter target platform to the desktop updater platform.
///
/// This is deliberately pure: callers and tests supply both inputs instead of
/// relying on `dart:io` platform globals. Mobile and unsupported targets do not
/// have a desktop updater platform.
OneSendDesktopPlatform desktopUpdatePlatformForTarget(
  TargetPlatform targetPlatform, {
  bool isWeb = false,
}) {
  if (isWeb) return OneSendDesktopPlatform.unsupported;
  return switch (targetPlatform) {
    TargetPlatform.macOS => OneSendDesktopPlatform.macos,
    TargetPlatform.windows => OneSendDesktopPlatform.windows,
    TargetPlatform.linux => OneSendDesktopPlatform.linux,
    _ => OneSendDesktopPlatform.unsupported,
  };
}

/// Creates the only updater that should be used by the application entrypoint.
///
/// Android, iOS, web, and other unsupported targets receive the disabled
/// manager, so they never construct the desktop HTTP updater. The optional
/// arguments make the platform decision directly unit-testable while the
/// defaults preserve normal Flutter runtime detection.
UpdateManager createUpdateManager({
  TargetPlatform? targetPlatform,
  bool? isWeb,
}) {
  final desktopPlatform = desktopUpdatePlatformForTarget(
    targetPlatform ?? defaultTargetPlatform,
    isWeb: isWeb ?? kIsWeb,
  );
  if (desktopPlatform == OneSendDesktopPlatform.unsupported) {
    return DisabledUpdateManager.instance;
  }
  return DesktopUpdateManager(platform: desktopPlatform);
}

class MethodChannelNativeUpdateBridge implements NativeUpdateBridge {
  const MethodChannelNativeUpdateBridge();

  static const MethodChannel _channel = MethodChannel(
    oneSendDesktopUpdaterChannel,
  );

  @override
  Future<void> checkForUpdates() =>
      _channel.invokeMethod<void>('checkForUpdates');

  @override
  Future<bool> getAutomaticChecksEnabled() async =>
      await _channel.invokeMethod<bool>('getAutomaticChecksEnabled') ?? true;

  @override
  Future<void> setAutomaticChecksEnabled(bool enabled) => _channel
      .invokeMethod<void>('setAutomaticChecksEnabled', {'enabled': enabled});
}

class DesktopUpdateManager extends UpdateManager {
  DesktopUpdateManager({
    OneSendDesktopPlatform? platform,
    http.Client? client,
    NativeUpdateBridge? nativeBridge,
    Future<PackageInfo> Function()? packageInfoLoader,
    Future<Directory?> Function()? downloadsDirectoryLoader,
    Future<bool> Function(String path)? fileOpener,
    Future<bool> Function(Uri url)? externalUrlLauncher,
    UpdateManifestParser? manifestParser,
    DateTime Function()? clock,
  }) : _platform =
           platform ??
           desktopUpdatePlatformForTarget(defaultTargetPlatform, isWeb: kIsWeb),
       _client = client ?? http.Client(),
       _ownsClient = client == null,
       _nativeBridge = nativeBridge ?? const MethodChannelNativeUpdateBridge(),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
       _downloadsDirectoryLoader =
           downloadsDirectoryLoader ?? getDownloadsDirectory,
       _fileOpener = fileOpener ?? _openFile,
       _externalUrlLauncher = externalUrlLauncher ?? _launchExternalUrl,
       _manifestParser = manifestParser ?? parseSignedUpdateManifest,
       _clock = clock ?? DateTime.now;

  final OneSendDesktopPlatform _platform;
  final http.Client _client;
  final bool _ownsClient;
  final NativeUpdateBridge _nativeBridge;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final Future<Directory?> Function() _downloadsDirectoryLoader;
  final Future<bool> Function(String path) _fileOpener;
  final Future<bool> Function(Uri url) _externalUrlLauncher;
  final UpdateManifestParser _manifestParser;
  final DateTime Function() _clock;

  PackageInfo? _packageInfo;
  SharedPreferences? _preferences;
  bool _automaticChecksEnabled = true;
  bool _checking = false;
  bool _downloading = false;
  double? _downloadProgress;
  String? _lastError;
  OneSendUpdateRelease? _availableRelease;

  @override
  Future<void> initialize() async {
    _packageInfo = await _packageInfoLoader();
    _preferences = await SharedPreferences.getInstance();

    if (_platform == OneSendDesktopPlatform.macos ||
        _platform == OneSendDesktopPlatform.windows) {
      try {
        _automaticChecksEnabled = await _nativeBridge
            .getAutomaticChecksEnabled();
      } on Object {
        // A broken updater preference must not prevent file transfer or later
        // manual checks from initializing.
        _automaticChecksEnabled = true;
      }
    } else if (_platform == OneSendDesktopPlatform.linux) {
      _automaticChecksEnabled =
          _preferences?.getBool(_linuxAutomaticChecksKey) ?? true;
    }
    notifyListeners();
  }

  @override
  bool get supportsUpdates => _platform != OneSendDesktopPlatform.unsupported;

  @override
  String get currentVersionLabel {
    final info = _packageInfo;
    if (info == null) return '读取中';
    return '${info.version} (${info.buildNumber})';
  }

  @override
  bool get automaticChecksEnabled => _automaticChecksEnabled;

  @override
  bool get checking => _checking;

  @override
  bool get downloading => _downloading;

  @override
  double? get downloadProgress => _downloadProgress;

  @override
  String? get lastError => _lastError;

  @override
  OneSendUpdateRelease? get availableRelease => _availableRelease;

  @override
  Future<UpdateCheckOutcome> checkForUpdates({
    bool userInitiated = true,
  }) async {
    if (!supportsUpdates) return UpdateCheckOutcome.unsupported;
    if (_checking) {
      throw StateError('更新检查正在进行。');
    }

    _checking = true;
    _lastError = null;
    notifyListeners();
    try {
      if (_platform == OneSendDesktopPlatform.macos ||
          _platform == OneSendDesktopPlatform.windows) {
        await _nativeBridge.checkForUpdates();
        return UpdateCheckOutcome.nativeWindowOpened;
      }

      final response = await _client
          .get(
            Uri.parse(_updateManifestUrl),
            headers: const {
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.cacheControlHeader: 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('更新服务器返回 ${response.statusCode}。');
      }
      final release = await _manifestParser(response.bodyBytes);
      final info = _packageInfo ?? await _packageInfoLoader();
      final buildNumber = int.tryParse(info.buildNumber) ?? 0;

      _preferences ??= await SharedPreferences.getInstance();
      await _preferences?.setString(
        _lastLinuxCheckKey,
        _clock().toUtc().toIso8601String(),
      );

      if (release.isNewerThan(info.version, buildNumber)) {
        _availableRelease = release;
        return UpdateCheckOutcome.updateAvailable;
      }
      _availableRelease = null;
      return UpdateCheckOutcome.upToDate;
    } catch (error) {
      _lastError = _friendlyError(error);
      rethrow;
    } finally {
      _checking = false;
      notifyListeners();
    }
  }

  @override
  Future<void> performStartupCheck() async {
    if (!supportsUpdates || !_automaticChecksEnabled) return;
    if (_platform != OneSendDesktopPlatform.linux) {
      // Sparkle and WinSparkle own their persisted scheduler and startup check.
      return;
    }

    _preferences ??= await SharedPreferences.getInstance();
    final lastCheckText = _preferences?.getString(_lastLinuxCheckKey);
    final lastCheck = lastCheckText == null
        ? null
        : DateTime.tryParse(lastCheckText)?.toUtc();
    if (lastCheck != null &&
        _clock().toUtc().difference(lastCheck) < _automaticCheckInterval) {
      return;
    }

    try {
      await checkForUpdates(userInitiated: false);
    } catch (_) {
      // Startup checks stay quiet. A manual check will surface the same error.
    }
  }

  @override
  Future<void> setAutomaticChecksEnabled(bool enabled) async {
    if (!supportsUpdates) return;
    _lastError = null;
    try {
      if (_platform == OneSendDesktopPlatform.macos ||
          _platform == OneSendDesktopPlatform.windows) {
        await _nativeBridge.setAutomaticChecksEnabled(enabled);
      } else {
        _preferences ??= await SharedPreferences.getInstance();
        await _preferences?.setBool(_linuxAutomaticChecksKey, enabled);
      }
      _automaticChecksEnabled = enabled;
      notifyListeners();
    } catch (error) {
      _lastError = _friendlyError(error);
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> downloadAvailableUpdate() async {
    if (_platform != OneSendDesktopPlatform.linux) {
      await _nativeBridge.checkForUpdates();
      return;
    }
    final release = _availableRelease;
    if (release == null) throw StateError('没有可下载的更新。');
    if (_downloading) throw StateError('更新包正在下载。');

    _downloading = true;
    _downloadProgress = 0;
    _lastError = null;
    notifyListeners();

    File? partialFile;
    try {
      final asset = release.assetFor(_platform);
      final downloads =
          await _downloadsDirectoryLoader() ?? await getTemporaryDirectory();
      await downloads.create(recursive: true);
      final finalPath = _availableDownloadPath(downloads, asset.fileName);
      partialFile = File('$finalPath.part');

      final request = http.Request('GET', asset.url)
        ..headers[HttpHeaders.acceptHeader] = 'application/octet-stream';
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('更新包服务器返回 ${response.statusCode}。');
      }
      if (response.contentLength != null &&
          response.contentLength != asset.length) {
        throw const UpdateManifestException('更新包长度与发布信息不一致。');
      }

      final sink = partialFile.openWrite();
      var received = 0;
      var lastReportedPercent = -1;
      try {
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 30),
        )) {
          received += chunk.length;
          if (received > asset.length) {
            throw const UpdateManifestException('更新包超过发布信息中的长度。');
          }
          sink.add(chunk);
          final percent = (received * 100 / asset.length).floor();
          if (percent != lastReportedPercent) {
            lastReportedPercent = percent;
            _downloadProgress = received / asset.length;
            notifyListeners();
          }
        }
      } finally {
        await sink.close();
      }

      if (received != asset.length) {
        throw const UpdateManifestException('更新包下载不完整。');
      }
      final digest = await sha256.bind(partialFile.openRead()).first;
      if (digest.toString() != asset.sha256) {
        throw const UpdateManifestException('更新包 SHA-256 校验失败。');
      }

      final completedFile = await partialFile.rename(finalPath);
      partialFile = null;
      _downloadProgress = 1;
      notifyListeners();

      if (!await _fileOpener(completedFile.path)) {
        if (!await _externalUrlLauncher(release.releasePage)) {
          throw StateError('更新包已下载，但系统无法打开它或下载页面。');
        }
      }
    } catch (error) {
      if (partialFile != null && await partialFile.exists()) {
        await partialFile.delete();
      }
      _lastError = _friendlyError(error);
      rethrow;
    } finally {
      _downloading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> openReleasePage() async {
    final url =
        _availableRelease?.releasePage ??
        Uri.parse('https://github.com/makerjackie/onesend/releases/latest');
    _lastError = null;
    try {
      if (!await _externalUrlLauncher(url)) {
        throw StateError('无法打开下载页面。');
      }
    } catch (error) {
      _lastError = _friendlyError(error);
      notifyListeners();
      rethrow;
    }
  }

  String _availableDownloadPath(Directory directory, String fileName) {
    final requested = path.join(directory.path, fileName);
    if (!File(requested).existsSync()) return requested;
    final extension = path.extension(fileName);
    final stem = path.basenameWithoutExtension(fileName);
    final timestamp = _clock().millisecondsSinceEpoch;
    var attempt = 1;
    while (true) {
      final suffix = attempt == 1 ? '$timestamp' : '$timestamp-$attempt';
      final candidate = path.join(directory.path, '$stem-$suffix$extension');
      if (!File(candidate).existsSync()) return candidate;
      attempt++;
    }
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
    super.dispose();
  }
}

Future<bool> _openFile(String filePath) async {
  final result = await OpenFilex.open(filePath);
  return result.type == ResultType.done;
}

Future<bool> _launchExternalUrl(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

String _friendlyError(Object error) {
  if (error is UpdateManifestException) return error.message;
  if (error is TimeoutException) return '连接更新服务器超时。';
  if (error is SocketException) return '无法连接更新服务器。';
  if (error is HttpException) return error.message;
  if (error is PlatformException) return error.message ?? '系统更新服务暂时不可用。';
  if (error is StateError) return error.message;
  return '检查更新失败，请稍后重试。';
}
