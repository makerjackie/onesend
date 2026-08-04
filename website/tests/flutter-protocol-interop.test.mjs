import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

import {
  OpticalReceiver,
  TRANSFER_MODES,
  crc32,
  decodeTransferFile,
  parseFrame,
} from "../app/web-transfer-protocol.mjs";

function loadFixture(name) {
  return JSON.parse(
    readFileSync(
      resolve(import.meta.dirname, "../../test/fixtures/optical_interop", name),
      "utf8",
    ),
  );
}

function decodeBase64(value) {
  return Uint8Array.from(Buffer.from(value, "base64"));
}

function expectFrame(bytes, document, fixture, frameFixture, mode) {
  assert.equal(bytes.length, mode.blockLength + 28 + 4);
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const storedChecksum = view.getUint32(bytes.length - 4, true);
  assert.equal(storedChecksum, frameFixture.frameChecksum);
  assert.equal(crc32(bytes, 0, bytes.length - 4), frameFixture.frameChecksum);

  const parsed = parseFrame(bytes);
  assert.ok(parsed);
  assert.equal(parsed.header.protocolVersion, document.protocolVersion);
  assert.equal(parsed.header.profileId, mode.id);
  assert.equal(parsed.header.profileId, fixture.profileId);
  assert.equal(parsed.header.sessionId, fixture.sessionId);
  assert.equal(parsed.header.sequence, frameFixture.sequence);
  assert.equal(parsed.header.blockCount, fixture.blockCount);
  assert.equal(parsed.header.blockLength, mode.blockLength);
  assert.equal(parsed.header.blockLength, fixture.blockLength);
  assert.equal(parsed.header.totalLength, fixture.totalLength);
  assert.equal(parsed.header.payloadChecksum, fixture.payloadChecksum);
}

async function checkJsCanReadDartFixture(document) {
  assert.equal(document.schemaVersion, 1);
  assert.equal(document.protocolVersion, 2);
  assert.equal(document.source, "dart");

  const original = decodeBase64(document.file.bytesBase64);
  const envelope = decodeBase64(document.file.envelopeBase64);
  assert.equal(envelope.length, document.file.envelopeLength);
  assert.equal(crc32(envelope), document.file.envelopeChecksum);

  const decoded = await decodeTransferFile(envelope);
  assert.equal(decoded.name, document.file.name);
  assert.equal(decoded.mimeType, document.file.mimeType);
  assert.deepEqual(decoded.bytes, original);

  for (const fixture of document.cases) {
    const mode = TRANSFER_MODES[fixture.mode];
    assert.ok(mode, `unknown mode ${fixture.mode}`);
    assert.equal(fixture.profileId, mode.id);
    assert.equal(fixture.blockLength, mode.blockLength);
    assert.equal(
      fixture.usesRatelessFountain,
      fixture.mode === "fast" || fixture.mode === "turbo",
    );

    const receiver = new OpticalReceiver();
    let completion = null;
    assert.ok(fixture.frames.length > 0);
    assert.ok(fixture.frames.length <= 32);
    for (const frameFixture of fixture.frames) {
      const bytes = decodeBase64(frameFixture.bytesBase64);
      expectFrame(bytes, document, fixture, frameFixture, mode);
      const event = receiver.consume(bytes);
      if (event?.verified) completion = event;
    }

    assert.ok(completion);
    assert.equal(completion.verified, true);
    assert.deepEqual(completion.payload, envelope);
    assert.equal(receiver.snapshot.mode, fixture.mode);
    assert.equal(receiver.snapshot.sessionId, fixture.sessionId);
    assert.equal(receiver.snapshot.blockCount, fixture.blockCount);
    assert.equal(receiver.snapshot.solvedBlocks, fixture.blockCount);
  }
}

test("JS parses Dart-generated v2 frames and Envelope fixtures", async () => {
  await checkJsCanReadDartFixture(loadFixture("dart_to_js.json"));
});
