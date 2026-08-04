/// Release metadata shown in the user-facing About UI.
///
/// The values can be replaced at build time with:
///
/// ```text
/// --dart-define=ONESEND_VERSION=1.5.2
/// --dart-define=ONESEND_RELEASE_PUBLISHED_AT="2026-08-04 22:12"
/// ```
///
/// Build numbers are deliberately not part of this model or its display
/// formatter.
class OneSendReleaseInfo {
  const OneSendReleaseInfo({required this.version, required this.publishedAt});

  final String version;
  final String publishedAt;

  String get displayLabel =>
      formatOneSendReleaseLabel(version: version, publishedAt: publishedAt);
}

const String oneSendReleaseVersion = String.fromEnvironment(
  'ONESEND_VERSION',
  defaultValue: '1.5.2',
);

const String oneSendReleasePublishedAt = String.fromEnvironment(
  'ONESEND_RELEASE_PUBLISHED_AT',
  defaultValue: '2026-08-04 22:12',
);

const OneSendReleaseInfo oneSendReleaseInfo = OneSendReleaseInfo(
  version: oneSendReleaseVersion,
  publishedAt: oneSendReleasePublishedAt,
);

/// Formats a semantic version and release timestamp without exposing a build
/// number. A package version occasionally arrives with a `+build` suffix, so
/// the suffix is removed before it reaches the UI.
String formatOneSendReleaseLabel({
  required String version,
  required String publishedAt,
}) {
  final semanticVersion = _semanticVersion(version);
  return '$semanticVersion（$publishedAt）';
}

String _semanticVersion(String value) {
  final match = RegExp(
    r'\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?',
  ).firstMatch(value.trim());
  return match?.group(0) ?? value.trim();
}
