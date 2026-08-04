const CURRENT_PROTOCOL_VERSION = 2;
const FRAME_HEADER_LENGTH = 28;
const FRAME_CHECKSUM_LENGTH = 4;
const MAX_OPTICAL_PAYLOAD_BYTES = 72 * 1024 * 1024;
const MAX_OPTICAL_BLOCKS = 110000;
const MIN_OPTICAL_BLOCK_LENGTH = 64;
// Turbo mode uses 2921-byte blocks (Flutter interop). Must be >= 2921.
const MAX_OPTICAL_BLOCK_LENGTH = 4096;
const MAX_RATELESS_FOUNTAIN_BLOCKS = 8192;
const MAX_TRANSFER_FILE_BYTES = 64 * 1024 * 1024;
const MAX_TRANSFER_ENVELOPE_BYTES = 72 * 1024 * 1024;
const SOURCE_FRAMES_PER_GROUP = 4;
const FRAMES_PER_GROUP = SOURCE_FRAMES_PER_GROUP + 1;
const SEEN_SEQUENCE_WINDOW = 4096;
const MAXIMUM_PENDING_FRAME_LIMIT = 8192;
const ENVELOPE_MAGIC = [0x4c, 0x4d, 0x53, 0x31];
const ENVELOPE_VERSION = 2;

const CRC32_TABLE = new Uint32Array(
  Array.from({ length: 256 }, (_, index) => {
    let value = index;
    for (let bit = 0; bit < 8; bit += 1) {
      value = (value & 1) === 1 ? 0xedb88320 ^ (value >>> 1) : value >>> 1;
    }
    return value >>> 0;
  }),
);

const encoder = new TextEncoder();
const decoder = new TextDecoder();

export const TRANSFER_MODES = {
  reliable: {
    id: 0,
    label: "Compatible",
    blockLength: 720,
    frameIntervalMs: 125,
    errorCorrectionLevel: "M",
  },
  fast: {
    id: 2,
    label: "Standard",
    blockLength: 1700,
    frameIntervalMs: 1000 / 24,
    errorCorrectionLevel: "L",
  },
  turbo: {
    id: 3,
    label: "Fast",
    blockLength: 2921,
    frameIntervalMs: 1000 / 24,
    errorCorrectionLevel: "L",
  },
};

export function toUint8Array(value) {
  if (value instanceof Uint8Array) return value;
  if (value instanceof ArrayBuffer) return new Uint8Array(value);
  return new Uint8Array(value);
}

export function crc32(bytes, start = 0, end = bytes.length) {
  const input = toUint8Array(bytes);
  let checksum = 0xffffffff;
  for (let index = start; index < end; index += 1) {
    checksum =
      CRC32_TABLE[(checksum ^ input[index]) & 0xff] ^ (checksum >>> 8);
  }
  return (checksum ^ 0xffffffff) >>> 0;
}

function signed32(value) {
  return value | 0;
}

function unsigned32(value) {
  return value >>> 0;
}

function imul(left, right) {
  return Math.imul(left, right);
}

function deterministicLog(value) {
  let exponent = 0;
  let mantissa = value;
  while (mantissa >= 1.5) {
    mantissa /= 2;
    exponent += 1;
  }
  while (mantissa < 0.75) {
    mantissa *= 2;
    exponent -= 1;
  }
  const z = (mantissa - 1) / (mantissa + 1);
  const zSquared = z * z;
  let term = z;
  let sum = 0;
  for (let n = 1; n <= 21; n += 2) {
    sum += term / n;
    term *= zSquared;
  }
  return exponent * Math.LN2 + 2 * sum;
}

function solitonCdf(blockCount) {
  const cdf = new Float64Array(blockCount);
  if (blockCount === 1) {
    cdf[0] = 1;
    return cdf;
  }

  const robust = Math.max(
    1,
    0.1 * deterministicLog(blockCount / 0.5) * Math.sqrt(blockCount),
  );
  const spike = Math.min(blockCount, Math.ceil(blockCount / robust));
  let total = 0;
  for (let degree = 1; degree <= blockCount; degree += 1) {
    const rho = degree === 1 ? 1 / blockCount : 1 / (degree * (degree - 1));
    let tau = 0;
    if (degree < spike) {
      tau = robust / (degree * blockCount);
    } else if (degree === spike) {
      tau = (robust * Math.max(0, deterministicLog(robust / 0.5))) / blockCount;
    }
    total += rho + tau;
    cdf[degree - 1] = total;
  }
  for (let index = 0; index < blockCount; index += 1) {
    cdf[index] /= total;
  }
  cdf[blockCount - 1] = 1;
  return cdf;
}

function splitmix32(seed) {
  let state = signed32(seed);
  return () => {
    state = signed32(state + 0x9e3779b9);
    let value = unsigned32(state) ^ (unsigned32(state) >>> 16);
    value = unsigned32(imul(value, 0x21f0aaad));
    value = unsigned32(value ^ (value >>> 15));
    value = unsigned32(imul(value, 0x735a2d97));
    value = unsigned32(value ^ (value >>> 15));
    return value;
  };
}

function frameSeed(sessionId, sequence) {
  let hash = signed32(
    imul(sessionId + 1, 0x9e3779b1) ^
      unsigned32(sequence + 0x85ebca6b),
  );
  hash = imul(hash ^ (unsigned32(hash) >>> 13), 0xc2b2ae35);
  return signed32(unsigned32(hash) ^ (unsigned32(hash) >>> 16));
}

function isRepairSequence(sequence) {
  return sequence % FRAMES_PER_GROUP === SOURCE_FRAMES_PER_GROUP;
}

function frameBlockIndices(
  blockCount,
  cdf,
  sessionId,
  sequence,
  { protocolVersion = CURRENT_PROTOCOL_VERSION, systematicFrames = true } = {},
) {
  if (systematicFrames && !isRepairSequence(sequence)) {
    const group = Math.floor(sequence / FRAMES_PER_GROUP);
    const sourceSlot = sequence % FRAMES_PER_GROUP;
    return [
      (group * SOURCE_FRAMES_PER_GROUP + sourceSlot) % blockCount,
    ];
  }

  const random = splitmix32(frameSeed(sessionId, sequence));
  const sample = random() / 0x100000000;
  let low = 0;
  let high = blockCount - 1;
  while (low < high) {
    const middle = (low + high) >> 1;
    if (cdf[middle] >= sample) high = middle;
    else low = middle + 1;
  }
  const sampledDegree = Math.min(blockCount, low + 1);
  const degree = protocolVersion >= CURRENT_PROTOCOL_VERSION
    ? Math.min(sampledDegree, 64)
    : sampledDegree;

  if (degree > (blockCount >> 3)) {
    const scratch = new Uint32Array(blockCount);
    for (let index = 0; index < blockCount; index += 1) scratch[index] = index;
    const result = [];
    for (let index = 0; index < degree; index += 1) {
      const swapIndex = index + (random() % (blockCount - index));
      [scratch[index], scratch[swapIndex]] = [scratch[swapIndex], scratch[index]];
      result.push(scratch[index]);
    }
    return result;
  }

  const result = new Set();
  while (result.size < degree) result.add(random() % blockCount);
  return Array.from(result);
}

function xorInto(target, source) {
  for (let index = 0; index < target.length; index += 1) {
    target[index] ^= source[index];
  }
}

export function packFrame({
  profileId,
  sessionId,
  sequence,
  blockCount,
  blockLength,
  totalLength,
  payloadChecksum,
}, block) {
  const data = toUint8Array(block);
  if (data.length !== blockLength) throw new Error("Invalid frame block length");
  const bytes = new Uint8Array(
    FRAME_HEADER_LENGTH + data.length + FRAME_CHECKSUM_LENGTH,
  );
  const view = new DataView(bytes.buffer);
  view.setUint8(0, 0x4f);
  view.setUint8(1, 0x53);
  view.setUint8(2, CURRENT_PROTOCOL_VERSION);
  view.setUint8(3, profileId & 0xff);
  view.setUint32(4, sessionId >>> 0, true);
  view.setUint32(8, sequence >>> 0, true);
  view.setUint32(12, blockCount >>> 0, true);
  view.setUint16(16, blockLength, true);
  view.setUint16(18, 0, true);
  view.setUint32(20, totalLength >>> 0, true);
  view.setUint32(24, payloadChecksum >>> 0, true);
  bytes.set(data, FRAME_HEADER_LENGTH);
  view.setUint32(bytes.length - FRAME_CHECKSUM_LENGTH, crc32(bytes, 0, bytes.length - FRAME_CHECKSUM_LENGTH), true);
  return bytes;
}

export function parseFrame(value) {
  const bytes = toUint8Array(value);
  if (bytes.length <= FRAME_HEADER_LENGTH + FRAME_CHECKSUM_LENGTH) return null;
  if (bytes[0] !== 0x4f || bytes[1] !== 0x53 || bytes[2] !== CURRENT_PROTOCOL_VERSION) return null;
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const header = {
    protocolVersion: bytes[2],
    profileId: bytes[3],
    sessionId: view.getUint32(4, true),
    sequence: view.getUint32(8, true),
    blockCount: view.getUint32(12, true),
    blockLength: view.getUint16(16, true),
    totalLength: view.getUint32(20, true),
    payloadChecksum: view.getUint32(24, true),
  };
  const expectedLength = FRAME_HEADER_LENGTH + header.blockLength + FRAME_CHECKSUM_LENGTH;
  const minimumLength = (header.blockCount - 1) * header.blockLength + 1;
  const maximumLength = header.blockCount * header.blockLength;
  if (
    bytes.length !== expectedLength ||
    header.blockCount <= 0 ||
    header.blockLength <= 0 ||
    header.totalLength < minimumLength ||
    header.totalLength > maximumLength
  ) return null;
  const expectedChecksum = view.getUint32(bytes.length - FRAME_CHECKSUM_LENGTH, true);
  if (crc32(bytes, 0, bytes.length - FRAME_CHECKSUM_LENGTH) !== expectedChecksum) return null;
  return {
    header,
    block: bytes.slice(FRAME_HEADER_LENGTH, bytes.length - FRAME_CHECKSUM_LENGTH),
  };
}

/**
 * Extracts OneSend bytes from a ZXing result.
 *
 * QR Result#getRawBytes() contains the complete QR codewords, including
 * Reed-Solomon correction bytes. BYTE_SEGMENTS is the actual byte-mode
 * payload. A rawBytes fallback is kept for decoders that expose payload bytes
 * there, but it must be a valid OneSend frame before it reaches the receiver.
 */
function latin1TextToBytes(text) {
  if (typeof text !== "string" || text.length === 0) return null;
  const bytes = new Uint8Array(text.length);
  for (let index = 0; index < text.length; index += 1) {
    const code = text.charCodeAt(index);
    // ISO-8859-1 / Latin-1 only. Multi-byte chars mean the decoder mangled binary.
    if (code > 0xff) return null;
    bytes[index] = code;
  }
  return bytes;
}

export function extractScannerFrame(result) {
  const metadata = result?.getResultMetadata?.();
  // ZXing ResultMetadataType.BYTE_SEGMENTS === 2 (also accept string key).
  const byteSegments =
    metadata?.get?.(2) ??
    metadata?.get?.("BYTE_SEGMENTS") ??
    metadata?.get?.("2");
  if (Array.isArray(byteSegments)) {
    const segments = byteSegments.filter(
      (segment) => segment instanceof Uint8Array || segment instanceof Uint8ClampedArray,
    );
    if (segments.length > 0) {
      const payload = new Uint8Array(
        segments.reduce((total, segment) => total + segment.byteLength, 0),
      );
      let offset = 0;
      for (const segment of segments) {
        payload.set(new Uint8Array(segment.buffer, segment.byteOffset, segment.byteLength), offset);
        offset += segment.byteLength;
      }
      if (payload.length > 0) return payload;
    }
  }

  // Some mobile WebViews only expose getText(). With CHARACTER_SET=ISO-8859-1
  // the string is a 1:1 Latin-1 map of the byte payload.
  if (typeof result?.getText === "function") {
    const fromText = latin1TextToBytes(result.getText());
    if (fromText && parseFrame(fromText)) return fromText;
  }

  const rawBytes = result?.getRawBytes?.();
  if (!rawBytes?.length) return null;
  const candidate = toUint8Array(rawBytes);
  return parseFrame(candidate) ? candidate : null;
}

function randomSessionId() {
  const values = new Uint32Array(1);
  if (globalThis.crypto?.getRandomValues) {
    globalThis.crypto.getRandomValues(values);
    return values[0] || 1;
  }
  return (Math.floor(Math.random() * 0xffffffff) + 1) >>> 0;
}

export class OpticalSender {
  constructor(payload, mode = "fast", sessionId = randomSessionId()) {
    this.payload = toUint8Array(payload);
    this.mode = TRANSFER_MODES[mode] ?? TRANSFER_MODES.fast;
    this.sessionId = sessionId >>> 0;
    this.payloadChecksum = crc32(this.payload);
    this.blockCount = Math.max(1, Math.ceil(this.payload.length / this.mode.blockLength));
    this.usesRatelessFountain =
      (mode === "fast" || mode === "turbo") &&
      this.blockCount <= MAX_RATELESS_FOUNTAIN_BLOCKS;
    this.systematicFrames = !this.usesRatelessFountain;
    this.encoder = new LTEncoder({
      payload: this.payload,
      blockLength: this.mode.blockLength,
      sessionId: this.sessionId,
      systematicFrames: this.systematicFrames,
    });
    this.sequence = 0;
    this.framesEmitted = 0;
    this.sourceFramesEmitted = 0;
  }

  nextFrame() {
    const sequence = this.sequence;
    const repair = this.usesRatelessFountain || isRepairSequence(sequence);
    const block = this.encoder.encode(sequence);
    const bytes = packFrame({
      profileId: this.mode.id,
      sessionId: this.sessionId,
      sequence,
      blockCount: this.blockCount,
      blockLength: this.mode.blockLength,
      totalLength: this.payload.length,
      payloadChecksum: this.payloadChecksum,
    }, block);
    this.sequence = (this.sequence + 1) >>> 0;
    this.framesEmitted += 1;
    if (!repair) this.sourceFramesEmitted += 1;
    const progressFrames = this.usesRatelessFountain
      ? this.framesEmitted
      : this.sourceFramesEmitted;
    return {
      bytes,
      sequence,
      passNumber: Math.floor(progressFrames / this.blockCount) + 1,
      passProgress: (progressFrames % this.blockCount) / this.blockCount,
    };
  }
}

class LTEncoder {
  constructor({ payload, blockLength, sessionId, systematicFrames }) {
    this.payload = payload;
    this.blockLength = blockLength;
    this.sessionId = sessionId;
    this.blockCount = Math.max(1, Math.ceil(payload.length / blockLength));
    this.cdf = solitonCdf(this.blockCount);
    this.systematicFrames = systematicFrames;
  }

  encode(sequence) {
    const indices = frameBlockIndices(
      this.blockCount,
      this.cdf,
      this.sessionId,
      sequence,
      { systematicFrames: this.systematicFrames },
    );
    const output = new Uint8Array(this.blockLength);
    if (indices.length === 1) {
      const start = indices[0] * this.blockLength;
      const end = Math.min(start + this.blockLength, this.payload.length);
      if (start < end) output.set(this.payload.subarray(start, end));
      return output;
    }
    for (const blockIndex of indices) {
      const start = blockIndex * this.blockLength;
      const available = Math.min(this.blockLength, this.payload.length - start);
      for (let byte = 0; byte < available; byte += 1) {
        output[byte] ^= this.payload[start + byte];
      }
    }
    return output;
  }
}

class LTDecoder {
  constructor({ blockCount, blockLength, sessionId, totalLength, systematicFrames }) {
    this.blockCount = blockCount;
    this.blockLength = blockLength;
    this.sessionId = sessionId;
    this.totalLength = totalLength;
    this.systematicFrames = systematicFrames;
    this.words = Math.ceil(blockLength / 4);
    this.cdf = solitonCdf(blockCount);
    this.solved = Array.from({ length: blockCount }, () => null);
    this.waitingByBlock = new Map();
    this.seen = new Set();
    this.seenOrder = [];
    this.maximumPendingFrames = Math.min(blockCount * 2, MAXIMUM_PENDING_FRAME_LIMIT);
    this.solvedCount = 0;
    this.framesNew = 0;
    this.framesDuplicate = 0;
    this.framesDiscarded = 0;
    this.pendingFrames = 0;
  }

  get isComplete() {
    return this.solvedCount >= this.blockCount;
  }

  addFrame(sequence, block) {
    const bytes = toUint8Array(block);
    if (bytes.length !== this.blockLength) {
      this.framesDiscarded += 1;
      return;
    }
    if (this.seen.has(sequence)) {
      this.framesDuplicate += 1;
      return;
    }
    this.seen.add(sequence);
    this.seenOrder.push(sequence);
    if (this.seenOrder.length > SEEN_SEQUENCE_WINDOW) {
      this.seen.delete(this.seenOrder.shift());
    }
    this.framesNew += 1;
    if (this.isComplete) return;

    const indices = new Set(frameBlockIndices(
      this.blockCount,
      this.cdf,
      this.sessionId,
      sequence,
      { systematicFrames: this.systematicFrames },
    ));
    const words = new Uint32Array(this.words);
    new Uint8Array(words.buffer).set(bytes);
    for (const blockIndex of Array.from(indices)) {
      const solved = this.solved[blockIndex];
      if (solved) {
        xorInto(words, solved);
        indices.delete(blockIndex);
      }
    }
    if (indices.size === 0) return;
    if (indices.size === 1) {
      this.resolve(indices.values().next().value, words);
      return;
    }
    if (this.pendingFrames >= this.maximumPendingFrames) {
      this.framesDiscarded += 1;
      return;
    }
    const pending = { indices, words };
    this.pendingFrames += 1;
    for (const blockIndex of indices) {
      if (!this.waitingByBlock.has(blockIndex)) this.waitingByBlock.set(blockIndex, new Set());
      this.waitingByBlock.get(blockIndex).add(pending);
    }
  }

  resolve(firstBlock, firstWords) {
    const queue = [{ blockIndex: firstBlock, words: firstWords }];
    while (queue.length > 0) {
      const { blockIndex, words } = queue.pop();
      if (this.solved[blockIndex]) continue;
      this.solved[blockIndex] = words;
      this.solvedCount += 1;
      const waiting = this.waitingByBlock.get(blockIndex);
      this.waitingByBlock.delete(blockIndex);
      if (!waiting) continue;
      for (const pending of waiting) {
        xorInto(pending.words, words);
        pending.indices.delete(blockIndex);
        if (pending.indices.size === 1) {
          const remaining = pending.indices.values().next().value;
          this.waitingByBlock.get(remaining)?.delete(pending);
          this.pendingFrames -= 1;
          if (!this.solved[remaining]) {
            queue.push({ blockIndex: remaining, words: pending.words });
          }
        }
      }
    }
  }

  assemble() {
    if (!this.isComplete) return null;
    const output = new Uint8Array(this.totalLength);
    for (let block = 0; block < this.blockCount; block += 1) {
      const start = block * this.blockLength;
      const length = Math.min(this.blockLength, this.totalLength - start);
      if (length <= 0 || !this.solved[block]) continue;
      output.set(new Uint8Array(this.solved[block].buffer, 0, length), start);
    }
    return output;
  }
}

function isRatelessProfile(profileId, blockCount) {
  return (
    (profileId === TRANSFER_MODES.fast.id ||
      profileId === TRANSFER_MODES.turbo.id) &&
    blockCount <= MAX_RATELESS_FOUNTAIN_BLOCKS
  );
}

function snapshotFor(header, decoderState) {
  const mode = Object.entries(TRANSFER_MODES).find(([, value]) =>
    value.id === header.profileId && value.blockLength === header.blockLength,
  )?.[0] ?? "unknown";
  const usesRateless = isRatelessProfile(header.profileId, decoderState.blockCount);
  let progress = 0;
  if (decoderState.blockCount === 0) {
    progress = 0;
  } else if (decoderState.isComplete) {
    progress = 1;
  } else if (usesRateless) {
    progress = Math.min(
      0.95,
      decoderState.framesNew / (decoderState.blockCount * 1.25),
    );
  } else {
    progress = Math.min(1, decoderState.solvedCount / decoderState.blockCount);
  }
  return {
    protocolVersion: header.protocolVersion,
    profileId: header.profileId,
    mode,
    sessionId: decoderState.sessionId,
    blockCount: decoderState.blockCount,
    totalLength: decoderState.totalLength,
    framesNew: decoderState.framesNew,
    framesDuplicate: decoderState.framesDuplicate,
    framesDiscarded: decoderState.framesDiscarded,
    solvedBlocks: decoderState.solvedCount,
    progress,
  };
}

export class OpticalReceiver {
  constructor() {
    this.decoder = null;
    this.configuration = null;
    this.delivered = false;
  }

  get snapshot() {
    if (!this.decoder || !this.configuration) return null;
    return snapshotFor(this.configuration, this.decoder);
  }

  consume(value) {
    const parsed = parseFrame(value);
    if (!parsed) return null;
    const { header } = parsed;
    if (
      header.totalLength > MAX_OPTICAL_PAYLOAD_BYTES ||
      header.blockLength < MIN_OPTICAL_BLOCK_LENGTH ||
      header.blockLength > MAX_OPTICAL_BLOCK_LENGTH ||
      header.blockCount > MAX_OPTICAL_BLOCKS
    ) return null;
    const mode = Object.values(TRANSFER_MODES).find((item) =>
      item.id === header.profileId && item.blockLength === header.blockLength,
    );
    if (!mode) return null;

    if (!this.decoder) {
      this.configuration = header;
      this.decoder = new LTDecoder({
        blockCount: header.blockCount,
        blockLength: header.blockLength,
        sessionId: header.sessionId,
        totalLength: header.totalLength,
        // Must match sender: fast + turbo use rateless fountain (non-systematic).
        systematicFrames: !isRatelessProfile(
          header.profileId,
          header.blockCount,
        ),
      });
      this.delivered = false;
    } else if (!matchesConfiguration(this.configuration, header)) {
      return null;
    }

    this.decoder.addFrame(header.sequence, parsed.block);
    const snapshot = this.snapshot;
    if (!this.decoder.isComplete || this.delivered) return { snapshot };
    const payload = this.decoder.assemble();
    if (!payload) return { snapshot };
    if (crc32(payload) !== header.payloadChecksum) {
      return { snapshot, error: "The complete transfer failed its checksum." };
    }
    this.delivered = true;
    return { snapshot: this.snapshot, payload, verified: true };
  }

  reset() {
    this.decoder = null;
    this.configuration = null;
    this.delivered = false;
  }
}

function matchesConfiguration(left, right) {
  return [
    "protocolVersion",
    "profileId",
    "sessionId",
    "blockCount",
    "blockLength",
    "totalLength",
    "payloadChecksum",
  ].every((key) => left[key] === right[key]);
}

export function sanitizeFileName(name) {
  const normalized = name.replace(/[\\/:*?"<>|\u0000-\u001f]/g, "_").trim();
  return normalized || "received.bin";
}

export function encodeTransferFile({ name, mimeType, bytes }) {
  const input = toUint8Array(bytes);
  if (input.length > MAX_TRANSFER_FILE_BYTES) {
    throw new Error("Files must be 64 MB or smaller.");
  }
  const nameBytes = encoder.encode(sanitizeFileName(name));
  const mimeBytes = encoder.encode(mimeType || "application/octet-stream");
  if (nameBytes.length > 0xffff || mimeBytes.length > 0xffff) {
    throw new Error("File metadata is too long.");
  }
  const bytesOut = new Uint8Array(26 + nameBytes.length + mimeBytes.length + input.length);
  const view = new DataView(bytesOut.buffer);
  bytesOut.set(ENVELOPE_MAGIC, 0);
  view.setUint8(4, ENVELOPE_VERSION);
  view.setUint8(5, 0); // Browser sender deliberately stays uncompressed for compatibility.
  view.setUint16(6, nameBytes.length, true);
  view.setUint16(8, mimeBytes.length, true);
  view.setUint32(10, input.length, true);
  view.setUint32(14, crc32(input), true);
  view.setUint32(18, input.length, true);
  view.setUint32(22, crc32(input), true);
  const metadataStart = 26;
  bytesOut.set(nameBytes, metadataStart);
  bytesOut.set(mimeBytes, metadataStart + nameBytes.length);
  bytesOut.set(input, metadataStart + nameBytes.length + mimeBytes.length);
  return bytesOut;
}

function hasEnvelopeMagic(bytes) {
  return ENVELOPE_MAGIC.every((value, index) => bytes[index] === value);
}

function decodeName(bytes, start, length) {
  return sanitizeFileName(decoder.decode(bytes.subarray(start, start + length)));
}

function decodeMime(bytes, start, length) {
  return decoder.decode(bytes.subarray(start, start + length)) || "application/octet-stream";
}

async function decompressGzip(bytes) {
  if (typeof DecompressionStream === "undefined") {
    throw new Error("This browser cannot decompress the received file.");
  }
  const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("gzip"));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

export async function decodeTransferFile(value) {
  const bytes = toUint8Array(value);
  if (bytes.length > MAX_TRANSFER_ENVELOPE_BYTES) throw new Error("Received file is too large.");
  if (!hasEnvelopeMagic(bytes)) {
    if (bytes.length > MAX_TRANSFER_FILE_BYTES) throw new Error("Received file is too large.");
    return { name: "received.bin", mimeType: "application/octet-stream", bytes };
  }
  if (bytes.length < 5) throw new Error("The file envelope is truncated.");
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  if (bytes[4] === 1) {
    if (bytes.length < 9) throw new Error("The legacy file envelope is truncated.");
    const nameLength = view.getUint16(5, true);
    const mimeLength = view.getUint16(7, true);
    const dataStart = 9 + nameLength + mimeLength;
    if (dataStart > bytes.length) throw new Error("The legacy file metadata is invalid.");
    return {
      name: decodeName(bytes, 9, nameLength),
      mimeType: decodeMime(bytes, 9 + nameLength, mimeLength),
      bytes: bytes.slice(dataStart),
    };
  }
  if (bytes[4] !== ENVELOPE_VERSION || bytes.length < 26) {
    throw new Error("Unsupported OneSend file envelope.");
  }
  const flags = bytes[5];
  if ((flags & ~1) !== 0) throw new Error("The file envelope has unknown flags.");
  const nameLength = view.getUint16(6, true);
  const mimeLength = view.getUint16(8, true);
  const originalLength = view.getUint32(10, true);
  const originalChecksum = view.getUint32(14, true);
  const storedLength = view.getUint32(18, true);
  const storedChecksum = view.getUint32(22, true);
  const dataStart = 26 + nameLength + mimeLength;
  if (originalLength > MAX_TRANSFER_FILE_BYTES || dataStart > bytes.length || bytes.length - dataStart !== storedLength) {
    throw new Error("The file envelope lengths are invalid.");
  }
  const stored = bytes.slice(dataStart);
  if (crc32(stored) !== storedChecksum) throw new Error("Stored file data failed its checksum.");
  const original = (flags & 1) === 1 ? await decompressGzip(stored) : stored;
  if (original.length !== originalLength || crc32(original) !== originalChecksum) {
    throw new Error("The original file failed its checksum.");
  }
  return {
    name: decodeName(bytes, 26, nameLength),
    mimeType: decodeMime(bytes, 26 + nameLength, mimeLength),
    bytes: original,
  };
}

export function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(bytes < 10 * 1024 ? 1 : 0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB`;
}

export function formatSpeed(bytesPerSecond) {
  if (!Number.isFinite(bytesPerSecond) || bytesPerSecond <= 0) return "—";
  if (bytesPerSecond < 1024) return `${Math.round(bytesPerSecond)} B/s`;
  return `${(bytesPerSecond / 1024).toFixed(bytesPerSecond < 10 * 1024 ? 1 : 0)} KB/s`;
}

export function theoreticalSpeed(mode = "fast") {
  const config = TRANSFER_MODES[mode] ?? TRANSFER_MODES.fast;
  return config.blockLength * (1000 / config.frameIntervalMs) * SOURCE_FRAMES_PER_GROUP / FRAMES_PER_GROUP;
}
