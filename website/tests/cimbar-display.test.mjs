import assert from "node:assert/strict";
import test from "node:test";

// Mirror of CIMBAR_DISPLAY_POLICY + resolveCimbarCanvasSize in cimbar-client.tsx.
// Kept as a pure unit so sizing regressions fail without a React mount.

const CIMBAR_DISPLAY_POLICY = {
  desktopBreakpointPx: 840,
  desktopWidthRatio: 0.42,
  desktopHeightRatio: 0.62,
  mobileWidthRatio: 0.88,
  mobileHeightRatio: 0.4,
  maximumDisplayPx: 560,
  minimumDisplayPx: 280,
  fallbackDisplayPx: 360,
};

function resolveCimbarCanvasSize(viewport) {
  const width = Math.max(1, Math.floor(viewport.width));
  const height = Math.max(1, Math.floor(viewport.height));
  const isDesktop = width >= CIMBAR_DISPLAY_POLICY.desktopBreakpointPx;
  const widthBudget = Math.floor(
    width *
      (isDesktop
        ? CIMBAR_DISPLAY_POLICY.desktopWidthRatio
        : CIMBAR_DISPLAY_POLICY.mobileWidthRatio),
  );
  const heightBudget = Math.floor(
    height *
      (isDesktop
        ? CIMBAR_DISPLAY_POLICY.desktopHeightRatio
        : CIMBAR_DISPLAY_POLICY.mobileHeightRatio),
  );
  const fit = Math.min(
    CIMBAR_DISPLAY_POLICY.maximumDisplayPx,
    widthBudget,
    heightBudget,
  );
  return Math.max(
    CIMBAR_DISPLAY_POLICY.minimumDisplayPx,
    Math.floor(fit) || CIMBAR_DISPLAY_POLICY.fallbackDisplayPx,
  );
}

test("cimbar display uses the available workbench without overflowing", () => {
  const desktop = resolveCimbarCanvasSize({ width: 1280, height: 720 });
  assert.ok(desktop <= 560, `desktop size ${desktop} exceeds 560`);
  assert.ok(desktop >= 280, `desktop size ${desktop} below 280`);
  assert.equal(desktop, 446);

  const laptop = resolveCimbarCanvasSize({ width: 1440, height: 900 });
  assert.equal(laptop, 558);

  const phone = resolveCimbarCanvasSize({ width: 390, height: 844 });
  assert.ok(phone <= 560);
  assert.ok(phone >= 280);
});

test("cimbar CSS display stays capped while the bitmap remains 1024", () => {
  const huge = resolveCimbarCanvasSize({ width: 2560, height: 1440 });
  assert.equal(huge, 560);
  assert.notEqual(huge, 1024);
});
