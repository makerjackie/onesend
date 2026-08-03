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

test("cimbar copy and camera behavior stay local and opt-in", () => {
  const page = text(resolve(appRoot, "page.tsx"));
  const client = text(resolve(appRoot, "cimbar-client.tsx"));
  const senderWrapper = text(resolve(assetRoot, "cimbar-send-bootstrap.js"));
  const receiverWrapper = text(resolve(assetRoot, "cimbar-receive-worker.js"));

  assert.match(page, /彩色高速（实验）/);
  assert.match(page, /mode B/);
  assert.match(page, /106 KB\/s/);
  assert.doesNotMatch(page, /200\s*KB\/s/);
  assert.match(client, /发送/);
  assert.match(client, /接收/);
  assert.match(client, /getUserMedia/);
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

test("existing QR transfer exposes only the secondary cimbar entry", () => {
  const webTransfer = text(resolve(websiteRoot, "app", "web-transfer.tsx"));
  assert.match(webTransfer, /href="\/cimbar"/);
  assert.match(webTransfer, /试用彩色高速实验/);
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
