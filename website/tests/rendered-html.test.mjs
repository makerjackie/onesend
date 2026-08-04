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
  assert.match(html, /网页试用/);
  assert.match(html, /下载 App/);
  assert.match(html, /网页传输/);
  assert.match(html, /开始发送/);
  assert.match(html, /自动 · 快速/);
  assert.match(html, /测试视频/);
  assert.match(html, /预览/);
  assert.match(html, /打开 \/ 新标签/);
  assert.match(html, /保存/);
  assert.match(html, /id="web-transfer"/);
  assert.match(html, /id="download"/);
  assert.match(html, /href="\/how"/);
  assert.match(html, /href="\/privacy"/);
  assert.match(html, /class="more-menu"/);
  assert.match(html, /onesend-android\.apk/);
  assert.match(html, /onesend-macos-universal\.dmg/);
  assert.match(html, /testflight\.apple\.com\/join\/n2t1KrCp/);
  assert.doesNotMatch(html, /漏帧，不等于失败/);
  assert.doesNotMatch(html, /默认快，需要时更稳/);
  assert.doesNotMatch(html, /web-role-picker/);
  assert.doesNotMatch(html, /codex-preview|loading skeleton|Starter Project/i);
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
