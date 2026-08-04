import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

const websiteRoot = resolve(import.meta.dirname, "..");
const appRoot = resolve(websiteRoot, "app");

const sourcePaths = {
  brand: resolve(appRoot, "brand.tsx"),
  home: resolve(appRoot, "page.tsx"),
  how: resolve(appRoot, "how", "page.tsx"),
  privacy: resolve(appRoot, "privacy", "page.tsx"),
  layout: resolve(appRoot, "layout.tsx"),
  favicon: resolve(websiteRoot, "public", "favicon.svg"),
  styles: resolve(appRoot, "globals.css"),
};

const source = Object.fromEntries(
  Object.entries(sourcePaths).map(([name, path]) => [name, readFileSync(path, "utf8")]),
);
const legacyBrandClass = ["brand", "mark"].join("-");

test("all public pages and footers use the shared Brand component", () => {
  assert.match(source.brand, /export function Brand\(/);
  assert.match(source.home, /import \{ Brand \} from "\.\/brand"/);
  assert.match(source.how, /import \{ Brand \} from "\.\.\/brand"/);
  assert.match(source.privacy, /import \{ Brand \} from "\.\.\/brand"/);

  assert.equal((source.home.match(/<Brand\b/g) ?? []).length, 2);
  assert.equal((source.how.match(/<Brand\b/g) ?? []).length, 2);
  assert.equal((source.privacy.match(/<Brand\b/g) ?? []).length, 1);
});

test("brand source uses the icon asset and contains no text-1 logo", () => {
  assert.match(source.brand, /src="\/icon\.png"/);

  const appSource = [
    source.brand,
    source.home,
    source.how,
    source.privacy,
    source.layout,
    source.styles,
  ].join("\n");
  assert.doesNotMatch(appSource, new RegExp(legacyBrandClass));
  assert.doesNotMatch(
    appSource,
    new RegExp(`<span[^>]*className=["']${legacyBrandClass}["'][^>]*>\\s*1\\s*<\\/`),
  );

  assert.match(source.layout, /icon:\s*["']\/icon\.png["']/);
  assert.match(source.layout, /shortcut:\s*["']\/icon\.png["']/);
  assert.match(source.layout, /apple:\s*["']\/icon\.png["']/);
  assert.match(source.layout, /url:\s*["']\/og\.png["']/);
  assert.match(source.layout, /images:\s*\[\s*["']\/og\.png["']\]/);
});

test("favicon references the generated PNG without drawing a second mark", () => {
  assert.match(source.favicon, /<image\b[^>]*href="\/icon\.png"/);
  assert.doesNotMatch(source.favicon, /<(?:path|rect|polygon|circle|g)\b/);
});

async function render(pathname) {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}-${pathname}`);
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

test("server-rendered page brands contain a real accessible icon image", async () => {
  for (const pathname of ["/", "/how", "/privacy"]) {
    const response = await render(pathname);
    assert.equal(response.status, 200, pathname);

    const html = await response.text();
    const brands = html.match(/<a\b[^>]*class="brand"[^>]*>[\s\S]*?<\/a>/g) ?? [];
    assert.ok(brands.length > 0, `${pathname} should render a brand link`);

    for (const brand of brands) {
      assert.match(brand, /aria-label="[^"]+"/);
      assert.match(brand, /<img\b[^>]*src="\/icon\.png"/);
      assert.match(brand, /alt=""/);
      assert.match(brand, /aria-hidden="true"/);
      assert.doesNotMatch(brand, new RegExp(`${legacyBrandClass}|>\\s*1\\s*<`));
    }
  }
});
