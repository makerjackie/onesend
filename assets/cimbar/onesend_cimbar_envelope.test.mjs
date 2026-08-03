import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import vm from "node:vm";

const repoRoot = resolve(import.meta.dirname, "../..");
const helperPaths = [
  resolve(repoRoot, "assets/cimbar/onesend_cimbar_envelope.js"),
  resolve(repoRoot, "website/public/cimbar/onesend_cimbar_envelope.js"),
];

function loadCodec(path) {
  const sandbox = {
    self: {},
    ArrayBuffer,
    DataView,
    Error,
    Math,
    Number,
    Object,
    RangeError,
    TextDecoder,
    TextEncoder,
    TypeError,
    Uint8Array,
  };
  vm.runInNewContext(readFileSync(path, "utf8"), sandbox, { filename: path });
  return sandbox.self.OneSendCimbarEnvelope;
}

test("mobile and website helpers share the same binary envelope", () => {
  const mobile = loadCodec(helperPaths[0]);
  const website = loadCodec(helperPaths[1]);
  const input = {
    name: "报告 📦.txt",
    mimeType: "text/plain",
    bytes: new Uint8Array([0, 1, 2, 3, 255]),
  };
  const mobileBytes = mobile.encode(input);
  const websiteBytes = website.encode(input);

  assert.deepEqual([...mobileBytes], [...websiteBytes]);
  const decoded = website.decode(mobileBytes);
  assert.equal(decoded.version, 1);
  assert.equal(decoded.name, input.name);
  assert.equal(decoded.mimeType, input.mimeType);
  assert.deepEqual([...decoded.bytes], [...input.bytes]);
  assert.equal(decoded.crc32, mobile.crc32(input.bytes));
  assert.equal(decoded.verified, true);
});

test("helper rejects CRC tampering, truncation, invalid UTF-8 and oversize", () => {
  const codec = loadCodec(helperPaths[0]);
  const encoded = codec.encode({
    name: "file.bin",
    mimeType: "application/octet-stream",
    bytes: new Uint8Array([10, 20, 30]),
  });

  const tampered = encoded.slice();
  tampered[tampered.length - 1] ^= 1;
  assert.throws(() => codec.decode(tampered), /CRC32/);
  assert.throws(() => codec.decode(encoded.slice(0, -1)), /length|truncated/i);

  const invalidUtf8 = encoded.slice();
  invalidUtf8[codec.HEADER_BYTES] = 0xff;
  assert.throws(() => codec.decode(invalidUtf8), /UTF-8/);

  const invalidLength = encoded.slice();
  new DataView(invalidLength.buffer).setUint32(
    9,
    codec.MAX_PAYLOAD_BYTES + 1,
    true,
  );
  assert.throws(() => codec.decode(invalidLength), /length|33 MiB/i);
  assert.throws(
    () => codec.encode({
      name: "file.bin",
      mimeType: "application/octet-stream",
      bytes: new Uint8Array(codec.MAX_PAYLOAD_BYTES + 1),
    }),
    /33 MiB/,
  );
});
