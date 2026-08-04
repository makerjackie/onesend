# OneSend 1.5.1 brand design QA

- Canonical source: `assets/brand/onesend-transfer-mark.svg`
- Compared the pre-change production capture, local implementation capture, and canonical icon at the same 1265 × 712 browser viewport.
- Website header/footer now use the official black-and-white optical transfer mark; no textual `1` logo remains.
- Android, iOS, macOS, Windows, Linux, Flutter in-app surfaces, favicon, social preview, and website icon are generated from or reference the canonical source.
- Header geometry, typography, transfer controls, and compact single-page layout remain visually intact.
- `tool/generate_icons.sh --check` prevents checked-in platform assets from drifting.

final result: passed
