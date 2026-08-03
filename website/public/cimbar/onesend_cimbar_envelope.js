/*
 * OneSend CIMBAR envelope codec.
 *
 * This file is intentionally dependency-free and is copied verbatim to the
 * mobile asset bundle. Keep the binary layout in sync with
 * lib/services/cimbar_bridge.dart.
 */
(function (root) {
  'use strict';

  const MAGIC = Object.freeze([0x4f, 0x53, 0x43, 0x45]); // "OSCE"
  const VERSION = 1;
  const HEADER_BYTES = 17;
  const MAX_ENVELOPE_BYTES = 33 * 1024 * 1024;
  const MAX_PAYLOAD_BYTES = MAX_ENVELOPE_BYTES;
  const MAX_FILENAME_BYTES = 4096;
  const MAX_MIME_TYPE_BYTES = 256;
  const encoder = new TextEncoder();
  const decoder = new TextDecoder('utf-8', { fatal: true });
  const CRC32_TABLE = new Uint32Array(256);

  for (let index = 0; index < CRC32_TABLE.length; index += 1) {
    let value = index;
    for (let bit = 0; bit < 8; bit += 1) {
      value = (value & 1) === 1
        ? 0xedb88320 ^ (value >>> 1)
        : value >>> 1;
    }
    CRC32_TABLE[index] = value >>> 0;
  }

  function toUint8Array(value) {
    if (value instanceof Uint8Array) return value;
    if (value instanceof ArrayBuffer) return new Uint8Array(value);
    if (ArrayBuffer.isView(value)) {
      return new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
    }
    throw new TypeError('Expected an ArrayBuffer or Uint8Array.');
  }

  function crc32(value, start, end) {
    const bytes = toUint8Array(value);
    const first = start === undefined ? 0 : start;
    const last = end === undefined ? bytes.length : end;
    if (!Number.isSafeInteger(first) || !Number.isSafeInteger(last) ||
        first < 0 || last < first || last > bytes.length) {
      throw new RangeError('CRC32 range is invalid.');
    }
    let checksum = 0xffffffff;
    for (let index = first; index < last; index += 1) {
      checksum = CRC32_TABLE[(checksum ^ bytes[index]) & 0xff] ^
        (checksum >>> 8);
    }
    return (checksum ^ 0xffffffff) >>> 0;
  }

  function validateText(value, label) {
    if (typeof value !== 'string' || value.length === 0) {
      throw new TypeError(label + ' must be a non-empty string.');
    }
    for (let index = 0; index < value.length; index += 1) {
      const codeUnit = value.charCodeAt(index);
      if (codeUnit >= 0xd800 && codeUnit <= 0xdbff) {
        const next = value.charCodeAt(index + 1);
        if (!(next >= 0xdc00 && next <= 0xdfff)) {
          throw new TypeError(label + ' contains an unpaired surrogate.');
        }
        index += 1;
      } else if (codeUnit >= 0xdc00 && codeUnit <= 0xdfff) {
        throw new TypeError(label + ' contains an unpaired surrogate.');
      }
      if (codeUnit <= 0x1f || codeUnit === 0x7f) {
        throw new TypeError(label + ' contains a control character.');
      }
    }
  }

  function encodeText(value, label, maximum) {
    validateText(value, label);
    const bytes = encoder.encode(value);
    if (bytes.length > maximum) {
      throw new RangeError(label + ' exceeds ' + maximum + ' UTF-8 bytes.');
    }
    return bytes;
  }

  function decodeText(bytes, start, length, label, maximum) {
    if (length <= 0 || length > maximum || start < 0 ||
        start + length > bytes.length) {
      throw new Error(label + ' length is invalid.');
    }
    let value;
    try {
      value = decoder.decode(bytes.subarray(start, start + length));
    } catch {
      throw new Error(label + ' is not valid UTF-8.');
    }
    validateText(value, label);
    if (encoder.encode(value).length !== length) {
      throw new Error(label + ' UTF-8 is not canonical.');
    }
    return value;
  }

  function hasMagic(bytes) {
    if (bytes.length < MAGIC.length) return false;
    for (let index = 0; index < MAGIC.length; index += 1) {
      if (bytes[index] !== MAGIC[index]) return false;
    }
    return true;
  }

  function encode({ name, mimeType, bytes }) {
    const nameBytes = encodeText(name, 'Filename', MAX_FILENAME_BYTES);
    const mimeBytes = encodeText(
      mimeType || 'application/octet-stream',
      'MIME type',
      MAX_MIME_TYPE_BYTES,
    );
    const payload = toUint8Array(bytes);
    if (payload.length > MAX_PAYLOAD_BYTES) {
      throw new RangeError('CIMBAR payload exceeds 33 MiB.');
    }

    const payloadStart = HEADER_BYTES + nameBytes.length + mimeBytes.length;
    const totalLength = payloadStart + payload.length;
    if (totalLength > MAX_ENVELOPE_BYTES) {
      throw new RangeError('CIMBAR envelope exceeds 33 MiB.');
    }

    const output = new Uint8Array(totalLength);
    output.set(MAGIC, 0);
    const view = new DataView(output.buffer);
    view.setUint8(4, VERSION);
    view.setUint16(5, nameBytes.length, true);
    view.setUint16(7, mimeBytes.length, true);
    view.setUint32(9, payload.length, true);
    view.setUint32(13, crc32(payload), true);
    output.set(nameBytes, HEADER_BYTES);
    output.set(mimeBytes, HEADER_BYTES + nameBytes.length);
    output.set(payload, payloadStart);
    return output;
  }

  function decode(value) {
    const bytes = toUint8Array(value);
    if (bytes.length > MAX_ENVELOPE_BYTES) {
      throw new Error('CIMBAR envelope exceeds 33 MiB.');
    }
    if (!hasMagic(bytes)) throw new Error('CIMBAR envelope magic is invalid.');
    if (bytes.length < HEADER_BYTES) {
      throw new Error('CIMBAR envelope is truncated.');
    }

    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
    if (view.getUint8(4) !== VERSION) {
      throw new Error('Unsupported CIMBAR envelope version.');
    }
    const nameLength = view.getUint16(5, true);
    const mimeLength = view.getUint16(7, true);
    const payloadLength = view.getUint32(9, true);
    const expectedChecksum = view.getUint32(13, true);
    if (nameLength === 0 || nameLength > MAX_FILENAME_BYTES ||
        mimeLength === 0 || mimeLength > MAX_MIME_TYPE_BYTES ||
        payloadLength > MAX_PAYLOAD_BYTES) {
      throw new Error('CIMBAR envelope lengths are invalid.');
    }

    const payloadStart = HEADER_BYTES + nameLength + mimeLength;
    if (payloadStart > bytes.length ||
        bytes.length - payloadStart !== payloadLength) {
      throw new Error('CIMBAR envelope lengths are invalid.');
    }
    const name = decodeText(
      bytes,
      HEADER_BYTES,
      nameLength,
      'Filename',
      MAX_FILENAME_BYTES,
    );
    const mimeType = decodeText(
      bytes,
      HEADER_BYTES + nameLength,
      mimeLength,
      'MIME type',
      MAX_MIME_TYPE_BYTES,
    );
    const payload = bytes.slice(payloadStart);
    if (crc32(payload) !== expectedChecksum) {
      throw new Error('CIMBAR payload CRC32 check failed.');
    }
    return Object.freeze({
      version: VERSION,
      name,
      mimeType,
      bytes: payload,
      crc32: expectedChecksum,
      verified: true,
    });
  }

  const api = Object.freeze({
    MAGIC,
    VERSION,
    HEADER_BYTES,
    MAX_ENVELOPE_BYTES,
    MAX_PAYLOAD_BYTES,
    MAX_FILENAME_BYTES,
    MAX_MIME_TYPE_BYTES,
    crc32,
    encode,
    decode,
    toUint8Array,
  });
  root.OneSendCimbarEnvelope = api;
})(typeof self === 'undefined' ? globalThis : self);
