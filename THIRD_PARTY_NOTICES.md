# Third-party notices

## decimen-optical-transfer

OneSend's original protocol-v1 compatibility work and LT-code foundation were
informed by
[`bashalarmistalt/decimen-optical-transfer`](https://github.com/bashalarmistalt/decimen-optical-transfer),
which is available under the MIT License:

```text
MIT License

Copyright (c) 2026 BashAlarmist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

OneSend also evaluated the public architecture of
[`deedy/qr-data-transfer`](https://github.com/deedy/qr-data-transfer). That
repository did not declare a license when OneSend v1.1 was developed, so no
source code or assets from it are included here.

## Desktop update frameworks

The macOS app embeds
[`Sparkle 2.9.5`](https://github.com/sparkle-project/Sparkle/tree/2.9.5), and the
Windows app embeds
[`WinSparkle 0.9.4`](https://github.com/vslavik/winsparkle/tree/v0.9.4). Both
are used only to check, authenticate, download, and install OneSend desktop
releases. Their complete bundled notices are preserved in:

- [`licenses/Sparkle-LICENSE.txt`](licenses/Sparkle-LICENSE.txt)
- [`licenses/WinSparkle-COPYING.txt`](licenses/WinSparkle-COPYING.txt)
- [`licenses/WinSparkle-COPYING.expat.txt`](licenses/WinSparkle-COPYING.expat.txt)

Dependency licenses remain with their respective copyright holders. Flutter
and Dart dependency manifests in this repository identify the exact versions
used by each release.

## libcimbar v0.6.7c (cimbar color high-speed experiment)

The `/cimbar` website and Flutter mobile experiment include the unmodified
Emscripten release assets from the `sz3/libcimbar` v0.6.7c GitHub release.
That release tag resolves to commit
`e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44`:

- Project: [`sz3/libcimbar`](https://github.com/sz3/libcimbar)
- Release: [`v0.6.7c`](https://github.com/sz3/libcimbar/releases/tag/v0.6.7c)
- Tagged source commit: [`e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44`](https://github.com/sz3/libcimbar/tree/e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44)
- License: Mozilla Public License 2.0 (MPL-2.0)
- Full license text: [`licenses/libcimbar-MPL-2.0.txt`](licenses/libcimbar-MPL-2.0.txt)
- Corresponding source offer: the exact upstream source tree is available at
  the commit link above; the mobile release assets are kept under
  `assets/cimbar/upstream/` and the website copy under `website/public/cimbar/`.

The copied `cimbar_js.2026-07-13T0523.js`,
`cimbar_js.2026-07-13T0523.wasm`, `send.2026-07-13T0523.js`, and
`send-worker.2026-07-13T0523.js` files, along with the receiver worker and
zstd/receiver scripts in `assets/cimbar/upstream/`, are distributed without
source changes.
The OneSend bootstrap and receiver wrapper are separate OneSend files; they
only call the upstream public worker/WASM interface. The upstream release
service workers are intentionally not copied or registered, so they cannot
control or purge caches belonging to the OneSend site.

OneSend's website, wrapper code, and existing QR transfer remain under the
OneSend MIT License. The libcimbar MPL-2.0 notice and source obligations apply
only to the libcimbar covered assets and are not relicensed as OneSend MIT.
