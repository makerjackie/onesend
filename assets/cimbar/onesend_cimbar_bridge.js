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
    receivePaused: false,
    receiveVideoStarted: false,
    receiveWasmReady: false,
    receiveSession: 0,
    receiveStartedAt: 0,
    receiveWorkers: [],
    receiveWorkerBlobUrls: [],
    receiveWorkersExpected: 0,
    receiveWorkersReady: 0,
    receiveWorkersReadyResolve: null,
    receiveWorkersReadyReject: null,
    receiveGeneration: 0,
    nativeWorker: null,
    workerProxy: null,
    pendingAnimationFrames: [],
    pausedRequestAnimationFrame: null,
    cameraCaptureInstalled: false,
    nativeFrames: false,
    nextNativeWorker: 0,
    nativeWorkersBusy: [],
    nativeFeedAnnounced: false,
    decodedOpticalBytes: 0,
    lastDecodeProgressBridgeAt: 0,
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
        const progress = report.map(function (value) { return Number(value); });
        const now = performance.now();
        const terminal = progress.some(function (value) {
          return Number.isFinite(value) && value >= 1;
        });
        // Worker reports can arrive in bursts and out of order. Flutter owns
        // the monotonic progress surface, so cap bridge/UI churn at ~5 Hz while
        // always forwarding completion immediately.
        if (terminal || state.lastDecodeProgressBridgeAt === 0 ||
            now - state.lastDecodeProgressBridgeAt >= 200) {
          state.lastDecodeProgressBridgeAt = now;
          bridge('decode-progress', {
            progress: progress,
            mode: 'B',
            decodedBytes: state.decodedOpticalBytes,
            elapsedMs: state.receiveStartedAt > 0
              ? Math.max(0, now - state.receiveStartedAt)
              : 0,
          });
        }
      }
      return originalProgress.apply(this, arguments);
    };

    const originalError = global.Recv.set_error;
    global.Recv.set_error = function (message) {
      const text = String(message || '');
      // Upstream reports getUserMedia failures through set_error; keep the
      // phase accurate so the UI does not blame "decode" for camera issues.
      const phase = /camera|mediaDevices|getUserMedia|permission/i.test(text)
        ? 'camera'
        : 'decode';
      bridge('error', { phase: phase, message: text });
      return originalError.apply(this, arguments);
    };

    const originalRestartPausedCamera = global.Recv.restart_paused_camera;
    if (typeof originalRestartPausedCamera === 'function') {
      global.Recv.restart_paused_camera = function () {
        if (!state.receiveStarted || state.receivePaused) return;
        return originalRestartPausedCamera.apply(this, arguments);
      };
    }

    const originalDecode = global.Recv.on_decode;
    global.Recv.on_decode = function (workerId, data) {
      const nativeWorkerId = Number(workerId);
      if (Number.isInteger(nativeWorkerId) && nativeWorkerId >= 0 &&
          nativeWorkerId < state.nativeWorkersBusy.length) {
        state.nativeWorkersBusy[nativeWorkerId] = false;
      }
      if (data && data.type === 'startWasm' && data.error === 'no wasm') {
        // A frame reached this worker during its asynchronous WASM startup.
        // It is a transient readiness signal, not a corrupt transfer.
        return;
      }
      if (data && data.error) {
        fail('decode', data.res || 'worker decoder error');
      } else if (data && data.failed_extract) {
        bridge('decode-progress', { phase: 'scan', worker: workerId });
      } else if (data && data.buff && Number(data.buff.byteLength) > 0) {
        state.decodedOpticalBytes += Number(data.buff.byteLength);
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

  /**
   * OneSend shells live at assets/cimbar/*.html while unmodified upstream
   * workers live at assets/cimbar/upstream/*.js. Upstream code constructs
   * `new Worker('recv-worker….js')` (same-dir as the page), which 404s and
   * was previously surfaced as a fake camera/permission error.
   */
  function resolveUpstreamWorkerUrl(scriptUrl) {
    if (typeof scriptUrl !== 'string') return scriptUrl;
    if (
      scriptUrl.indexOf('://') >= 0 ||
      scriptUrl.indexOf('/') >= 0 ||
      scriptUrl.indexOf('blob:') === 0
    ) {
      return scriptUrl;
    }
    return 'upstream/' + scriptUrl;
  }

  function installReceiveWorkerTracking() {
    if (state.workerProxy || typeof global.Worker !== 'function') {
      return;
    }
    state.nativeWorker = global.Worker;
    state.workerProxy = new Proxy(state.nativeWorker, {
      construct(target, args) {
        const receiveGeneration = state.receiveGeneration;
        const nextArgs = args.slice();
        var inlineWorker = false;
        if (nextArgs.length > 0) {
          const requestedUrl = nextArgs[0];
          const inlineSource = global.OneSendCimbarInlineReceiveWorkerSource;
          if (typeof requestedUrl === 'string' &&
              requestedUrl.indexOf('recv-worker.') >= 0 &&
              typeof inlineSource === 'string' && inlineSource.length > 0) {
            const blobUrl = global.URL.createObjectURL(
              new Blob([inlineSource], { type: 'text/javascript' }),
            );
            state.receiveWorkerBlobUrls.push(blobUrl);
            nextArgs[0] = blobUrl;
            inlineWorker = true;
          } else {
            nextArgs[0] = resolveUpstreamWorkerUrl(requestedUrl);
          }
        }
        const worker = Reflect.construct(target, nextArgs);
        state.receiveWorkers.push(worker);
        var workerReady = false;
        worker.addEventListener('message', function (event) {
          if (workerReady ||
              !event || !event.data || !event.data.ready ||
              receiveGeneration !== state.receiveGeneration) {
            return;
          }
          workerReady = true;
          state.receiveWorkersReady += 1;
          if (state.receiveWorkersReady >= state.receiveWorkersExpected &&
              typeof state.receiveWorkersReadyResolve === 'function') {
            const resolve = state.receiveWorkersReadyResolve;
            state.receiveWorkersReadyResolve = null;
            state.receiveWorkersReadyReject = null;
            resolve();
          }
        });
        worker.addEventListener('error', function (event) {
          // A worker can report its final error asynchronously after a mode
          // switch or teardown. Never let that stale event fail a new session.
          if (!state.receiveStarted ||
              receiveGeneration !== state.receiveGeneration) {
            return;
          }
          const error = new Error(
            '解码 worker 加载失败: ' +
              (event && event.message ? event.message : nextArgs[0]),
          );
          if (typeof state.receiveWorkersReadyReject === 'function') {
            const reject = state.receiveWorkersReadyReject;
            state.receiveWorkersReadyResolve = null;
            state.receiveWorkersReadyReject = null;
            reject(error);
          } else {
            fail('decode', error);
          }
        });
        if (inlineWorker) {
          const wasm = global.Module && global.Module.wasmBinary;
          if (!(wasm instanceof Uint8Array) || wasm.length === 0) {
            worker.terminate();
            throw new Error('离线解码 worker 缺少 WASM 字节。');
          }
          const copy = wasm.slice();
          worker.postMessage(
            { type: 'onesend-wasm-init', wasmBinary: copy.buffer },
            [copy.buffer],
          );
        }
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
    for (const blobUrl of state.receiveWorkerBlobUrls) {
      try {
        global.URL.revokeObjectURL(blobUrl);
      } catch (error) {}
    }
    state.receiveWorkerBlobUrls = [];
    state.receiveWorkersExpected = 0;
    state.receiveWorkersReady = 0;
    state.receiveWorkersReadyResolve = null;
    state.receiveWorkersReadyReject = null;
    if (state.workerProxy && global.Worker === state.workerProxy) {
      global.Worker = state.nativeWorker;
    }
    state.workerProxy = null;
    state.nativeWorker = null;
  }

  function prepareReceiveWorkers(count, receiveGeneration) {
    state.receiveWorkersExpected = count;
    state.receiveWorkersReady = 0;
    return new Promise(function (resolve, reject) {
      state.receiveWorkersReadyResolve = resolve;
      state.receiveWorkersReadyReject = reject;
      global.setTimeout(function () {
        if (receiveGeneration !== state.receiveGeneration ||
            !state.receiveStarted ||
            state.receiveWorkersReady >= count) {
          return;
        }
        state.receiveWorkersReadyResolve = null;
        state.receiveWorkersReadyReject = null;
        reject(new Error('解码 worker 启动超时。'));
      }, 5000);
    });
  }

  function ensureVideoFrameCallback(video) {
    if (video.requestVideoFrameCallback) return;
    video.requestVideoFrameCallback = function (callback) {
      return global.requestAnimationFrame(function (timestamp) {
        callback(timestamp, { presentedFrames: 0 });
      });
    };
  }

  /**
   * Soften getUserMedia and wrap Recv.init_video while still calling the
   * original (it owns private `_video` used by on_frame).
   */
  function installMobileCameraCapture() {
    if (state.cameraCaptureInstalled || !global.Recv) return;
    if (!global.navigator ||
        !global.navigator.mediaDevices ||
        typeof global.navigator.mediaDevices.getUserMedia !== 'function') {
      return;
    }
    state.cameraCaptureInstalled = true;

    const originalGum = global.navigator.mediaDevices.getUserMedia.bind(
      global.navigator.mediaDevices,
    );
    global.navigator.mediaDevices.getUserMedia = function () {
      const attempts = [
        {
          audio: false,
          video: {
            facingMode: { ideal: 'environment' },
            width: { ideal: 1280 },
            height: { ideal: 720 },
          },
        },
        { audio: false, video: { facingMode: 'environment' } },
        { audio: false, video: true },
      ];
      function tryAt(i) {
        return originalGum(attempts[i]).catch(function (err) {
          if (i + 1 < attempts.length) return tryAt(i + 1);
          throw err;
        });
      }
      return tryAt(0);
    };

    const originalInitVideo = global.Recv.init_video.bind(global.Recv);
    global.Recv.init_video = function (video) {
      if (video) {
        video.autoplay = true;
        video.muted = true;
        video.playsInline = true;
        video.setAttribute('playsinline', 'true');
        video.setAttribute('webkit-playsinline', 'true');
        video.setAttribute('muted', 'true');
        video.style.width = '100%';
        video.style.height = '100%';
        video.style.objectFit = 'cover';
        ensureVideoFrameCallback(video);
      }
      // Patch set_error once around the open so success can be inferred if
      // play starts without an error callback.
      const previousSetError = global.Recv.set_error;
      var opened = false;
      global.Recv.set_error = function (message) {
        if (!opened) {
          fail('camera', new Error(String(message || 'camera error')));
        }
        if (typeof previousSetError === 'function') {
          return previousSetError.apply(this, arguments);
        }
      };
      try {
        originalInitVideo(video);
        // Upstream does not emit success; poll for live tracks.
        var tries = 0;
        var timer = global.setInterval(function () {
          tries += 1;
          var stream = video && video.srcObject;
          var live = stream && stream.getVideoTracks &&
            stream.getVideoTracks().some(function (t) {
              return t.readyState === 'live';
            });
          if (live || (video && video.videoWidth > 0)) {
            opened = true;
            global.clearInterval(timer);
            global.Recv.set_error = previousSetError;
            bridge('receive-camera-live', {
              width: video.videoWidth || 0,
              height: video.videoHeight || 0,
            });
            try {
              var playResult = video.play();
              if (playResult && typeof playResult.catch === 'function') {
                playResult.catch(function () {});
              }
            } catch (e) {}
          } else if (tries >= 40) {
            global.clearInterval(timer);
            global.Recv.set_error = previousSetError;
            if (!opened) {
              fail('camera', new Error('摄像头预览超时（黑屏）。'));
            }
          }
        }, 100);
      } catch (error) {
        global.Recv.set_error = previousSetError;
        fail('camera', error);
      }
    };
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
      installMobileCameraCapture();
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
      installMobileCameraCapture();
      global.Module = global.Module || {};
      const finishBoot = function () {
        if (state.receiveWasmReady) {
          // Idempotently replay readiness. Flutter may attach its JavaScript
          // channel just after a cached WebView finishes Emscripten startup.
          bridge('receive-ready', { decoder: 'upstream-worker', mode: 'B' });
          return;
        }
        try {
          // Match sender mode B (68). Auto (0) also works, but locking avoids
          // wasteful mode cycling on empty frames.
          if (typeof global.Recv.setMode === 'function') {
            global.Recv.setMode(68);
          }
          state.receiveWasmReady = true;
          bridge('receive-ready', { decoder: 'upstream-worker', mode: 'B' });
          // Only open the camera after Flutter/native startReceive has armed us.
          initializeReceiveVideo();
        } catch (error) {
          state.receiveWasmReady = false;
          fail('receive-init', error);
        }
      };
      global.Module.onRuntimeInitialized = finishBoot;
      // A cached/reused WebView can finish Emscripten before the wrapper is
      // re-armed. Detect that state instead of waiting forever for a callback
      // that has already happened.
      if (
        global.Module.calledRun === true &&
        typeof global.Module._cimbard_get_bufsize === 'function'
      ) {
        global.setTimeout(finishBoot, 0);
      }
    } catch (error) {
      fail('receive-init', error);
    }
  }

  function startReceive(options) {
    if (state.receiveStarted) {
      return;
    }
    options = options || {};
    // nativeFrames: Flutter owns the camera preview (mobile). WebView only
    // runs WASM workers — avoids black file:// getUserMedia sessions.
    state.nativeFrames = options.nativeFrames === true;
    state.receiveStarted = true;
    state.receivePaused = false;
    state.receiveStartedAt = performance.now();
    state.receiveVideoStarted = false;
    state.nextNativeWorker = 0;
    state.nativeWorkersBusy = [];
    state.nativeFeedAnnounced = false;
    state.decodedOpticalBytes = 0;
    state.lastDecodeProgressBridgeAt = 0;
    try {
      installReceiveWorkerTracking();
      const receiveGeneration = state.receiveGeneration;
      const workerCount = 4;
      state.nativeWorkersBusy = new Array(workerCount).fill(false);
      const workersReady = prepareReceiveWorkers(
        workerCount,
        receiveGeneration,
      );
      global.Recv.init_ww(workerCount);
      if (typeof global.Recv.setMode === 'function') {
        global.Recv.setMode(68);
      }
      workersReady.then(function () {
        if (!state.receiveStarted ||
            receiveGeneration !== state.receiveGeneration) {
          return;
        }
        bridge('receive-started', {
          mode: 'B',
          nativeFrames: state.nativeFrames,
        });
        if (state.nativeFrames) {
          state.receiveVideoStarted = true;
          bridge('receive-camera-live', { native: true });
        } else {
          initializeReceiveVideo();
        }
      }).catch(function (error) {
        if (!state.receiveStarted ||
            receiveGeneration !== state.receiveGeneration) {
          return;
        }
        state.receiveStarted = false;
        fail('decode', error);
      });
    } catch (error) {
      state.receiveStarted = false;
      state.nativeFrames = false;
      const text = error && error.message ? String(error.message) : String(error);
      const phase = /camera|mediaDevices|getUserMedia|permission|NotAllowed|NotFound/i.test(
        text,
      )
        ? 'camera'
        : 'decode';
      fail(phase, error);
    }
  }

  function base64ToBytes(base64) {
    const binary = global.atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i += 1) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
  }

  /**
   * Ingest one RGBA frame from the Flutter camera plugin.
   * width/height must match the pixel buffer (width*height*4 bytes).
   */
  function feedNativeFrame(width, height, rgbaBase64) {
    if (!state.receiveStarted || state.receivePaused || !state.nativeFrames) {
      return false;
    }
    if (!state.receiveWorkers || state.receiveWorkers.length === 0) return false;
    const w = Number(width) | 0;
    const h = Number(height) | 0;
    if (w <= 0 || h <= 0 || typeof rgbaBase64 !== 'string' || !rgbaBase64) {
      return false;
    }
    try {
      const pixels = base64ToBytes(rgbaBase64);
      if (pixels.length < w * h * 4) return false;
      let index = -1;
      for (let offset = 0; offset < state.receiveWorkers.length; offset += 1) {
        const candidate =
          (state.nextNativeWorker + offset) % state.receiveWorkers.length;
        if (!state.nativeWorkersBusy[candidate]) {
          index = candidate;
          break;
        }
      }
      // Never queue stale camera frames behind a slow decode. Fountain coding
      // tolerates dropped frames; a growing worker queue hurts both stability
      // and effective throughput.
      if (index < 0) return false;
      state.nextNativeWorker = (index + 1) % state.receiveWorkers.length;
      const worker = state.receiveWorkers[index];
      // Copy into a transferable buffer for the worker.
      const copy = pixels.slice(0, w * h * 4);
      worker.postMessage(
        {
          type: 'proc',
          pixels: copy,
          format: 'RGBA',
          width: w,
          height: h,
          mode: 68,
        },
        [copy.buffer],
      );
      state.nativeWorkersBusy[index] = true;
      // First successful feed: confirm live path (idempotent for Flutter status).
      if (!state.nativeFeedAnnounced) {
        state.nativeFeedAnnounced = true;
        bridge('receive-camera-live', {
          native: true,
          width: w,
          height: h,
          fed: true,
        });
      }
      return true;
    } catch (error) {
      console.warn('[onesend-cimbar] feedNativeFrame failed', error);
      return false;
    }
  }

  function setReceivePaused(paused) {
    if (!state.receiveStarted) return false;
    state.receivePaused = Boolean(paused);
    if (state.nativeFrames) {
      if (!state.receivePaused) {
        bridge('receive-camera-live', { native: true, resumed: true });
      }
      return true;
    }

    try {
      const video = document.getElementById('video');
      if (!video) throw new Error('接收页面 video 元素未找到。');
      if (state.receivePaused) {
        video.pause();
      } else {
        const playResult = video.play();
        if (playResult && typeof playResult.then === 'function') {
          playResult.then(function () {
            bridge('receive-camera-live', {
              width: video.videoWidth || 0,
              height: video.videoHeight || 0,
              resumed: true,
            });
          }).catch(function (error) {
            fail('camera', error);
          });
        } else {
          bridge('receive-camera-live', { resumed: true });
        }
      }
      return true;
    } catch (error) {
      fail('camera', error);
      return false;
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
    state.receivePaused = false;
    state.receiveVideoStarted = false;
    state.receiveStartedAt = 0;
    state.nativeFrames = false;
    state.nextNativeWorker = 0;
    state.nativeWorkersBusy = [];
    state.nativeFeedAnnounced = false;
    state.decodedOpticalBytes = 0;
    state.lastDecodeProgressBridgeAt = 0;
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
    setReceivePaused: setReceivePaused,
    feedNativeFrame: feedNativeFrame,
    stopReceive: stopReceive,
    stop: stop,
  };
})(window);
