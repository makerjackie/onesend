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
  // Web transfer is two equal jobs (send + receive), not a single /send link.
  assert.match(page, /className="button button-primary" href="\/send"/);
  assert.match(page, /className="button button-primary" href="\/receive"/);
  assert.match(page, /下载 OneSend/);
  assert.match(page, /className="button button-secondary hero-download-cta" href="\/download"/);
  assert.match(page, /className="home-value"/);
  assert.match(page, /hero-scan-mark\.png/);
  assert.match(page, /home-hero-visual/);
  assert.doesNotMatch(page, /import \{ WebTransfer \}/);
  assert.doesNotMatch(page, /<WebTransfer/);
});

test("worker serves public static media from ASSETS", () => {
  assert.match(worker, /png\|jpe\?g\|gif\|webp/);
  assert.match(worker, /shouldServeFromAssets/);
  assert.match(worker, /shouldServeFromAssets\(url\.pathname\) && env\?\.ASSETS/);
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

test("web transfer keeps fast defaults, two primary modes, and completed-file actions", () => {
  assert.match(transfer, /useState<TransferModeChoice>\("fast"\)/);
  assert.match(transfer, /useRef<TransferModeChoice>\("fast"\)/);
  assert.match(transfer, /className="web-mode-switcher"/);
  assert.match(transfer, /className="web-mode-primary"/);
  assert.match(transfer, /copy\.qr/);
  assert.match(transfer, /copy\.qrAdvanced/);
  assert.match(transfer, /copy\.fast/);
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

test("sender can bootstrap a no-app web receiver in the matching mode", () => {
  assert.match(transfer, /buildReceiverLaunchUrl/);
  assert.match(transfer, /parseReceiverLaunch/);
  assert.match(transfer, /对方没有 App？/);
  assert.match(transfer, /先让对方打开接收页/);
  assert.match(transfer, /web-receiver-setup-dialog/);
  assert.match(transfer, /startCamera\(\{ automatic: true \}\)/);
  assert.match(transfer, /autoStartReceiver=\{autoStartCimbarReceiver\}/);
  assert.match(styles, /\.web-receiver-setup-backdrop/);
  assert.match(styles, /\.web-receiver-setup-dialog/);
});

test("web transfer allows live mode switches without pausing first", () => {
  // Must not hard-block mode changes while sending/paused.
  assert.doesNotMatch(
    transfer,
    /if \(senderState === "sending" \|\| senderState === "paused"\) return/,
  );
  // Live switch rebuilds the QR sender and can auto-resume.
  assert.match(transfer, /autoStart:\s*wasSending/);
  assert.match(transfer, /modeSwitchHint/);
  assert.match(transfer, /web-mode-hint/);
  assert.match(transfer, /flashModeNotice/);
  // Only preparing (file still loading) should lock mode buttons.
  assert.match(transfer, /const modeBusy = senderState === "preparing"/);
});

test("warm visual system and constrained mobile receive loop are present", () => {
  assert.match(styles, /--paper: #fbfaf4/);
  assert.match(styles, /--lime:/);
  assert.match(styles, /border-radius: 20px/);
  assert.match(styles, /\.web-code-stage \.web-code-canvas[\s\S]*?max-width: none !important/);
  assert.match(styles, /@media \(prefers-color-scheme: dark\)/);
  // /send and /receive: single-screen, no page scroll, footer hidden.
  assert.match(styles, /\.transfer-page \{[\s\S]*?height: 100svh[\s\S]*?overflow: hidden/);
  assert.match(styles, /\.transfer-page \.site-footer \{[\s\S]*?display: none/);
  assert.match(styles, /\.transfer-page-send \.web-workbench-send/);
  assert.match(styles, /\.transfer-page-receive \.web-workbench-receive \{[\s\S]*?grid-template-areas:[\s\S]*?"stage"[\s\S]*?"controls"/);
  assert.match(styles, /\.transfer-page-receive \.web-camera-stage-compact \{[\s\S]*?aspect-ratio: 1/);
  assert.match(transfer, /transfer-header-compact/);
  assert.doesNotMatch(transfer, /site-footer page-shell/);
});

test("worker serves hashed assets before the RSC handler when worker-first assets are enabled", () => {
  assert.match(worker, /run_worker_first/);
  assert.match(worker, /shouldServeFromAssets/);
  assert.match(worker, /pathname\.startsWith\("\/assets\/"\)/);
  // vinext dev: CSS + client components under /app/* must hit Vite, not RSC.
  assert.match(worker, /pathname\.startsWith\("\/app\/"\)/);
  assert.match(worker, /pathname\.startsWith\("\/@"\)/);
  assert.match(worker, /return env\.ASSETS\.fetch\(request\)/);
});
