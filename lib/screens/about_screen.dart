import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';

const Color _aboutInk = Color(0xff10130f);
const Color _aboutPaper = Color(0xfff5f6f0);
const Color _aboutPanel = Color(0xffffffff);
const Color _aboutMuted = Color(0xff667066);
const BorderRadius _aboutRadius = BorderRadius.all(Radius.circular(6));

const String oneSendGithubUrl = 'https://github.com/makerjackie/onesend';
final Uri oneSendGithubUri = Uri.parse(oneSendGithubUrl);

typedef AboutPackageInfoLoader = Future<PackageInfo> Function();
typedef AboutUrlLauncher = Future<bool> Function(Uri url);

/// About page with injectable platform seams for version loading and links.
///
/// The page owns neither the package info object nor navigation state, so it
/// can be pushed directly from HomeScreen or embedded in a later settings
/// route without introducing a second app-level dependency.
class AboutScreen extends StatefulWidget {
  const AboutScreen({this.packageInfoLoader, this.urlLauncher, super.key});

  final AboutPackageInfoLoader? packageInfoLoader;
  final AboutUrlLauncher? urlLauncher;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
  String? _versionError;
  String? _message;
  bool _openingGithub = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final loader = widget.packageInfoLoader ?? PackageInfo.fromPlatform;
    try {
      final info = await loader();
      if (!mounted) return;
      setState(() => _packageInfo = info);
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionError = 'unavailable');
    }
  }

  Future<void> _openGithub() async {
    if (_openingGithub) return;
    setState(() {
      _openingGithub = true;
      _message = null;
    });
    try {
      final launcher = widget.urlLauncher;
      final opened = launcher == null
          ? await launchUrl(
              oneSendGithubUri,
              mode: LaunchMode.externalApplication,
            )
          : await launcher(oneSendGithubUri);
      if (!opened) throw StateError('github');
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = AppLocalizations.of(context)!.cannotOpenGithub);
    }
    if (!mounted) return;
    setState(() => _openingGithub = false);
  }

  String _versionLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = _packageInfo;
    if (info != null) {
      return '${info.version} (${info.buildNumber})';
    }
    return _versionError == null
        ? l10n.readingVersion
        : l10n.versionUnavailable;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _aboutPaper,
      appBar: AppBar(
        title: Text(l10n.about),
        backgroundColor: _aboutPaper,
        foregroundColor: _aboutInk,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutHeader(version: _versionLabel(context), l10n: l10n),
                  const SizedBox(height: 18),
                  Text(
                    l10n.experimentalVisualTransfer,
                    style: TextStyle(
                      color: _aboutInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AboutPanel(
                    title: l10n.workingPrinciple,
                    body: l10n.workingPrincipleBody,
                  ),
                  const SizedBox(height: 12),
                  _AboutPanel(
                    title: l10n.whyWeBuiltIt,
                    body: l10n.whyWeBuiltItBody,
                  ),
                  const SizedBox(height: 12),
                  _AboutPanel(title: l10n.privacy, body: l10n.privacyBody),
                  const SizedBox(height: 12),
                  _AboutPanel(
                    title: l10n.openSourceAndAuthor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AboutInfoLine(
                          label: l10n.author,
                          value: 'MakerJackie / 01MVP',
                        ),
                        const SizedBox(height: 9),
                        _AboutInfoLine(label: l10n.license, value: 'MIT'),
                        const SizedBox(height: 9),
                        _AboutInfoLine(
                          label: l10n.version,
                          value: _versionLabel(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AboutPanel(
                    title: l10n.github,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SelectableText(
                          oneSendGithubUrl,
                          style: TextStyle(color: _aboutMuted, height: 1.45),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          key: const ValueKey<String>('about-github'),
                          onPressed: _openingGithub ? null : _openGithub,
                          icon: _openingGithub
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(
                            _openingGithub ? l10n.opening : l10n.openGithub,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _aboutInk,
                            side: const BorderSide(color: _aboutInk, width: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _message!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      l10n.aboutFooter,
                      style: const TextStyle(color: _aboutMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader({required this.version, required this.l10n});

  final String version;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: _aboutInk,
        border: Border.fromBorderSide(BorderSide(color: _aboutInk, width: 2)),
        borderRadius: _aboutRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/brand/onesend-icon-1024.png',
              width: 56,
              height: 56,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'OneSend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '扫传',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.versionLabel(version),
            style: const TextStyle(color: Color(0xffdfe5dc), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.title, this.body, this.child});

  final String title;
  final String? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    assert(body != null || child != null);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _aboutPanel,
        border: Border.fromBorderSide(BorderSide(color: _aboutInk, width: 2)),
        borderRadius: _aboutRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _aboutInk,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (body != null)
            Text(
              body!,
              style: const TextStyle(color: _aboutMuted, height: 1.55),
            )
          else
            child!,
        ],
      ),
    );
  }
}

class _AboutInfoLine extends StatelessWidget {
  const _AboutInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: _aboutMuted, height: 1.4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _aboutInk,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
