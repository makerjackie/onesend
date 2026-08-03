import assert from "node:assert/strict";
import test from "node:test";
import QRCode from "qrcode";
import {
  BinaryBitmap,
  DecodeHintType,
  HybridBinarizer,
  QRCodeReader,
  RGBLuminanceSource,
  ResultMetadataType,
} from "@zxing/library";

import {
  OpticalReceiver,
  OpticalSender,
  crc32,
  decodeTransferFile,
  encodeTransferFile,
  extractScannerFrame,
  packFrame,
  parseFrame,
} from "../app/web-transfer-protocol.mjs";

function bytesOf(length, seed = 17) {
  return Uint8Array.from(
    { length },
    (_, index) => (index * 97 + seed * 13 + (index >> 3)) & 0xff,
  );
}

test("encodes raw bytes as a standard QR byte segment", () => {
  const rawFrame = bytesOf(1732, 29);
  const symbol = QRCode.create(
    [{ data: new Uint8ClampedArray(rawFrame), mode: "byte" }],
    { errorCorrectionLevel: "L", maskPattern: rawFrame.at(-4) & 7 },
  );
  assert.equal(symbol.segments[0].mode.id, "Byte");
  assert.deepEqual(symbol.segments[0].data, rawFrame);
  assert.ok(symbol.modules.size >= 21);
});

test("ZXing exposes the raw byte segment, not only QR codewords", () => {
  const rawFrame = bytesOf(1732, 31);
  const symbol = QRCode.create(
    [{ data: new Uint8ClampedArray(rawFrame), mode: "byte" }],
    { errorCorrectionLevel: "L", maskPattern: rawFrame.at(-4) & 7 },
  );
  const scale = 4;
  const margin = 4;
  const width = (symbol.modules.size + margin * 2) * scale;
  const luminance = new Uint8ClampedArray(width * width);
  for (let y = 0; y < width; y += 1) {
    for (let x = 0; x < width; x += 1) {
      const row = Math.floor(y / scale) - margin;
      const column = Math.floor(x / scale) - margin;
      const dark =
        row >= 0 &&
        column >= 0 &&
        row < symbol.modules.size &&
        column < symbol.modules.size &&
        symbol.modules.get(row, column);
      luminance[y * width + x] = dark ? 0 : 255;
    }
  }
  const result = new QRCodeReader().decode(
    new BinaryBitmap(
      new HybridBinarizer(new RGBLuminanceSource(luminance, width, width)),
    ),
    new Map([[DecodeHintType.PURE_BARCODE, true]]),
  );
  const segments = result
    .getResultMetadata()
    .get(ResultMetadataType.BYTE_SEGMENTS);
  assert.ok(Array.isArray(segments));
  assert.deepEqual(segments[0], rawFrame);
  assert.notEqual(result.getRawBytes().length, rawFrame.length);
  assert.deepEqual(
    extractScannerFrame({
      getResultMetadata: () => result.getResultMetadata(),
      getRawBytes: () => result.getRawBytes(),
    }),
    rawFrame,
  );
});

test("only accepts a rawBytes fallback when it is already a valid OneSend frame", () => {
  const sender = new OpticalSender(encodeTransferFile({
    name: "fallback.bin",
    mimeType: "application/octet-stream",
    bytes: bytesOf(80, 9),
  }), "reliable", 0x11223344);
  const frame = sender.nextFrame().bytes;
  assert.deepEqual(
    extractScannerFrame({
      getResultMetadata: () => new Map(),
      getRawBytes: () => frame,
    }),
    frame,
  );
  assert.equal(
    extractScannerFrame({
      getResultMetadata: () => new Map(),
      getRawBytes: () => new Uint8Array([...frame, 0]),
    }),
    null,
  );
});

test("packs and parses the Flutter-compatible v2 frame header and CRC", () => {
  const block = bytesOf(720, 3);
  const frame = packFrame(
    {
      profileId: 0,
      sessionId: 0x12345678,
      sequence: 14,
      blockCount: 3,
      blockLength: block.length,
      totalLength: 2100,
      payloadChecksum: crc32(bytesOf(2100, 4)),
    },
    block,
  );
  const parsed = parseFrame(frame);
  assert.ok(parsed);
  assert.equal(parsed.header.sessionId, 0x12345678);
  assert.equal(parsed.header.sequence, 14);
  assert.deepEqual(parsed.block, block);

  frame[frame.length - 1] ^= 1;
  assert.equal(parseFrame(frame), null);
});

test("round-trips a fast raw-byte transfer through the browser receiver", async () => {
  const original = bytesOf(31_000, 41);
  const envelope = encodeTransferFile({
    name: "中文 name.bin",
    mimeType: "application/octet-stream",
    bytes: original,
  });
  const sender = new OpticalSender(envelope, "fast", 0x0badcafe);
  const receiver = new OpticalReceiver();
  let completed = null;

  for (let index = 0; index < sender.blockCount * 8 && !completed; index += 1) {
    const event = receiver.consume(sender.nextFrame().bytes);
    if (event?.payload) completed = event;
  }

  assert.ok(completed?.verified);
  const file = await decodeTransferFile(completed.payload);
  assert.equal(file.name, "中文 name.bin");
  assert.equal(file.mimeType, "application/octet-stream");
  assert.deepEqual(file.bytes, original);
});

test("keeps reliable mode readable with systematic and repair frames", async () => {
  const original = bytesOf(6_200, 77);
  const envelope = encodeTransferFile({
    name: "reliable.dat",
    mimeType: "application/octet-stream",
    bytes: original,
  });
  const sender = new OpticalSender(envelope, "reliable", 0x01020304);
  const receiver = new OpticalReceiver();
  let completed = null;

  for (let index = 0; index < sender.blockCount * 5 && !completed; index += 1) {
    const event = receiver.consume(sender.nextFrame().bytes);
    if (event?.payload) completed = event;
  }

  assert.ok(completed?.verified);
  const file = await decodeTransferFile(completed.payload);
  assert.deepEqual(file.bytes, original);
});
