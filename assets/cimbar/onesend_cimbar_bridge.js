/*
 * OneSend libcimbar WebView wrapper.
 *
 * Copyright (c) 2026 OneSend contributors
 * SPDX-License-Identifier: MIT
 *
 * The libcimbar JavaScript/WASM files are kept as unmodified upstream
 * artifacts. This file only supplies the OneSend page shell, event protocol,
 * and WebView download bridge around them.
 */
(function (global) {
  'use strict';

  // Peak experimental ceiling: match libcimbar/envelope 33 MiB (iPhone tests).
  const MAX_INPUT_FILE_BYTES = 33 * 1024 * 1024;
  const MAX_ENVELOPE_BYTES = MAX_INPUT_FILE_BYTES;
  const CHUNK_BYTES = 128 * 1024;
  const BRIDGE_CHANNEL = 'OneSendCimbarBridge';
  const state = {
    sendReady: false,
    sendPaused: false,
    sendInFlight: false,
    sendGeneration: 0,
    receiveStarted: false,
    receiveVideoStarted: false,
    receiveWasmReady: false,
    receiveSession: 0,
    receiveStartedAt: 0,
    receiveWorkers: [],
    receiveGeneration: 0,
    nativeWorker: null,
    workerProxy: null,
    pendingAnimationFrames: [],
    pausedRequestAnimationFrame: null,
  };

  function bridge(type, details) {
    const payload = Object.assign({ type: type }, details || {});
    try {
      if (global[BRIDGE_CHANNEL] &&
          typeof global[BRIDGE_CHANNEL].postMessage === 'function') {
        global[BRIDGE_CHANNEL].postMessage(JSON.stringify(payload));
      }
    } catch (error) {
      console.error('[onesend-cimbar] bridge error', error);
    }
  }

  function messageFor(error) {
    if (error && typeof error.message === 'string') {
      return error.message;
    }
    return String(error);
  }

  function fail(phase, error) {
    console.error('[onesend-cimbar] ' + phase + ' error', error);
    bridge('error', { phase: phase, message: messageFor(error) });
  }

  function setText(id, value) {
    const element = document.getElementById(id);
    if (element) {
      element.textContent = String(value);
    }
  }

  function makeSession() {
    state.receiveSession += 1;
    return 'cimbar-' + Date.now().toString(36) + '-' +
      state.receiveSession.toString(36);
  }

  function bytesToBase64(bytes) {
    let binary = '';
    const step = 0x8000;
    for (let offset = 0; offset < bytes.length; offset += step) {
      const end = Math.min(offset + step, bytes.length);
      binary += String.fromCharCode.apply(null, bytes.subarray(offset, end));
    }
    return btoa(binary);
  }

  function installPausedAnimationFrame() {
    if (state.animationFrameInstalled) {
      return;
    }
    state.animationFrameInstalled = true;
    state.nativeRequestAnimationFrame =
      global.requestAnimationFrame.bind(global);
    state.pausedRequestAnimationFrame = function (callback) {
      if (state.sendPaused) {
        state.pendingAnimationFrames.push(callback);
        return 0;
      }
      return state.nativeRequestAnimationFrame(callback);
    };
    global.requestAnimationFrame = state.pausedRequestAnimationFrame;
  }

  function resumeAnimationFrame() {
    const callback = state.pendingAnimationFrames.shift();
    if (callback) {
      state.nativeRequestAnimationFrame(callback);
    }
  }

  function sendWasmBytes(bytes) {
    const length = bytes.length;
    const pointer = global.Module._malloc(Math.max(length, 1));
    const wasmBytes = new Uint8Array(
      global.Module.HEAPU8.buffer,
      pointer,
      length,
    );
    wasmBytes.set(bytes);
    try {
      global.Send.encode_bytes(wasmBytes);
    } finally {
      global.Module._free(pointer);
    }
  }

  function envelopeCodec() {
    const codec = global.OneSendCimbarEnvelope;
    if (!codec || typeof codec.encode !== 'function' ||
        typeof codec.decode !== 'function') {
      throw new Error('OneSend CIMBAR envelope codec 未加载。');
    }
    return codec;
  }

  async function encodeFile(file) {
    if (state.sendInFlight) {
      throw new Error('已有文件正在准备，请先暂停或等待完成。');
    }
    if (!file || typeof file.size !== 'number') {
      throw new Error('没有选择有效文件。');
    }
    if (file.size > MAX_INPUT_FILE_BYTES) {
      throw new Error('当前移动端 CIMBAR 实验上限为 33 MiB。');
    }

    state.sendInFlight = true;
    const sendGeneration = state.sendGeneration;
    setText('send-status', '正在准备文件…');
    bridge('send-prepared', {
      name: file.name || 'selected.bin',
      size: file.size,
      mode: 'B',
    });

    try {
      if (typeof file.arrayBuffer !== 'function') {
        throw new Error('当前 WebView 不支持读取文件字节。');
      }
      const rawBytes = new Uint8Array(await file.arrayBuffer());
      if (rawBytes.length !== file.size) {
        throw new Error('读取文件大小与选择结果不一致。');
      }
      const mimeType = file.type || 'application/octet-stream';
      const envelope = envelopeCodec().encode({
        name: file.name || 'selected.bin',
        mimeType: mimeType,
        bytes: rawBytes,
      });
      if (envelope.length > MAX_ENVELOPE_BYTES) {
        throw new Error('文件加上 CIMBAR envelope 后超过 33 MiB 移动端上限。');
      }

      global.Send.encode_init(file.name || 'selected.bin');
      const wasmChunkSize = global.Module._cimbare_encode_bufsize() * 16;
      const chunkSize = Math.max(1, wasmChunkSize || CHUNK_BYTES);
      let offset = 0;
      while (offset < envelope.length) {
        if (sendGeneration !== state.sendGeneration) return;
        const end = Math.min(offset + chunkSize, envelope.length);
        const bytes = new Uint8Array(
          envelope.subarray(offset, end),
        );
        sendWasmBytes(bytes);
        offset = end;
        const originalBytesRead = file.size === 0
          ? 0
          : Math.min(file.size, Math.round(offset / envelope.length * file.size));
        setText('send-status', '正在准备 ' + originalBytesRead + ' / ' + file.size + ' B');
        bridge('send-progress', {
          name: file.name || 'selected.bin',
          size: file.size,
          bytesRead: originalBytesRead,
        });
        await new Promise(function (resolve) { setTimeout(resolve, 0); });
      }

      // A zero-length call flushes the upstream encoder.
      if (sendGeneration !== state.sendGeneration) return;
      sendWasmBytes(new Uint8Array(0));
      setText('send-status', '文件已准备，正在播放');
      bridge('send-complete', {
        name: file.name || 'selected.bin',
        size: file.size,
        mode: 'B',
      });
    } catch (error) {
      fail('send', error);
    } finally {
      state.sendInFlight = false;
    }
  }

  function bootSend() {
    try {
      installPausedAnimationFrame();
      const canvas = document.getElementById('canvas');
      if (!canvas || !global.Main || !global.Send) {
        throw new Error('发送页面上游引擎未加载。');
      }
      global.Module = global.Module || {};
      global.Module.canvas = canvas;
      global.Module.onRuntimeInitialized = function () {
        try {
          // The upstream worker remains packaged for offline use. The sender
          // intentionally uses the main-thread API on mobile WebViews because
          // OffscreenCanvas support differs between Android WebView and WKWebView.
          global.Main.init(canvas);
          // Mode B + 15 fps: peak upstream profile for high-end phone tests.
          // (Bm/3fps was the conservative reliability profile.)
          if (typeof global.Main.setMode === 'function') {
            global.Main.setMode('B');
          } else if (typeof global.Send.setMode === 'function') {
            global.Send.setMode(68);
          }
          global.Send.setFPS(15);
          state.sendReady = true;
          setText('send-status', '请选择文件开始播放');
          bridge('send-ready', { mode: 'B' });
        } catch (error) {
          fail('send-init', error);
        }
      };
    } catch (error) {
      fail('send-init', error);
    }
  }

  function togglePause(paused) {
    state.sendPaused = Boolean(paused);
    try {
      global.Main.togglePause(state.sendPaused);
      if (!state.sendPaused) {
        resumeAnimationFrame();
      }
      setText('send-status', state.sendPaused ? '已暂停' : '正在播放');
      bridge('send-paused', { paused: state.sendPaused });
    } catch (error) {
      fail('send-pause', error);
    }
  }

  function installReceiveHooks() {
    if (state.receiveHooksInstalled) {
      return;
    }
    state.receiveHooksInstalled = true;

    const originalProgress = global.Recv.render_progress;
    global.Recv.render_progress = function (report) {
      if (Array.isArray(report)) {
        bridge('decode-progress', {
          progress: report.map(function (value) { return Number(value); }),
          mode: 'B',
        });
      }
      return originalProgress.apply(this, arguments);
    };

    const originalError = global.Recv.set_error;
    global.Recv.set_error = function (message) {
      bridge('error', { phase: 'decode', message: String(message) });
      return originalError.apply(this, arguments);
    };

    const originalRestartPausedCamera = global.Recv.restart_paused_camera;
    if (typeof originalRestartPausedCamera === 'function') {
      global.Recv.restart_paused_camera = function () {
        if (!state.receiveStarted) return;
        return originalRestartPausedCamera.apply(this, arguments);
      };
    }

    const originalDecode = global.Recv.on_decode;
    global.Recv.on_decode = function (workerId, data) {
      if (data && data.error) {
        fail('decode', data.res || 'worker decoder error');
      } else if (data && data.failed_extract) {
        bridge('decode-progress', { phase: 'scan', worker: workerId });
      }
      return originalDecode.apply(this, arguments);
    };

    const originalDownload = global.Zstd.download_blob;
    global.Zstd.download_blob = async function (name, blob) {
      const session = makeSession();
      const receiveGeneration = state.receiveGeneration;
      try {
        const sourceSize = Number(blob && blob.size);
        if (!Number.isSafeInteger(sourceSize) ||
            sourceSize < 0 || sourceSize > MAX_ENVELOPE_BYTES) {
          throw new Error('解码结果超过 33 MiB 移动端上限或大小无效。');
        }
        const buffer = await blob.arrayBuffer();
        if (buffer.byteLength !== sourceSize) {
          throw new Error('解码结果大小在传递过程中发生变化。');
        }
        const decoded = envelopeCodec().decode(new Uint8Array(buffer));
        if (decoded.verified !== true) {
          throw new Error('CIMBAR envelope 未通过 CRC32 校验。');
        }
        const filename = decoded.name;
        const mimeType = decoded.mimeType;
        const bytes = decoded.bytes;
        const size = bytes.length;
        if (size > MAX_INPUT_FILE_BYTES) {
          throw new Error('解码文件超过 33 MiB 移动端上限。');
        }
        if (receiveGeneration !== state.receiveGeneration ||
            !state.receiveStarted) {
          return;
        }
        const totalChunks = size === 0 ? 0 : Math.ceil(size / CHUNK_BYTES);
        bridge('receive-file-start', {
          session: session,
          name: filename,
          mimeType: mimeType,
          size: size,
          totalChunks: totalChunks,
          crc32: decoded.crc32,
          verified: true,
        });
        for (let index = 0; index < totalChunks; index += 1) {
          if (receiveGeneration !== state.receiveGeneration ||
              !state.receiveStarted) {
            return;
          }
          const start = index * CHUNK_BYTES;
          const end = Math.min(start + CHUNK_BYTES, bytes.length);
          bridge('receive-file-chunk', {
            session: session,
            index: index,
            size: size,
            totalChunks: totalChunks,
            data: bytesToBase64(bytes.subarray(start, end)),
          });
          await new Promise(function (resolve) { setTimeout(resolve, 0); });
        }
        bridge('receive-file-complete', {
          session: session,
          size: size,
          totalChunks: totalChunks,
          crc32: decoded.crc32,
          verified: true,
        });
        bridge('receive-complete', {
          session: session,
          name: filename,
          size: size,
          crc32: decoded.crc32,
          verified: true,
          elapsedMs: state.receiveStartedAt > 0
            ? Math.max(0, performance.now() - state.receiveStartedAt)
            : 0,
        });
      } catch (error) {
        fail('receive', error);
      }
    };
    // Keep a reference for diagnostics without invoking the browser download.
    state.originalDownload = originalDownload;
  }

  function installReceiveWorkerTracking() {
    if (state.workerProxy || typeof global.Worker !== 'function') {
      return;
    }
    state.nativeWorker = global.Worker;
    state.workerProxy = new Proxy(state.nativeWorker, {
      construct(target, args) {
        const worker = Reflect.construct(target, args);
        state.receiveWorkers.push(worker);
        return worker;
      },
    });
    global.Worker = state.workerProxy;
  }

  function stopReceiveWorkers() {
    for (const worker of state.receiveWorkers) {
      try {
        worker.terminate();
      } catch (error) {
        console.warn('[onesend-cimbar] stop worker error', error);
      }
    }
    state.receiveWorkers = [];
    if (state.workerProxy && global.Worker === state.workerProxy) {
      global.Worker = state.nativeWorker;
    }
    state.workerProxy = null;
    state.nativeWorker = null;
  }

  function initializeReceiveVideo() {
    if (!state.receiveStarted || state.receiveVideoStarted) {
      return;
    }
    state.receiveVideoStarted = true;
    try {
      const video = document.getElementById('video');
      if (!video) {
        throw new Error('接收页面 video 元素未找到。');
      }
      video.autoplay = true;
      video.playsInline = true;
      video.muted = true;
      if (!video.requestVideoFrameCallback) {
        video.requestVideoFrameCallback = function (callback) {
          return global.requestAnimationFrame(function (timestamp) {
            callback(timestamp, { presentedFrames: 0 });
          });
        };
      }
      global.Recv.init_video(video);
    } catch (error) {
      state.receiveVideoStarted = false;
      fail('camera', error);
    }
  }

  function bootReceive() {
    try {
      if (!global.Recv || !global.Zstd) {
        throw new Error('接收页面上游 worker/解码器未加载。');
      }
      installReceiveHooks();
      global.Module = global.Module || {};
      global.Module.onRuntimeInitialized = function () {
        state.receiveWasmReady = true;
        // Match sender mode B (68). Auto (0) also works, but locking avoids
        // wasteful mode cycling on empty frames.
        if (typeof global.Recv.setMode === 'function') {
          global.Recv.setMode(68);
        }
        bridge('receive-ready', { decoder: 'upstream-worker', mode: 'B' });
        initializeReceiveVideo();
      };
    } catch (error) {
      fail('receive-init', error);
    }
  }

  function startReceive() {
    if (state.receiveStarted) {
      return;
    }
    state.receiveStarted = true;
    state.receiveStartedAt = performance.now();
    state.receiveVideoStarted = false;
    try {
      // Camera access is deliberately reached only from this native-button
      // initiated call. The decoder workers are also created at this point.
      installReceiveWorkerTracking();
      global.Recv.init_ww(4);
      if (typeof global.Recv.setMode === 'function') {
        global.Recv.setMode(68);
      }
      bridge('receive-started', { mode: 'B' });
      initializeReceiveVideo();
    } catch (error) {
      state.receiveStarted = false;
      fail('camera', error);
    }
  }

  function stopReceive() {
    state.receiveGeneration += 1;
    try {
      const video = document.getElementById('video');
      if (video && video.srcObject && video.srcObject.getTracks) {
        video.srcObject.getTracks().forEach(function (track) { track.stop(); });
        video.srcObject = null;
      }
      if (video && typeof video.pause === 'function') video.pause();
    } catch (error) {
      console.warn('[onesend-cimbar] stop camera error', error);
    }
    state.receiveStarted = false;
    state.receiveVideoStarted = false;
    state.receiveWasmReady = false;
    state.receiveStartedAt = 0;
    stopReceiveWorkers();
  }

  function stopSend() {
    state.sendGeneration += 1;
    state.sendInFlight = false;
    state.sendReady = false;
    state.sendPaused = false;
    state.pendingAnimationFrames = [];
    try {
      if (global.Main && typeof global.Main.togglePause === 'function') {
        global.Main.togglePause(true);
      }
    } catch (error) {
      console.warn('[onesend-cimbar] stop sender error', error);
    }
    if (state.animationFrameInstalled &&
        global.requestAnimationFrame === state.pausedRequestAnimationFrame) {
      global.requestAnimationFrame = state.nativeRequestAnimationFrame;
    }
    state.animationFrameInstalled = false;
    state.nativeRequestAnimationFrame = null;
    state.pausedRequestAnimationFrame = null;
  }

  function chooseFile() {
    const input = document.getElementById('file_input');
    if (!input) {
      fail('send', new Error('发送文件入口不可用。'));
      return;
    }
    input.value = '';
    input.click();
  }

  function stop() {
    stopReceive();
    stopSend();
  }

  global.OneSendCimbar = {
    bootSend: bootSend,
    sendFile: function (file) {
      if (!state.sendReady) {
        fail('send', new Error('编码器尚未就绪。'));
        return;
      }
      encodeFile(file).catch(function (error) {
        fail('send', error);
      });
    },
    chooseFile: chooseFile,
    togglePause: togglePause,
    bootReceive: bootReceive,
    startReceive: startReceive,
    stopReceive: stopReceive,
    stop: stop,
  };
})(window);
