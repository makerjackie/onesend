# OneSend 1.5.2 design QA

final result: passed

## Visual sources

- Selected transfer-home concept: `exec-59e6b3b5-6f03-46e4-9bf1-2daa7ec120be.png`
- Selected receive concept: `exec-9754288b-90ee-42b0-ac6e-cfd98171c8bc.png`
- Canonical product mark: `assets/brand/onesend-file-scan-mark.png`

The selected concepts and 390 × 844 Flutter captures were reviewed side by side in a single comparison image for each screen. The website was inspected at 390 × 844 and 1440 × 1024 in the in-app browser.

## Verification

- P0: none. Send and receive are separate routes/screens; primary actions are reachable and the camera/scan state remains visible.
- P1: none. The mobile website home and receive route both measure exactly one 390 × 844 viewport with no page scroll. Flutter receive layout tests cover 360 × 800 and 390 × 844 without overflow.
- P2: resolved. Increased the scanner radius, removed the idle indeterminate progress animation, corrected dark-theme readout colors, reduced mobile-home vertical padding, and unified the generated logo across web and native launchers.
- Hierarchy: one dominant send action, one secondary receive action, settings moved to bottom navigation, and secondary explanations moved out of the main transfer path.
- Brand: the file-in-scanner mark is shared by Flutter, website, Android, iOS, macOS, Windows, and Linux assets.
- Accessibility: controls retain semantic labels, keyboard focus treatment, localized diagnostics, and sufficient light/dark contrast.

## Accepted implementation differences

The production Flutter home uses a more compact card height than the concept so the complete three-tab shell remains usable on 360 × 800 devices. The receive screen gives more height to the live camera than the concept, matching the reliability-first requirement.
