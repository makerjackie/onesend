# OneSend website design QA

## Comparison input

- Source visual: `/Users/jackiexiao/.codex/generated_images/019fbbb5-686e-7891-8d97-cf2882cf8350/exec-4c831aac-13e6-4c91-ae9a-6abc15cd3a28.png`
- Source dimensions: 1487 × 1058 px
- Implementation screenshot: `/tmp/onesend-design-audit/08-final-send.jpg`
- Implementation viewport/screenshot: 1280 × 720 CSS px / 1265 × 712 px
- State: Chinese locale, web transfer anchored at the send workbench, built-in test video selected, default `自动 · 快速`, static bootstrap code visible
- Receive-state screenshot: `/tmp/onesend-design-audit/09-final-receive.jpg`
- Combined comparison: `/tmp/onesend-design-audit/design-comparison.png`

## QA history

1. **P1 — default path was not immediately testable.** The send panel initially required a manual file choice even though the product includes a sample video. Fixed by automatically loading `onesend-optical-test.mp4` and retaining the explicit “测试视频” action.
2. **P2 — role switching changed page position.** Switching between send and receive invoked `scrollIntoView`, which made the single-workbench flow feel unstable. Fixed by preserving the current scroll position.
3. **P2 — receive guidance was repetitive.** The camera instructions repeated the same sentence and implied that the user had to understand transport matching. Reduced to one direct instruction: “对准发送端的视觉码。”
4. **P2 — transfer controls were spread across too much vertical space.** Consolidated the mode selector, send/receive tabs, workbench, preview, progress, and status into a 664 px desktop workspace that fits within one viewport when entered through the Try action.
5. **P3 — the first implementation was visually softer than the selected target.** Removed rounded cards and shadows from the compact surface; aligned borders, typography, monochrome palette, and lime status accents with the selected 01MVP visual target.

## Final comparison findings

- **Typography:** Hierarchy matches the target: compact monospace labels, strong workbench headings, and restrained body copy. No cramped or truncated primary controls were found.
- **Spacing and layout:** The send and receive workbenches use a stable two-column desktop grid. The transfer area is 664 px high and remains within one viewport after the primary Try link anchors it to the top.
- **Viewport resilience:** Desktop was exercised at 1280 × 720. The implementation has explicit 840 px and 620 px breakpoints that collapse the workbench, preview, download strip, and actions into single-column/touch-friendly layouts without fixed-height clipping.
- **Colors and surfaces:** Black, white, paper gray, and lime consistently map to the selected visual. Borders are square and shadows are absent except for the open mode popover.
- **Assets:** The real bundled sample video and generated transfer code are used. No placeholder illustration, handcrafted SVG, or CSS-art substitute appears in the core flow.
- **Copy:** The primary route only explains what is needed to send or receive. Product background and technical details remain outside the core workbench.
- **States and interactions:** Send/receive tabs, four-mode selector, file picker, sample video, start/pause/cancel controls, camera opt-in, progress/status, and completed-file preview/actions are implemented. The browser runtime log was empty during the final send/receive pass.
- **Accessibility:** Tabs expose tab/tabpanel relationships and selected state; controls are semantic buttons/inputs; focus-visible uses a high-contrast lime outline; camera access is user initiated; reduced-motion rules are present.

No open P0, P1, or P2 findings remain.

## Final result

passed
