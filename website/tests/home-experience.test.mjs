import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

const root = resolve(import.meta.dirname, "..");
const page = readFileSync(resolve(root, "app", "page.tsx"), "utf8");
const transfer = readFileSync(resolve(root, "app", "web-transfer.tsx"), "utf8");
const styles = readFileSync(resolve(root, "app", "globals.css"), "utf8");
const sendRoute = readFileSync(resolve(root, "app", "send", "page.tsx"), "utf8");
const receiveRoute = readFileSync(
  resolve(root, "app", "receive", "page.tsx"),
  "utf8",
);
const downloadRoute = readFileSync(
  resolve(root, "app", "download", "page.tsx"),
  "utf8",
);
const worker = readFileSync(resolve(root, "worker", "index.ts"), "utf8");

test("homepage is intentionally a sparse entry point", () => {
  assert.match(page, /href="\/send"/);
  assert.match(page, /网页传输/);
  assert.match(page, /href="\/receive"/);
  assert.match(page, /接收文件/);
  assert.match(page, /href="\/download">/);
  assert.match(page, /className="home-value"/);
  assert.doesNotMatch(page, /import \{ WebTransfer \}/);
  assert.doesNotMatch(page, /<WebTransfer/);
});

test("legacy hash links route to the standalone surfaces", () => {
  assert.match(page, /#web-transfer-send/);
  assert.match(page, /#web-transfer-receive/);
  assert.match(page, /window\.location\.replace\(route\)/);
  assert.match(page, /return "\/send"/);
  assert.match(page, /return "\/receive"/);
  assert.match(page, /return "\/download"/);
});

test("standalone routes reuse one locked WebTransfer component", () => {
  assert.match(sendRoute, /StandaloneTransferPage/);
  assert.match(receiveRoute, /StandaloneTransferPage/);
  assert.match(downloadRoute, /platforms/);
  assert.match(transfer, /initialRole\?: TransferRole/);
  assert.match(transfer, /lockedRole\?: TransferRole/);
  assert.match(transfer, /const roleIsLocked = lockedRole !== undefined/);
  assert.match(transfer, /role=\{roleIsLocked \? undefined : "tabpanel"\}/);
  assert.match(transfer, /!roleIsLocked &&/);
});

test("web transfer keeps fast defaults, all modes, and completed-file actions", () => {
  assert.match(transfer, /useState<TransferModeChoice>\("fast"\)/);
  assert.match(transfer, /useRef<TransferModeChoice>\("fast"\)/);
  assert.match(transfer, /className="web-mode-menu"/);
  assert.match(transfer, /copy\.autoFast/);
  assert.match(transfer, /copy\.reliable/);
  assert.match(transfer, /copy\.turbo/);
  assert.match(transfer, /copy\.color/);
  assert.match(transfer, /CimbarTransfer/);
  assert.match(transfer, /SAMPLE_VIDEO_URL/);
  assert.match(transfer, /selectionVersionRef/);
  assert.match(transfer, /openReceivedInNewTab/);
  assert.match(transfer, /triggerDownload/);
  assert.match(transfer, /receiverPaused/);
  assert.doesNotMatch(transfer, /href="\/cimbar"/);
});

test("warm visual system and constrained mobile receive loop are present", () => {
  assert.match(styles, /--paper: #fbfaf4/);
  assert.match(styles, /--lime:/);
  assert.match(styles, /border-radius: 20px/);
  assert.match(styles, /\.web-code-stage \.web-code-canvas[\s\S]*?max-width: none !important/);
  assert.match(styles, /@media \(prefers-color-scheme: dark\)/);
  assert.match(styles, /\.transfer-page-receive \{[\s\S]*?height: 100svh[\s\S]*?overflow: hidden/);
  assert.match(styles, /\.transfer-page-receive \.web-transfer-section \{[\s\S]*?height: calc\(100svh - 64px\)/);
  assert.match(styles, /\.transfer-page-receive \.web-workbench-receive \{[\s\S]*?grid-template-areas:[\s\S]*?"stage"[\s\S]*?"controls"/);
  assert.match(styles, /\.transfer-page-receive \.web-workbench-receive \.web-camera-stage-compact \{[\s\S]*?aspect-ratio: 1/);
});

test("worker serves hashed assets before the RSC handler when worker-first assets are enabled", () => {
  assert.match(worker, /run_worker_first/);
  assert.match(worker, /pathname\.startsWith\("\/assets\/"\)/);
  assert.match(worker, /return env\.ASSETS\.fetch\(request\)/);
});
