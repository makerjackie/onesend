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
  assert.match(html, /OneSend · 扫传/);
  assert.match(html, /文件，/);
  assert.match(html, /用光传过去/);
  assert.match(html, /OneSend · 快速模式/);
  assert.match(html, /默认快，需要时更稳。/);
  assert.match(html, /快速模式默认开启；环境不佳时，在设置中切换到兼容可靠模式。/);
  assert.match(html, /快速模式/);
  assert.match(html, /≈33 KB\/s/);
  assert.match(html, /默认快速模式/);
  assert.match(html, /≈4\.7 KB\/s/);
  assert.match(html, /兼容可靠模式/);
  assert.match(html, /约 33 KB\/s/);
  assert.match(html, /可靠模式/);
  assert.match(html, /适用环境/);
  assert.match(html, /手持 · 普通屏幕/);
  assert.match(html, /固定 · 清晰屏幕/);
  assert.match(html, /默认设置/);
  assert.match(html, /新传输自动使用/);
  assert.match(html, /切换位置/);
  assert.match(html, /设置/);
  assert.doesNotMatch(html, /fps/i);
  assert.match(html, /onesend-android\.apk/);
  assert.match(html, /onesend-macos-universal\.dmg/);
  assert.match(html, /onesend-windows-setup\.exe/);
  assert.match(html, /onesend-linux-x64\.tar\.gz/);
  assert.match(html, /网页，也能扫传/);
  assert.match(html, /选择一个本地文件/);
  assert.match(html, /开启摄像头/);
  assert.match(html, /仅本地 \/ 不上传/);
  assert.match(html, /WEB ↔ WEB \/ FLUTTER V2/);
  assert.match(html, /id="web-transfer"/);
  assert.match(html, /github\.com\/makerjackie\/onesend\/releases\/latest/);
  assert.match(html, /testflight\.apple\.com\/join\/n2t1KrCp/);
  assert.match(html, /桌面自动更新/);
  assert.match(html, /Ed25519/);
  assert.match(html, /\/privacy/);
  assert.doesNotMatch(html, /codex-preview|loading skeleton|Starter Project/i);
});

test("bundles the original silent demo asset", async () => {
  const demo = new URL("../public/onesend-optical-test.mp4", import.meta.url);
  const details = await stat(demo);
  assert.ok(details.size > 20_000);
  assert.ok(details.size < 40_000);
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
