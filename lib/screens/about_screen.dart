import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../core/release_info.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/brand_mark.dart';

const String oneSendGithubUrl = 'https://github.com/makerjackie/onesend';
const String oneSendGithubNewIssueUrl =
    'https://github.com/makerjackie/onesend/issues/new';
const String oneSendPrivacyUrl = 'https://onesend.01mvp.com/privacy';

final Uri oneSendGithubUri = Uri.parse(oneSendGithubUrl);
final Uri oneSendGithubNewIssueUri = Uri.parse(oneSendGithubNewIssueUrl);
final Uri oneSendPrivacyUri = Uri.parse(oneSendPrivacyUrl);

/// Open-source projects historically referenced by OneSend (see README /
/// THIRD_PARTY_NOTICES).
const List<({String title, String url})> oneSendOpenSourceCredits =
    <({String title, String url})>[
      (
        title: 'decimen-optical-transfer',
        url: 'https://github.com/bashalarmistalt/decimen-optical-transfer',
      ),
      (
        title: 'qr-data-transfer',
        url: 'https://github.com/deedy/qr-data-transfer',
      ),
      (title: 'libcimbar', url: 'https://github.com/sz3/libcimbar'),
    ];

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
  bool _openingUrl = false;

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

  Future<void> _openUri(Uri uri, {required String failureMessage}) async {
    if (_openingUrl) return;
    setState(() {
      _openingUrl = true;
      _message = null;
    });
    try {
      final launcher = widget.urlLauncher;
      final opened = launcher == null
          ? await launchUrl(uri, mode: LaunchMode.externalApplication)
          : await launcher(uri);
      if (!opened) throw StateError('url');
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = failureMessage);
    }
    if (!mounted) return;
    setState(() => _openingUrl = false);
  }

  Future<void> _openGithub() async {
    await _openUri(
      oneSendGithubUri,
      failureMessage: AppLocalizations.of(context)!.cannotOpenGithub,
    );
  }

  Future<void> _openFeedback() async {
    await _openUri(
      oneSendGithubNewIssueUri,
      failureMessage: AppLocalizations.of(context)!.cannotOpenGithubIssues,
    );
  }

  Future<void> _openPrivacy() async {
    await _openUri(
      oneSendPrivacyUri,
      failureMessage: AppLocalizations.of(context)!.cannotOpenPrivacy,
    );
  }

  Future<void> _openCredit(String url) async {
    await _openUri(
      Uri.parse(url),
      failureMessage: AppLocalizations.of(context)!.cannotOpenGithub,
    );
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
    final creditBodies = <String>[
      l10n.creditDecimen,
      l10n.creditQrDataTransfer,
      l10n.creditLibcimbar,
    ];
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
                  _AboutPanel(
                    title: l10n.privacy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.privacyBody,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey<String>('about-privacy'),
                          onPressed: _openingUrl ? null : _openPrivacy,
                          icon: const Icon(Icons.policy_outlined, size: 18),
                          label: Text(l10n.openPrivacyPolicy),
                        ),
                      ],
                    ),
                  ),
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
                    title: l10n.acknowledgments,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.acknowledgmentsIntro,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < creditBodies.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _CreditRow(
                            body: creditBodies[i],
                            onOpen: _openingUrl
                                ? null
                                : () => unawaited(
                                    _openCredit(
                                      oneSendOpenSourceCredits[i].url,
                                    ),
                                  ),
                          ),
                        ],
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
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              key: const ValueKey<String>('about-github'),
                              onPressed: _openingUrl ? null : _openGithub,
                              icon: _openingUrl
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                _openingUrl ? l10n.opening : l10n.openGithub,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              key: const ValueKey<String>('about-feedback'),
                              onPressed: _openingUrl ? null : _openFeedback,
                              icon: const Icon(
                                Icons.bug_report_outlined,
                                size: 18,
                              ),
                              label: Text(l10n.sendFeedback),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.sendFeedbackSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
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

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.body, required this.onOpen});

  final String body;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.favorite_outline_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (onOpen != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ],
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
