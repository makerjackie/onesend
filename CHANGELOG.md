# Changelog

## 1.2.1 - 2026-08-03

- Fixed file selection failing with `Invalid argument: object is unsendable` on
  macOS and other native platforms.
- Moved send and receive file-envelope work behind explicit, sendable isolate
  messages so UI state and plugin objects cannot cross the worker boundary.
- Added isolate round-trip and real file-picker UI regression coverage for text,
  arbitrary binary data, compression, and Unicode file metadata.

## 1.2.0 - 2026-08-02

- Increased Fast mode from 1320 B at 15 fps to a fixed V30-L profile carrying
  1700 B at 24 fps, for about 32 KB/s theoretical useful throughput.
- Synchronized optical playback to display vsync and replaced per-frame QR mask
  searches with deterministic standards-compliant masks.
- Added a rateless LT schedule for Fast mode, cutting recovery overhead under
  frame loss while retaining bounded-memory scheduling for large files.
- Preserved receive compatibility with the OneSend 1.1 Fast profile.
- Processed every QR detected in a mobile camera exposure and added pacing,
  capacity, compatibility, and 30% frame-loss regression tests.

## 1.1.2 - 2026-08-02

- Updated the Chinese product name to “扫传” across the app, website, release
  metadata, and TestFlight materials.

## 1.1.1 - 2026-08-01

- Replaced the Flutter placeholder icon with the original OneSend optical-data mark on iOS, Android, macOS, Windows, and the product website.

## 1.1.0 - 2026-08-01

- Added Reliable and Fast optical transfer profiles.
- Added protocol v2 with 32-bit sessions and block counts plus per-frame CRC32.
- Interleaved systematic source frames with deterministic LT repair frames.
- Added gzip file envelopes with original and stored-data integrity checks.
- Added randomized loss, corruption, duplicate, reorder, and late-join tests.
- Replaced desktop photo polling with in-memory camera-frame decoding.
- Added bounded decompression and decoder memory limits for malformed inputs.
- Added a packaged-app native QR encode/decode self-test.
- Kept protocol v1 receive compatibility.
- Added local file opening from completion and transfer history screens.
- Added persistent Android release signing and release checksum generation.
- Added Developer ID signing, notarized universal macOS ZIP/DMG packaging, and a product site.

## 1.0.0 - 2026-08-01

- Initial OneSend release.
- Animated QR file sending and continuous camera receiving.
- Pause, resume, restart, integrity verification and local transfer history.
