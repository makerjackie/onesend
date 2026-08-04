import assert from "node:assert/strict";
import test from "node:test";

// Mirror of CIMBAR_DISPLAY_POLICY + resolveCimbarCanvasSize in cimbar-client.tsx.
// Kept as a pure unit so sizing regressions fail without a React mount.

const CIMBAR_DISPLAY_POLICY = {
  desktopBreakpointPx: 840,
  desktopWidthRatio: 0.34,
  desktopHeightRatio: 0.44,
  mobileWidthRatio: 0.88,
  mobileHeightRatio: 0.4,
  maximumDisplayPx: 420,
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

test("cimbar canvas stays within the right-hand workbench budget", () => {
  const desktop = resolveCimbarCanvasSize({ width: 1280, height: 720 });
  assert.ok(desktop <= 420, `desktop size ${desktop} exceeds 420`);
  assert.ok(desktop >= 280, `desktop size ${desktop} below 280`);
  // Must be smaller than the old 560–900 full-bleed policy.
  assert.ok(desktop < 560);

  const laptop = resolveCimbarCanvasSize({ width: 1440, height: 900 });
  assert.ok(laptop <= 420);

  const phone = resolveCimbarCanvasSize({ width: 390, height: 844 });
  assert.ok(phone <= 420);
  assert.ok(phone >= 280);
});

test("cimbar display never targets a 1024 full-bleed square", () => {
  const huge = resolveCimbarCanvasSize({ width: 2560, height: 1440 });
  assert.equal(huge, 420);
  assert.notEqual(huge, 1024);
});
