import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import assert from "node:assert/strict";

import {
  OpticalReceiver,
  OpticalSender,
  TRANSFER_MODES,
  crc32,
  encodeTransferFile,
  parseFrame,
} from "../website/app/web-transfer-protocol.mjs";

const repositoryRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const outputPath = resolve(
  repositoryRoot,
  "test/fixtures/optical_interop/js_to_dart.json",
);

function bytesOf(length, seed) {
  return Uint8Array.from(
    { length },
    (_, index) => (index * 97 + seed * 13 + (index >> 3)) & 0xff,
  );
}

function base64(bytes) {
  return Buffer.from(bytes).toString("base64");
}

function frameChecksum(bytes) {
  return new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)
    .getUint32(bytes.length - 4, true);
}

function makeCase({ modeName, sessionId, envelope }) {
  const sender = new OpticalSender(envelope, modeName, sessionId);
  const receiver = new OpticalReceiver();
  const frames = [];
  let completion = null;

  for (let index = 0; index < 32 && !completion; index += 1) {
    const emitted = sender.nextFrame();
    const parsed = parseFrame(emitted.bytes);
    assert.ok(parsed, `${modeName} emitted an invalid frame`);
    const event = receiver.consume(emitted.bytes);
    frames.push({
      sequence: emitted.sequence,
      frameChecksum: frameChecksum(emitted.bytes),
      bytesBase64: base64(emitted.bytes),
    });
    if (event?.verified && event.payload) completion = event;
  }

  assert.ok(completion?.verified, `${modeName} fixture did not complete`);
  assert.deepEqual(completion.payload, envelope);
  assert.equal(receiver.snapshot?.sessionId, sessionId);

  return {
    mode: modeName,
    profileId: sender.mode.id,
    sessionId,
    blockLength: sender.mode.blockLength,
    blockCount: sender.blockCount,
    totalLength: envelope.length,
    payloadChecksum: crc32(envelope),
    usesRatelessFountain: sender.usesRatelessFountain,
    frames,
  };
}

const file = {
  name: "js-optical-interop.bin",
  mimeType: "application/octet-stream",
  bytes: bytesOf(3200, 37),
};
const envelope = encodeTransferFile(file);
const sessionIds = {
  reliable: 0x13572468,
  fast: 0x13572469,
  turbo: 0x1357246a,
};

const document = {
  schemaVersion: 1,
  protocolVersion: 2,
  source: "javascript",
  generator: "website/app/web-transfer-protocol.mjs",
  file: {
    name: file.name,
    mimeType: file.mimeType,
    bytesBase64: base64(file.bytes),
    envelopeLength: envelope.length,
    envelopeChecksum: crc32(envelope),
    envelopeBase64: base64(envelope),
  },
  cases: Object.keys(TRANSFER_MODES).map((mode) =>
    makeCase({ modeName: mode, sessionId: sessionIds[mode], envelope }),
  ),
};

mkdirSync(dirname(outputPath), { recursive: true });
writeFileSync(outputPath, `${JSON.stringify(document, null, 2)}\n`);
console.log(`wrote ${outputPath}`);
