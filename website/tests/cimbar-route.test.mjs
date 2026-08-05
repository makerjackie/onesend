import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

const websiteRoot = resolve(import.meta.dirname, "..");
const appRoot = resolve(websiteRoot, "app", "cimbar");
const assetRoot = resolve(websiteRoot, "public", "cimbar", "node_modules");

function text(path) {
  return readFileSync(path, "utf8");
}

function sha256(path) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

test("cimbar route and local release assets are present", () => {
  assert.ok(existsSync(resolve(appRoot, "page.tsx")));
  assert.ok(existsSync(resolve(appRoot, "cimbar-client.tsx")));
  assert.ok(existsSync(resolve(appRoot, "cimbar.module.css")));

  const wasm = resolve(assetRoot, "cimbar_js.2026-07-13T0523.wasm");
  assert.ok(existsSync(wasm));
  assert.deepEqual([...readFileSync(wasm).subarray(0, 4)], [0, 97, 115, 109]);
  assert.equal(
    sha256(resolve(assetRoot, "cimbar_js.2026-07-13T0523.js")),
    "cc14cec5d982107b5bcdf02cdd254a8c01496c9b8833f02684c7ed8b90ba1d09",
  );
  assert.equal(
    sha256(wasm),
    "4b10483127d403ea3873ee751454afdc5d42eb5818f8b02e4c2ed0d49e2072ec",
  );
  assert.ok(existsSync(resolve(assetRoot, "send.2026-07-13T0523.js")));
  assert.ok(existsSync(resolve(assetRoot, "send-worker.2026-07-13T0523.js")));
  assert.ok(existsSync(resolve(assetRoot, "cimbar-send-bootstrap.js")));
  assert.ok(existsSync(resolve(assetRoot, "cimbar-receive-worker.js")));
  assert.equal(existsSync(resolve(assetRoot, "sw.js")), false);
  assert.equal(existsSync(resolve(assetRoot, "recv-sw.js")), false);
});

test("worker deployment keeps dynamic routes and static assets available", () => {
  const viteConfig = text(resolve(websiteRoot, "vite.config.ts"));
  assert.match(viteConfig, /assets:\s*\{/);
  assert.match(viteConfig, /binding:\s*"ASSETS"/);
  assert.match(viteConfig, /run_worker_first:\s*true/);

  // With run_worker_first, vinext only signals public/ files to ASSETS.
  // Hashed Vite bundles under /assets/* must be proxied by the Worker.
  const worker = text(resolve(websiteRoot, "worker", "index.ts"));
  assert.match(worker, /pathname\.startsWith\("\/assets\/"\)/);
  assert.match(worker, /env\.ASSETS\.fetch\(request\)/);
});

test("desktop update feeds target the current release", () => {
  const updatesRoot = resolve(websiteRoot, "public", "updates");
  const appcast = text(resolve(updatesRoot, "appcast.xml"));
  const latest = JSON.parse(text(resolve(updatesRoot, "latest.json")));
  const payload = JSON.parse(Buffer.from(latest.payload, "base64").toString("utf8"));

  assert.match(appcast, /<sparkle:shortVersionString>1\.5\.4<\/sparkle:shortVersionString>/);
  assert.match(appcast, /<sparkle:version>23<\/sparkle:version>/);
  assert.match(appcast, /releases\/download\/v1\.5\.4\/onesend-macos-universal\.zip/);
  assert.equal(payload.version, "1.5.4");
  assert.equal(payload.buildNumber, 23);
  assert.equal(payload.assets.macos.sha256, "d1a0bc0bbceabf0af396c47d3667855221ccb122dfbf04918a1c231ab3c59214");
  assert.equal(payload.assets.windows.sha256, "1855972e35f3fae73f0e8d6ac576e2c0f5589ba4ceb5ae972da1e7dcb6fdafba");
  assert.equal(payload.assets.linux.sha256, "671511ebef0a0d615f27b6e55219f6c4ce92bc1bbba300f3881c1e62a4af5a6a");
});

test("cimbar copy and camera behavior stay local and opt-in", () => {
  const page = text(resolve(appRoot, "page.tsx"));
  const client = text(resolve(appRoot, "cimbar-client.tsx"));
  const webTransfer = text(resolve(websiteRoot, "app", "web-transfer.tsx"));
  const senderWrapper = text(resolve(assetRoot, "cimbar-send-bootstrap.js"));
  const receiverWrapper = text(resolve(assetRoot, "cimbar-receive-worker.js"));

  // Old /cimbar bookmarks redirect into the main web-transfer mode switcher.
  assert.match(page, /redirect\("\/#web-transfer"\)/);
  assert.match(webTransfer, /彩色（实验）/);
  assert.match(client, /选择文件/);
  assert.match(client, /测试视频/);
  assert.match(client, /开始发送/);
  assert.match(client, /扫码连接/);
  assert.match(client, /web-workbench/);
  assert.match(client, /getUserMedia/);
  // Peak experimental profile for high-end phones (Mode B + 15 fps).
  assert.match(client, /const CIMBAR_MODE = 68/);
  assert.match(client, /const CIMBAR_DISPLAY_FPS = 15/);
  assert.match(client, /CIMBAR_THEORETICAL_KBPS/);
  assert.match(client, /理论峰值/);
  assert.match(client, /实测/);
  assert.match(client, /explainReceiveGap/);
  assert.match(client, /ideal: 1920/);
  // Visible size fits the workbench; the backing bitmap remains crisp.
  assert.match(client, /CIMBAR_DISPLAY_POLICY/);
  assert.match(client, /maximumDisplayPx: 560/);
  assert.match(client, /const CIMBAR_RENDER_SIZE = 1024/);
  assert.match(client, /sizeCimbarCanvas/);
  assert.match(senderWrapper, /callback === self\.Send\.nextFrame/);
  assert.match(senderWrapper, /opticalFrameTimer !== null/);
  assert.match(senderWrapper, /generation !== loadGeneration/);
  assert.match(senderWrapper, /frameCount \+= 1[\s\S]*postFrameIfNeeded\(\)/);
  assert.ok(client.indexOf("async function startReceiver") < client.indexOf("getUserMedia"));
  assert.doesNotMatch(`${page}\n${client}\n${senderWrapper}\n${receiverWrapper}`, /serviceWorker\.register/);
  assert.doesNotMatch(`${senderWrapper}\n${receiverWrapper}`, /https?:\/\//);
  assert.match(senderWrapper, /send-worker\.2026-07-13T0523\.js/);
  assert.match(receiverWrapper, /cimbar_js\.2026-07-13T0523\.js/);
});

test("cimbar view switches release the inactive transfer mode", () => {
  const client = text(resolve(appRoot, "cimbar-client.tsx"));
  const changeView = client.match(
    /function changeView\(nextView: View\) \{[\s\S]*?\n  \}/,
  )?.[0];

  assert.ok(changeView);
  assert.match(changeView, /nextView === "send"[\s\S]*stopReceiverResources\(\)/);
  assert.match(changeView, /nextView === "receive"[\s\S]*stopSender\(\)/);
});

test("web transfer switches cimbar inline with QR modes", () => {
  const webTransfer = text(resolve(websiteRoot, "app", "web-transfer.tsx"));
  assert.match(webTransfer, /CimbarTransfer/);
  assert.match(webTransfer, /"cimbar"/);
  assert.match(webTransfer, /copy\.color/);
  assert.doesNotMatch(webTransfer, /href="\/cimbar"/);
  assert.doesNotMatch(webTransfer, /试用彩色高速实验/);
});

test("MPL-2.0 notice and full license are included", () => {
  const notices = text(resolve(websiteRoot, "..", "THIRD_PARTY_NOTICES.md"));
  const license = text(resolve(websiteRoot, "..", "licenses", "libcimbar-MPL-2.0.txt"));
  assert.match(notices, /libcimbar v0\.6\.7c/);
  assert.match(notices, /e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44/);
  assert.match(notices, /OneSend MIT/);
  assert.match(notices, /MPL-2\.0/);
  assert.match(license, /Mozilla Public License Version 2\.0/);
  assert.match(license, /3\.2\. Distribution of Executable Form/);
});
