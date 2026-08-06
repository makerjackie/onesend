const RECEIVER_MODES = new Set(["fast", "reliable", "turbo", "cimbar"]);

/** Keep receiver-launch links deterministic and free of file/session data. */
export function normalizeReceiverLaunchMode(mode) {
  return RECEIVER_MODES.has(mode) ? mode : "fast";
}

export function buildReceiverLaunchUrl(origin, mode = "fast") {
  const url = new URL("/receive", origin);
  url.searchParams.set("autostart", "1");
  url.searchParams.set("mode", normalizeReceiverLaunchMode(mode));
  return url.toString();
}

export function parseReceiverLaunch(search) {
  const params = new URLSearchParams(search);
  if (params.get("autostart") !== "1") return null;
  return {
    autoStart: true,
    mode: normalizeReceiverLaunchMode(params.get("mode")),
  };
}
