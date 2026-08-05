# OneSend release rules

## User-visible version labels

- Every user-visible release label must use `SEMVER（yyyyMMddHHmm）`, for example
  `1.5.4（202608051240）`.
- The timestamp is Asia/Shanghai release time, contains digits only, and is
  frozen when the release build is prepared.
- Never expose an internal sequential build number such as `23` in the UI,
  release footer, About page, update screen, screenshots, or release copy.
- Pass the same timestamp with `ONESEND_RELEASE_PUBLISHED_AT` for release
  builds and update `oneSendReleasePublishedAt` as the checked-in fallback.
- iOS release archives should use the compact timestamp as `CFBundleVersion`
  when uploading to App Store Connect. Android may retain a monotonic internal
  `versionCode` because it is range-limited, but that value must not be shown to
  users.
- Tests must reject regressions that display `SEMVER (BUILD_NUMBER)`.

## Release safety

- Keep the semantic version aligned across source, App Store metadata, GitHub
  Release, website update metadata, and user-facing copy.
- Do not change the timestamp or replace artifact bytes after a release is
  public. Publish a newer build or patch version instead.
