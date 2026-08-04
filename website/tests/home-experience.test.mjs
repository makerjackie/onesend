import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

const root = resolve(import.meta.dirname, "..");
const page = readFileSync(resolve(root, "app", "page.tsx"), "utf8");
const transfer = readFileSync(resolve(root, "app", "web-transfer.tsx"), "utf8");
const styles = readFileSync(resolve(root, "app", "globals.css"), "utf8");
const worker = readFileSync(resolve(root, "worker", "index.ts"), "utf8");

test("homepage keeps the transfer-first navigation and platform strip", () => {
  assert.match(page, /href="#web-transfer">网页试用/);
  assert.match(page, /href="#download">下载/);
  assert.match(page, /className="more-menu"/);
  assert.match(page, /href="\/how"/);
  assert.match(page, /href="\/privacy"/);
  assert.match(page, /download-strip/);
  assert.match(page, /更多平台/);
});

test("web transfer defaults to fast and exposes all modes in a compact settings control", () => {
  assert.match(transfer, /useState<TransferModeChoice>\("fast"\)/);
  assert.match(transfer, /useRef<TransferModeChoice>\("fast"\)/);
  assert.match(transfer, /className="web-mode-menu"/);
  assert.match(transfer, /copy\.autoFast/);
  assert.match(transfer, /copy\.reliable/);
  assert.match(transfer, /copy\.turbo/);
  assert.match(transfer, /copy\.color/);
  assert.match(transfer, /CimbarTransfer/);
  assert.doesNotMatch(transfer, /href="\/cimbar"/);
});

test("web transfer includes sample media, accessible role tabs, and completed-file actions", () => {
  assert.match(transfer, /SAMPLE_VIDEO_URL/);
  assert.match(transfer, /loadSampleVideo\(\{ automatic: true \}\)/);
  assert.match(transfer, /selectionVersionRef/);
  assert.match(transfer, /sampleAbortRef/);
  assert.match(transfer, /signal: controller\.signal/);
  assert.match(transfer, /role="tablist"/);
  assert.match(transfer, /aria-controls="web-transfer-send-panel"/);
  assert.match(transfer, /aria-controls="web-transfer-receive-panel"/);
  assert.match(transfer, /web-receipt/);
  assert.match(transfer, /openReceivedInNewTab/);
  assert.match(transfer, /triggerDownload/);
  assert.match(transfer, /web-receipt-preview/);
  assert.doesNotMatch(transfer, /copy\.switchAction/);
});

test("desktop transfer uses a bounded two-column viewport and mobile may stack", () => {
  assert.match(transfer, /className="web-workbench web-workbench-send"/);
  assert.match(transfer, /className="web-workbench web-workbench-receive"/);
  assert.match(styles, /\.site-compact \.site-header\.page-shell \{[\s\S]*?height: 64px/);
  assert.match(styles, /\.site-compact \.web-transfer-section \{[\s\S]*?height: min\(664px, calc\(100svh - 8px\)\)/);
  assert.match(styles, /\.site-compact \.web-workbench \{[\s\S]*?grid-template-columns: minmax\(0, 1fr\) minmax\(0, 1fr\)/);
  assert.match(styles, /@media \(max-width: 840px\)[\s\S]*?\.site-compact \.web-workbench \{[\s\S]*?grid-template-columns: 1fr/);
});

test("worker serves hashed assets before the RSC handler when worker-first assets are enabled", () => {
  assert.match(worker, /run_worker_first/);
  assert.match(worker, /pathname\.startsWith\("\/assets\/"\)/);
  assert.match(worker, /return env\.ASSETS\.fetch\(request\)/);
});
