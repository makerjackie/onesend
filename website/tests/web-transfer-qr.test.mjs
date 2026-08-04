import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import * as ts from "typescript";
import QRCode from "qrcode";

import {
  OpticalSender,
  TRANSFER_MODES,
  encodeTransferFile,
} from "../app/web-transfer-protocol.mjs";

const webTransferSource = readFileSync(
  resolve(import.meta.dirname, "../app/web-transfer.tsx"),
  "utf8",
);

async function loadQrDisplayStrategy() {
  const start = webTransferSource.indexOf("export const QR_DISPLAY_POLICY");
  const end = webTransferSource.indexOf(
    "/**\n * Renders a OneSend QR",
    start,
  );
  assert.ok(start >= 0, "QR display policy must remain exported");
  assert.ok(end > start, "QR display strategy must remain isolated");

  // Keep the test on the production TSX function without importing the whole
  // client component (which also imports browser-only CSS/worker modules).
  const strategySource = webTransferSource.slice(start, end);
  const { outputText } = ts.transpileModule(strategySource, {
    compilerOptions: {
      module: ts.ModuleKind.ESNext,
      target: ts.ScriptTarget.ES2022,
    },
    fileName: "web-transfer-qr-strategy.ts",
  });
  return import(`data:text/javascript,${encodeURIComponent(outputText)}`);
}

function bytesOf(length, seed = 17) {
  return Uint8Array.from(
    { length },
    (_, index) => (index * 97 + seed * 13 + (index >> 3)) & 0xff,
  );
}

function fastFrame() {
  const payload = encodeTransferFile({
    name: "qr-regression.bin",
    mimeType: "application/octet-stream",
    bytes: bytesOf(2_200, 31),
  });
  return new OpticalSender(payload, "fast", 0x12345678).nextFrame().bytes;
}

test("fast V30 frame sizing keeps the desktop QR at three CSS px/module", async () => {
  const { QR_DISPLAY_POLICY, getQrDisplayMetrics } =
    await loadQrDisplayStrategy();
  const frame = fastFrame();
  const symbol = QRCode.create(
    [{ data: new Uint8ClampedArray(frame), mode: "byte" }],
    {
      errorCorrectionLevel: TRANSFER_MODES.fast.errorCorrectionLevel,
      maskPattern: frame.at(-4) & 7,
    },
  );
  const totalModules =
    symbol.modules.size + QR_DISPLAY_POLICY.quietZoneModules * 2;

  assert.equal(frame.length, 1_732);
  assert.equal(symbol.modules.size, 137, "Fast must stay a V30 symbol");
  assert.equal(totalModules, 145, "V30 plus the four-module quiet zone");

  const metrics = getQrDisplayMetrics(totalModules, {
    width: 1_440,
    height: 1_024,
  });
  assert.equal(metrics.modulePx, 3);
  assert.equal(metrics.pixelSize, 435);
  assert.ok(Number.isInteger(metrics.pixelSize));
  assert.ok(metrics.modulePx >= QR_DISPLAY_POLICY.minimumModulePx);
});

test("a tall desktop viewport prefers four CSS px/module", async () => {
  const { getQrDisplayMetrics } = await loadQrDisplayStrategy();
  const metrics = getQrDisplayMetrics(145, { width: 1_440, height: 1_440 });

  assert.equal(metrics.modulePx, 4);
  assert.equal(metrics.pixelSize, 580);
});

test("small screens keep dense QR modules at the three-pixel floor", async () => {
  const { QR_DISPLAY_POLICY, getQrDisplayMetrics } =
    await loadQrDisplayStrategy();
  const metrics = getQrDisplayMetrics(145, { width: 390, height: 844 });

  assert.equal(metrics.modulePx, 3);
  assert.equal(metrics.pixelSize, 435);
  assert.ok(metrics.modulePx >= QR_DISPLAY_POLICY.minimumModulePx);
  assert.ok(Number.isInteger(metrics.modulePx));
});

test("QR drawing keeps the quiet zone and defeats responsive CSS shrinking", () => {
  assert.match(
    webTransferSource,
    /const marginModules = QR_DISPLAY_POLICY\.quietZoneModules;/,
  );
  assert.match(
    webTransferSource,
    /\(column \+ marginModules\) \* modulePx/,
  );
  assert.match(
    webTransferSource,
    /canvas\.style\.setProperty\("width", `\$\{pixelSize\}px`, "important"\)/,
  );
  assert.match(
    webTransferSource,
    /canvas\.style\.setProperty\("max-width", "none", "important"\)/,
  );
  assert.match(webTransferSource, /context\.imageSmoothingEnabled = false;/);
  assert.doesNotMatch(webTransferSource, /Math\.min\(\s*360\s*,/);
});
