/// Release metadata shown in the user-facing About UI.
///
/// The values can be replaced at build time with:
///
/// ```text
/// --dart-define=ONESEND_VERSION=1.5.3
/// --dart-define=ONESEND_RELEASE_PUBLISHED_AT=202608042340
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
  defaultValue: '1.5.4',
);

const String oneSendReleasePublishedAt = String.fromEnvironment(
  'ONESEND_RELEASE_PUBLISHED_AT',
  defaultValue: '202608051240',
);

const OneSendReleaseInfo oneSendReleaseInfo = OneSendReleaseInfo(
  version: oneSendReleaseVersion,
  publishedAt: oneSendReleasePublishedAt,
);

/// Formats a semantic version and compact release timestamp without exposing
/// an internal build number. A package version occasionally arrives with a
/// `+build` suffix, so the suffix is removed before it reaches the UI.
String formatOneSendReleaseLabel({
  required String version,
  required String publishedAt,
}) {
  final semanticVersion = _semanticVersion(version);
  final timestamp = publishedAt.replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'^\d{12}$').hasMatch(timestamp)) {
    throw ArgumentError.value(
      publishedAt,
      'publishedAt',
      'must contain a yyyyMMddHHmm release timestamp',
    );
  }
  return '$semanticVersion（$timestamp）';
}

String _semanticVersion(String value) {
  final match = RegExp(
    r'\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?',
  ).firstMatch(value.trim());
  return match?.group(0) ?? value.trim();
}
