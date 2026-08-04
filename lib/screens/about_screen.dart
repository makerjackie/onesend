import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../core/release_info.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/brand_mark.dart';

const String oneSendGithubUrl = 'https://github.com/makerjackie/onesend';
final Uri oneSendGithubUri = Uri.parse(oneSendGithubUrl);

typedef AboutPackageInfoLoader = Future<PackageInfo> Function();
typedef AboutUrlLauncher = Future<bool> Function(Uri url);

/// About page entered from Settings.
class AboutScreen extends StatefulWidget {
  const AboutScreen({
    this.packageInfoLoader,
    this.urlLauncher,
    this.releaseInfo = oneSendReleaseInfo,
    super.key,
  });

  final AboutPackageInfoLoader? packageInfoLoader;
  final AboutUrlLauncher? urlLauncher;
  final OneSendReleaseInfo releaseInfo;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;
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
      // The compile-time release metadata is enough to render the page.
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

  String _versionLabel() {
    final packageVersion = _packageInfo?.version;
    return formatOneSendReleaseLabel(
      version: packageVersion ?? widget.releaseInfo.version,
      publishedAt: widget.releaseInfo.publishedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutHeader(version: _versionLabel(), l10n: l10n),
                  const SizedBox(height: 20),
                  Text(
                    l10n.experimentalVisualTransfer,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AboutPanel(
                    title: l10n.github,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          oneSendGithubUrl,
                          style: Theme.of(context).textTheme.bodyMedium,
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
                      style: Theme.of(context).textTheme.bodySmall,
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
    final scheme = Theme.of(context).colorScheme;
    final brandTagline = _brandTagline(l10n);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandIcon(size: 56, borderRadius: 14),
          const SizedBox(height: 16),
          Text(
            oneSendBrandName,
            style: TextStyle(
              color: scheme.surface,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          if (brandTagline != null) ...[
            const SizedBox(height: 2),
            Text(
              brandTagline,
              style: TextStyle(
                color: scheme.surface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            version,
            style: TextStyle(color: scheme.surface.withValues(alpha: 0.76)),
          ),
        ],
      ),
    );
  }
}

String? _brandTagline(AppLocalizations l10n) {
  const separator = ' · ';
  final separatorIndex = l10n.appTitle.indexOf(separator);
  if (separatorIndex == -1) return null;
  return l10n.appTitle.substring(separatorIndex + separator.length);
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(oneSendRadiusCard),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (body != null)
            Text(body!, style: Theme.of(context).textTheme.bodyMedium)
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
          width: 64,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
