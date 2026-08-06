import assert from "node:assert/strict";
import { access, readFile, stat } from "node:fs/promises";
import test from "node:test";

const projectRoot = new URL("../", import.meta.url);

async function render(pathname = "/") {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request(`http://localhost${pathname}`, {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

test("server-renders the OneSend product page", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /OneSend/);
  assert.match(html, /文件，/);
  assert.match(html, /用光传过去/);
  assert.match(html, /下载 OneSend/);
  assert.match(html, /hero-scan-mark\.png/);
  assert.match(html, /href="\/download"/);
  assert.match(html, /href="\/send"/);
  assert.match(html, /href="\/receive"/);
  // Peer web jobs: send + receive both appear as primary buttons.
  assert.match(html, /class="button button-primary" href="\/send"/);
  assert.match(html, /class="button button-primary" href="\/receive"/);
  assert.doesNotMatch(html, /id="web-transfer"/);
  assert.doesNotMatch(html, /开始发送/);
  assert.doesNotMatch(html, /自动 · 快速/);
  assert.match(html, /href="\/how"/);
  assert.match(html, /href="\/privacy"/);
  assert.match(html, /class="more-menu"/);
  assert.doesNotMatch(html, /漏帧，不等于失败/);
  assert.doesNotMatch(html, /默认快，需要时更稳/);
  assert.doesNotMatch(html, /codex-preview|loading skeleton|Starter Project/i);
});

test("server-renders independent send and receive surfaces without role tabs", async () => {
  const [sendResponse, receiveResponse] = await Promise.all([
    render("/send"),
    render("/receive"),
  ]);
  assert.equal(sendResponse.status, 200);
  assert.equal(receiveResponse.status, 200);

  const [sendHtml, receiveHtml] = await Promise.all([
    sendResponse.text(),
    receiveResponse.text(),
  ]);
  assert.match(sendHtml, /发送文件/);
  assert.match(sendHtml, /data-transfer-role="send"/);
  assert.match(sendHtml, /开始发送/);
  assert.match(sendHtml, /对方没有 App/);
  assert.doesNotMatch(sendHtml, /role="tablist"/);
  assert.match(receiveHtml, /接收文件/);
  assert.match(receiveHtml, /data-transfer-role="receive"/);
  assert.match(receiveHtml, /开启摄像头/);
  assert.doesNotMatch(receiveHtml, /role="tablist"/);
});

test("server-renders the standalone download page", async () => {
  const response = await render("/download");
  assert.equal(response.status, 200);
  const html = await response.text();
  assert.match(html, /把 OneSend 带到每台设备/);
  assert.match(html, /onesend-android\.apk/);
  assert.match(html, /onesend-macos-universal\.dmg/);
  assert.match(html, /testflight\.apple\.com\/join\/n2t1KrCp/);
  assert.doesNotMatch(html, /id="web-transfer"/);
});

test("bundles the shared built-in optical test video", async () => {
  const demo = new URL("../public/onesend-optical-test.mp4", import.meta.url);
  const details = await stat(demo);
  // Keep the fixture small enough for quick end-to-end optical tests.
  assert.equal(details.size, 125_415);
});

test("server-renders the standalone privacy notice", async () => {
  const response = await render("/privacy");
  assert.equal(response.status, 200);

  const html = await response.text();
  assert.match(html, /隐私说明/);
  assert.match(html, /我们不收集的数据/);
  assert.match(html, /安全边界/);
  assert.match(html, /2026 年 8 月 1 日/);
});

test("removes all starter preview artifacts and metadata", async () => {
  const [page, layout, packageJson] = await Promise.all([
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/layout.tsx", import.meta.url), "utf8"),
    readFile(new URL("../package.json", import.meta.url), "utf8"),
  ]);

  assert.doesNotMatch(page, /_sites-preview|SkeletonPreview|codex-preview/);
  assert.doesNotMatch(layout, /Starter Project|codex-preview/);
  assert.doesNotMatch(packageJson, /react-loading-skeleton/);
  await assert.rejects(access(new URL("app/_sites-preview", projectRoot)));
});
