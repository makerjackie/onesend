import assert from "node:assert/strict";
import test from "node:test";

import {
  buildReceiverLaunchUrl,
  normalizeReceiverLaunchMode,
  parseReceiverLaunch,
} from "../app/receiver-launch.mjs";

test("receiver launch URL opens the matching web mode without file data", () => {
  const result = new URL(
    buildReceiverLaunchUrl("https://onesend.01mvp.com/send", "cimbar"),
  );

  assert.equal(result.origin, "https://onesend.01mvp.com");
  assert.equal(result.pathname, "/receive");
  assert.equal(result.searchParams.get("autostart"), "1");
  assert.equal(result.searchParams.get("mode"), "cimbar");
  assert.deepEqual([...result.searchParams.keys()].sort(), ["autostart", "mode"]);
});

test("receiver launch parser defaults invalid modes to fast", () => {
  assert.equal(normalizeReceiverLaunchMode("turbo"), "turbo");
  assert.equal(normalizeReceiverLaunchMode("unknown"), "fast");
  assert.deepEqual(parseReceiverLaunch("?autostart=1&mode=unknown"), {
    autoStart: true,
    mode: "fast",
  });
  assert.equal(parseReceiverLaunch("?mode=fast"), null);
});
