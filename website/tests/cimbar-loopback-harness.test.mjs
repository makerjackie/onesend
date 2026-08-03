import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

const harnessPath = resolve(
  import.meta.dirname,
  "..",
  "public",
  "cimbar",
  "harness",
  "loopback.html",
);

test("browser harness performs a camera-free libcimbar RGBA loopback", () => {
  const harness = readFileSync(harnessPath, "utf8");

  assert.match(harness, /crypto\.getRandomValues\(new Uint8Array\(2048\)\)/);
  assert.match(harness, /cimbar-send-bootstrap\.js/);
  assert.match(harness, /cimbar-receive-worker\.js/);
  assert.match(harness, /getImageData/);
  assert.match(harness, /format: "RGBA"/);
  assert.match(harness, /candidates === 1 \|\| candidates % 5 === 0/);
  assert.match(harness, /byte mismatch at/);
  assert.match(harness, /SHA-256 mismatch/);
  assert.match(harness, /RGBA pixels, no camera/);
  assert.doesNotMatch(harness, /getUserMedia|mediaDevices|optical-speed benchmark result/i);
});
