"use client";

import { useEffect, useRef, useState } from "react";

import styles from "./cimbar.module.css";

const SEND_WORKER_URL = "/cimbar/node_modules/cimbar-send-bootstrap.js";
const RECEIVE_WORKER_URL = "/cimbar/node_modules/cimbar-receive-worker.js";
const MAX_INPUT_BYTES = 32 * 1024 * 1024;
/**
 * Mode Bm (67) — libcimbar's compact config for broader camera reliability.
 * ~70% of mode B peak speed, but far fewer empty optical frames in practice.
 * Encode + decode must use the same mode.
 */
const CIMBAR_MODE = 67;
const CIMBAR_MODE_LABEL = "Bm";
/**
 * Optical display rate. Color cells need long dwell on LCD for phone cameras;
 * 3 fps is much more reliable than 8–15 for real scans (upstream default is 15).
 * Theoretical KB/s drops; empty-frame rate drops far more.
 */
const CIMBAR_DISPLAY_FPS = 3;
/** Cap camera samples so transitional video frames do not dominate empty stats. */
const RECEIVE_CAPTURE_INTERVAL_MS = 120;
/**
 * Bitmap size == CSS size (1:1). CSS-downscaling color cells is the same
 * class of bug that made web QR unscannable. Prefer large on-screen cells.
 */
function resolveCimbarCanvasSize() {
  if (typeof window === "undefined") return 720;
  const limit = Math.min(window.innerWidth * 0.92, window.innerHeight * 0.58);
  return Math.max(640, Math.min(1024, Math.floor(limit)));
}

function guessMimeFromName(name: string, fallback = "application/octet-stream") {
  const lower = name.toLowerCase();
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".gif")) return "image/gif";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".svg")) return "image/svg+xml";
  if (lower.endsWith(".mp4")) return "video/mp4";
  if (lower.endsWith(".webm")) return "video/webm";
  if (lower.endsWith(".mp3")) return "audio/mpeg";
  if (lower.endsWith(".wav")) return "audio/wav";
  if (lower.endsWith(".pdf")) return "application/pdf";
  if (lower.endsWith(".json")) return "application/json";
  if (lower.endsWith(".txt") || lower.endsWith(".md") || lower.endsWith(".csv")) {
    return "text/plain";
  }
  if (lower.endsWith(".html") || lower.endsWith(".htm")) return "text/html";
  return fallback;
}

type View = "send" | "receive";
type SenderState = "idle" | "loading" | "sending" | "stopped" | "error";
type ReceiverState = "idle" | "starting" | "receiving" | "complete" | "error";

type ReceivedFile = {
  name: string;
  bytes: Uint8Array;
  mimeType: string;
  verified: boolean;
};

type CapturedFrame = {
  pixels: ArrayBuffer;
  width: number;
  height: number;
  format: "RGBA";
};

type VideoFrameLike = {
  displayWidth: number;
  displayHeight: number;
  allocationSize: (options: { format: "RGBA" }) => number;
  copyTo: (
    destination: Uint8Array,
    options: { format: "RGBA" },
  ) => Promise<unknown>;
  close: () => void;
};

type VideoFrameConstructor = new (source: HTMLVideoElement) => VideoFrameLike;

function formatBytes(bytes: number) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function safeFilename(name: string) {
  const cleaned = name
    .replace(/[\\/:*?"<>|\u0000-\u001f]/g, "-")
    .trim();
  return cleaned || "cimbar-file.bin";
}

function resolvedMime(file: ReceivedFile) {
  const mime = (file.mimeType || "").toLowerCase();
  if (mime && mime !== "application/octet-stream") return mime;
  return guessMimeFromName(file.name, mime || "application/octet-stream");
}

function fileBlob(file: ReceivedFile) {
  const copy = new Uint8Array(file.bytes.byteLength);
  copy.set(file.bytes);
  return new Blob([copy], { type: resolvedMime(file) });
}

function downloadFile(file: ReceivedFile) {
  if (file.verified !== true) return;
  const url = URL.createObjectURL(fileBlob(file));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = file.name;
  anchor.rel = "noreferrer";
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 60_000);
}

function isViewableMime(mime: string) {
  return (
    mime.startsWith("image/") ||
    mime.startsWith("video/") ||
    mime.startsWith("audio/") ||
    mime.startsWith("text/") ||
    mime === "application/pdf" ||
    mime === "application/json"
  );
}

/** Open viewable types in a new tab; fall back to download for others. */
function openReceivedInBrowser(file: ReceivedFile) {
  if (file.verified !== true) return;
  const mime = resolvedMime(file);
  const url = URL.createObjectURL(fileBlob(file));
  if (isViewableMime(mime)) {
    // Prefer <a target=_blank> — slightly less likely to be blocked than window.open
    // after an async worker completion callback.
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.target = "_blank";
    anchor.rel = "noopener noreferrer";
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    window.setTimeout(() => URL.revokeObjectURL(url), 180_000);
    return;
  }
  downloadFile(file);
  window.setTimeout(() => URL.revokeObjectURL(url), 60_000);
}

async function sha256(bytes: Uint8Array) {
  if (!globalThis.crypto?.subtle) return null;
  const digest = await globalThis.crypto.subtle.digest(
    "SHA-256",
    bytes.slice().buffer as ArrayBuffer,
  );
  return Array.from(new Uint8Array(digest), (value) =>
    value.toString(16).padStart(2, "0"),
  ).join("");
}

function describeError(error: unknown) {
  if (error instanceof Error && error.message) return error.message;
  return "浏览器无法完成这次本地实验。";
}

function tabClass(active: boolean) {
  return `${styles.viewTab}${active ? ` ${styles.viewTabActive}` : ""}`;
}

type CimbarTransferProps = {
  /** When set, only this direction is shown (for embedding in the main web transfer UI). */
  direction?: View;
  /** Hide local send/receive tabs; parent already owns navigation. */
  embedded?: boolean;
};

export function CimbarTransfer({
  direction,
  embedded = false,
}: CimbarTransferProps = {}) {
  const [view, setView] = useState<View>(direction ?? "send");
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [senderState, setSenderState] = useState<SenderState>("idle");
  const [senderFrames, setSenderFrames] = useState(0);
  const [senderError, setSenderError] = useState<string | null>(null);
  const [receiverState, setReceiverState] = useState<ReceiverState>("idle");
  const [decodedFrames, setDecodedFrames] = useState(0);
  const [receiverProgress, setReceiverProgress] = useState(0);
  const [receiverError, setReceiverError] = useState<string | null>(null);
  const [receivedFile, setReceivedFile] = useState<ReceivedFile | null>(null);
  const [verification, setVerification] = useState<string | null>(null);
  const [canvasSize] = useState(() => resolveCimbarCanvasSize());
  const [scanStats, setScanStats] = useState({ noData: 0, decoded: 0 });
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);

  useEffect(() => {
    if (!direction || direction === view) return;
    if (direction === "send") {
      stopReceiverResources();
      window.setTimeout(() => {
        setReceiverState((current) => (current === "complete" ? current : "idle"));
        setView(direction);
      }, 0);
    } else {
      stopSender();
      window.setTimeout(() => setView(direction), 0);
    }
    // Intentionally only re-run when the parent direction changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [direction]);

  const senderCanvasRef = useRef<HTMLCanvasElement>(null);
  const senderWorkerRef = useRef<Worker | null>(null);
  const senderReadyRef = useRef(false);
  const pendingFileRef = useRef<File | null>(null);

  const receiverVideoRef = useRef<HTMLVideoElement>(null);
  const captureCanvasRef = useRef<HTMLCanvasElement>(null);
  const receiverWorkerRef = useRef<Worker | null>(null);
  const receiverWorkerReadyRef = useRef(false);
  const receiverActiveRef = useRef(false);
  const receiverFramesInFlightRef = useRef(0);
  const receiverTimerRef = useRef<number | null>(null);
  const cameraStreamRef = useRef<MediaStream | null>(null);
  const lastCaptureAtRef = useRef(0);
  const previewUrlRef = useRef<string | null>(null);

  function revokePreviewUrl() {
    if (previewUrlRef.current) {
      URL.revokeObjectURL(previewUrlRef.current);
      previewUrlRef.current = null;
    }
    setPreviewUrl(null);
  }

  function presentReceivedFile(file: ReceivedFile) {
    setReceivedFile(file);
    setReceiverProgress(1);
    setReceiverState("complete");
    revokePreviewUrl();
    if (isViewableMime(resolvedMime(file))) {
      const url = URL.createObjectURL(fileBlob(file));
      previewUrlRef.current = url;
      setPreviewUrl(url);
    }
    // Best-effort auto open; popup blockers may still require the button.
    try {
      openReceivedInBrowser(file);
    } catch {
      // Button remains available.
    }
  }

  function stopReceiverResources() {
    receiverActiveRef.current = false;
    if (receiverTimerRef.current !== null) {
      window.clearTimeout(receiverTimerRef.current);
      receiverTimerRef.current = null;
    }
    cameraStreamRef.current?.getTracks().forEach((track) => track.stop());
    cameraStreamRef.current = null;
    const video = receiverVideoRef.current;
    if (video) {
      video.pause();
      video.srcObject = null;
    }
    receiverWorkerRef.current?.terminate();
    receiverWorkerRef.current = null;
    receiverWorkerReadyRef.current = false;
    receiverFramesInFlightRef.current = 0;
  }

  useEffect(() => {
    return () => {
      senderWorkerRef.current?.terminate();
      stopReceiverResources();
      revokePreviewUrl();
    };
  }, []);

  function postSenderFile(file: File) {
    pendingFileRef.current = file;
    const worker = senderWorkerRef.current;
    if (!worker || !senderReadyRef.current) return;
    setSenderState("sending");
    setSenderFrames(0);
    setSenderError(null);
    worker.postMessage({ type: "load", file });
  }

  function ensureSenderWorker(file: File) {
    pendingFileRef.current = file;
    if (senderWorkerRef.current) {
      if (senderReadyRef.current) postSenderFile(file);
      else setSenderState("loading");
      return;
    }

    const canvas = senderCanvasRef.current;
    if (!canvas || typeof canvas.transferControlToOffscreen !== "function") {
      setSenderState("error");
      setSenderError("当前浏览器不支持 OffscreenCanvas，无法运行本地编码器。");
      return;
    }

    setSenderState("loading");
    const worker = new Worker(SEND_WORKER_URL, {
      name: "onesend-cimbar-sender",
      type: "classic",
    });
    senderWorkerRef.current = worker;
    worker.onmessage = (event: MessageEvent) => {
      const data = event.data || {};
      if (data.type === "frame") {
        // Count is already throttled in the worker; still avoid layout thrash.
        const next = Number(data.count) || 0;
        setSenderFrames((prev) => (prev === next ? prev : next));
        return;
      }
      if (data.type === "error") {
        setSenderState("error");
        setSenderError(data.message || "编码 worker 出错。");
        return;
      }
      if (data.fun === "startWasm") {
        const ready = data.args?.[0] === true;
        senderReadyRef.current = ready;
        if (!ready) {
          setSenderState("error");
          setSenderError("本地 WASM 编码器未能启动。");
          return;
        }
        worker.postMessage({ fun: "setMode", args: [CIMBAR_MODE] });
        worker.postMessage({ fun: "setFPS", args: [CIMBAR_DISPLAY_FPS] });
        if (pendingFileRef.current) postSenderFile(pendingFileRef.current);
      }
    };
    worker.onerror = (event) => {
      setSenderState("error");
      setSenderError(event.message || "编码 worker 无法加载。");
    };

    const offscreen = canvas.transferControlToOffscreen();
    worker.postMessage(
      { fun: "init_window", args: [offscreen] },
      [offscreen],
    );
  }

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    if (file.size > MAX_INPUT_BYTES) {
      setSenderState("error");
      setSenderError("这个浏览器实验目前支持不超过 32 MB 的文件。");
      return;
    }
    setSelectedFile(file);
    ensureSenderWorker(file);
  }

  function stopSender() {
    pendingFileRef.current = null;
    senderWorkerRef.current?.postMessage({ type: "stop" });
    setSenderState((state) =>
      state === "loading" || state === "sending" ? "stopped" : state,
    );
  }

  function changeView(nextView: View) {
    if (nextView === "send") {
      stopReceiverResources();
      if (receiverState !== "complete") setReceiverState("idle");
    }
    if (nextView === "receive") {
      stopSender();
    }
    setView(nextView);
  }

  async function captureVideoFrame(video: HTMLVideoElement): Promise<CapturedFrame> {
    const VideoFrameClass = (globalThis as unknown as {
      VideoFrame?: VideoFrameConstructor;
    }).VideoFrame;

    if (VideoFrameClass && video.videoWidth > 0 && video.videoHeight > 0) {
      const frame = new VideoFrameClass(video);
      try {
        const width = frame.displayWidth;
        const height = frame.displayHeight;
        const size = frame.allocationSize({ format: "RGBA" });
        if (size === width * height * 4) {
          const pixels = new Uint8Array(size);
          await frame.copyTo(pixels, { format: "RGBA" });
          return { pixels: pixels.buffer, width, height, format: "RGBA" };
        }
      } finally {
        frame.close();
      }
    }

    const canvas = captureCanvasRef.current;
    if (!canvas || video.videoWidth <= 0 || video.videoHeight <= 0) {
      throw new Error("相机画面还没有准备好。");
    }
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const context = canvas.getContext("2d", { willReadFrequently: true });
    if (!context) throw new Error("无法读取相机画面。");
    context.drawImage(video, 0, 0, canvas.width, canvas.height);
    const image = context.getImageData(0, 0, canvas.width, canvas.height);
    return {
      pixels: new Uint8Array(image.data).buffer,
      width: canvas.width,
      height: canvas.height,
      format: "RGBA",
    };
  }

  function scheduleVideoFrame() {
    if (!receiverActiveRef.current) return;
    // Prefer a paced timer over raw camera FPS. Full-rate rVFC (~24–30 Hz)
    // samples transitional LCD frames and inflates empty-frame counts to ~90%.
    receiverTimerRef.current = window.setTimeout(() => {
      void sendVideoFrame();
    }, RECEIVE_CAPTURE_INTERVAL_MS);
  }

  async function sendVideoFrame() {
    const video = receiverVideoRef.current;
    const worker = receiverWorkerRef.current;
    if (!receiverActiveRef.current || !video || !worker) return;

    try {
      const now = performance.now();
      const dwellOk = now - lastCaptureAtRef.current >= RECEIVE_CAPTURE_INTERVAL_MS;
      // Only one decode in flight — backlog of stale frames wastes CPU and
      // reports empty results from mid-transition captures.
      if (
        dwellOk &&
        receiverFramesInFlightRef.current < 1 &&
        receiverWorkerReadyRef.current &&
        video.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA
      ) {
        lastCaptureAtRef.current = now;
        const captured = await captureVideoFrame(video);
        if (!receiverActiveRef.current) return;
        receiverFramesInFlightRef.current += 1;
        worker.postMessage(
          { type: "frame", ...captured },
          [captured.pixels],
        );
      }
    } catch (error) {
      stopReceiverResources();
      setReceiverState("error");
      setReceiverError(describeError(error));
      return;
    }
    scheduleVideoFrame();
  }

  async function startReceiver() {
    if (receiverState === "starting" || receiverState === "receiving") return;
    if (!navigator.mediaDevices?.getUserMedia) {
      setReceiverState("error");
      setReceiverError("当前浏览器没有可用的 camera API，请使用 HTTPS 或 localhost。");
      return;
    }

    stopReceiverResources();
    revokePreviewUrl();
    setReceiverState("starting");
    setReceiverError(null);
    setReceivedFile(null);
    setVerification(null);
    setDecodedFrames(0);
    setReceiverProgress(0);
    setScanStats({ noData: 0, decoded: 0 });
    lastCaptureAtRef.current = 0;

    const worker = new Worker(RECEIVE_WORKER_URL, {
      name: "onesend-cimbar-receiver",
      type: "classic",
    });
    receiverWorkerRef.current = worker;
    const workerReady = new Promise<void>((resolve, reject) => {
      worker.onmessage = (event: MessageEvent) => {
        const data = event.data || {};
        if (data.type === "ready") {
          receiverWorkerReadyRef.current = true;
          resolve();
          return;
        }
        if (data.frameDone) {
          receiverFramesInFlightRef.current = Math.max(
            0,
            receiverFramesInFlightRef.current - 1,
          );
        }
        if (data.type === "frame") {
          if (data.result === "decoded") {
            setDecodedFrames((count) => count + 1);
            setScanStats((stats) => ({
              ...stats,
              decoded: stats.decoded + 1,
            }));
          } else if (data.result === "no-data") {
            setScanStats((stats) => ({
              ...stats,
              noData: stats.noData + 1,
            }));
          }
          if (typeof data.progress === "number") {
            setReceiverProgress(data.progress);
          }
          return;
        }
        if (data.type === "complete") {
          if (data.verified !== true || !Number.isSafeInteger(data.crc32)) {
            stopReceiverResources();
            setReceiverState("error");
            setReceiverError("CIMBAR envelope 未通过 CRC32 校验，已拒绝下载。");
            return;
          }
          const bytes = new Uint8Array(data.bytes);
          const name = safeFilename(String(data.name || "cimbar-file.bin"));
          const rawMime =
            typeof data.mimeType === "string" && data.mimeType
              ? data.mimeType
              : "application/octet-stream";
          const file = {
            name,
            bytes,
            mimeType: guessMimeFromName(name, rawMime),
            verified: true,
          } satisfies ReceivedFile;
          stopReceiverResources();
          presentReceivedFile(file);
          void sha256(bytes)
            .then((digest) => {
              setVerification(
                digest
                  ? `fountain + zstd + envelope CRC32 校验通过 · SHA-256 ${digest}`
                  : "fountain + zstd + envelope CRC32 校验通过",
              );
            })
            .catch(() => setVerification("fountain + zstd + envelope CRC32 校验通过"));
          return;
        }
        if (data.type === "error") {
          stopReceiverResources();
          setReceiverState("error");
          setReceiverError(data.message || "接收 worker 出错。");
        }
      };
      worker.onerror = (event) => {
        reject(new Error(event.message || "接收 worker 无法加载。"));
      };
    });

    try {
      const streamPromise = navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          facingMode: { ideal: "environment" },
          // 720p is enough for mode Bm cells and is easier for autofocus.
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 30, max: 30 },
        },
      });
      const [stream] = await Promise.all([streamPromise, workerReady]);
      const track = stream.getVideoTracks()[0];
      if (track) {
        try {
          await track.applyConstraints({
            advanced: [
              { focusMode: "continuous" },
              { exposureMode: "continuous" },
              { whiteBalanceMode: "continuous" },
            ] as unknown as MediaTrackConstraintSet[],
          });
        } catch {
          // Constraints are best-effort; many browsers reject unknown keys.
        }
      }
      const video = receiverVideoRef.current;
      if (!video) throw new Error("相机预览还没有准备好。");
      cameraStreamRef.current = stream;
      video.srcObject = stream;
      await video.play();
      receiverActiveRef.current = true;
      setReceiverState("receiving");
      scheduleVideoFrame();
    } catch (error) {
      stopReceiverResources();
      setReceiverState("error");
      setReceiverError(describeError(error));
    }
  }

  function stopReceiver() {
    stopReceiverResources();
    if (receiverState !== "complete") setReceiverState("idle");
  }

  function receiveAgain() {
    stopReceiverResources();
    revokePreviewUrl();
    setReceivedFile(null);
    setVerification(null);
    setReceiverProgress(0);
    setDecodedFrames(0);
    setReceiverError(null);
    setReceiverState("idle");
  }

  const receiverActive = receiverState === "starting" || receiverState === "receiving";
  const showTabs = !embedded && !direction;

  return (
    <div className={`${styles.lab}${embedded ? ` ${styles.labEmbedded}` : ""}`}>
      {showTabs && (
        <div className={styles.viewTabs} role="tablist" aria-label="彩色高速视图">
          <button
            className={tabClass(view === "send")}
            type="button"
            role="tab"
            aria-selected={view === "send"}
            onClick={() => changeView("send")}
          >
            发送
            <small>显示动态 cimbar</small>
          </button>
          <button
            className={tabClass(view === "receive")}
            type="button"
            role="tab"
            aria-selected={view === "receive"}
            onClick={() => changeView("receive")}
          >
            接收
            <small>点击后开启 camera</small>
          </button>
        </div>
      )}

      <div className={styles.panelStack}>
        <article
          className={`${styles.panel} ${view === "send" ? styles.panelVisible : styles.panelHidden}`}
          role="tabpanel"
          aria-label="发送文件"
          hidden={view !== "send"}
        >
          <div className={styles.panelHeader}>
            <div>
              <span className="mono-label">SENDER / MODE B</span>
              <h3>把文件变成彩色高速流。</h3>
            </div>
            <span className={styles.liveBadge}>MODE {CIMBAR_MODE_LABEL}</span>
          </div>
          <label className={styles.filePicker} htmlFor="cimbar-file">
            <span className={styles.filePickerMark} aria-hidden="true">＋</span>
            <span>
              <strong>{selectedFile?.name || "选择任意本地文件"}</strong>
              <small>
                {selectedFile
                  ? `${formatBytes(selectedFile.size)} · ${selectedFile.type || "application/octet-stream"}`
                  : "文件只在此设备读取，不上传服务器"}
              </small>
            </span>
          </label>
          <input
            className="visually-hidden"
            id="cimbar-file"
            type="file"
            onChange={handleFileChange}
          />
          <div className={styles.codeStage}>
            <canvas
              ref={senderCanvasRef}
              className={styles.codeCanvas}
              width={canvasSize}
              height={canvasSize}
              style={{ width: canvasSize, height: canvasSize }}
              role="img"
              aria-label="动态 cimbar 彩色视觉码"
            />
            {!selectedFile && <span className={styles.codePlaceholder}>等待本地文件</span>}
          </div>
          <div className={styles.metrics} aria-live="polite">
            <span><small>模式</small><strong>{CIMBAR_MODE_LABEL}</strong></span>
            <span><small>显示</small><strong>{canvasSize}px · {CIMBAR_DISPLAY_FPS}fps</strong></span>
            <span><small>已输出</small><strong>{senderFrames} 帧</strong></span>
          </div>
          <div className={styles.actions}>
            {senderState === "sending" && (
              <button className="button button-secondary" type="button" onClick={stopSender}>
                停止显示
              </button>
            )}
            {senderState === "stopped" && selectedFile && (
              <button
                className="button button-primary"
                type="button"
                onClick={() => postSenderFile(selectedFile)}
              >
                继续显示 <span aria-hidden="true">↗</span>
              </button>
            )}
          </div>
          <p className={styles.status} aria-live="polite">
            {senderState === "loading"
              ? "正在准备本地 WASM 编码器…"
              : senderState === "sending"
                ? `正在播放彩色码（${CIMBAR_DISPLAY_FPS}fps · 模式 ${CIMBAR_MODE_LABEL}）。码尽量占满取景框，屏幕调最亮，另一端选「彩色视觉码」。`
                : senderState === "stopped"
                  ? "已停止显示；可以继续当前文件。"
                  : senderError || "选择文件后，浏览器会在本地开始编码并自动播放。"}
          </p>
        </article>

        <article
          className={`${styles.panel} ${view === "receive" ? styles.panelVisible : styles.panelHidden}`}
          role="tabpanel"
          aria-label="接收文件"
          hidden={view !== "receive"}
        >
          <div className={styles.panelHeader}>
            <div>
              <span className="mono-label">RECEIVER / MODE B</span>
              <h3>点击后，请 camera 看向彩色流。</h3>
            </div>
            <span className={styles.liveBadge}>LOCAL</span>
          </div>
          <div className={`${styles.cameraStage}${receiverActive ? ` ${styles.cameraActive}` : ""}`}>
            <video
              ref={receiverVideoRef}
              className={styles.cameraVideo}
              autoPlay
              muted
              playsInline
              aria-label="cimbar 相机预览"
            />
            {!receiverActive && (
              <div className={styles.cameraPlaceholder}>
                <b>◎</b>
                <span>尚未请求 camera</span>
              </div>
            )}
            <span className={`${styles.cameraCorner} ${styles.cornerTopLeft}`} />
            <span className={`${styles.cameraCorner} ${styles.cornerTopRight}`} />
            <span className={`${styles.cameraCorner} ${styles.cornerBottomLeft}`} />
            <span className={`${styles.cameraCorner} ${styles.cornerBottomRight}`} />
          </div>
          <canvas ref={captureCanvasRef} className={styles.captureCanvas} aria-hidden="true" />
          <div className={styles.metrics} aria-live="polite">
            <span><small>模式</small><strong>{CIMBAR_MODE_LABEL}</strong></span>
            <span><small>恢复</small><strong>{Math.round(receiverProgress * 100)}%</strong></span>
            <span>
              <small>有效/空</small>
              <strong>
                {scanStats.decoded}/{scanStats.noData}
                {scanStats.decoded + scanStats.noData > 0
                  ? ` · ${Math.round(
                      (100 * scanStats.decoded) /
                        (scanStats.decoded + scanStats.noData),
                    )}%`
                  : ""}
              </strong>
            </span>
          </div>
          <div className={styles.actions}>
            {!receiverActive && receiverState !== "complete" && (
              <button className="button button-primary" type="button" onClick={startReceiver}>
                开启摄像头 <span aria-hidden="true">↗</span>
              </button>
            )}
            {receiverActive && (
              <button className="button button-secondary" type="button" onClick={stopReceiver}>
                停止接收
              </button>
            )}
            {receivedFile && (
              <>
                <button
                  className="button button-primary"
                  type="button"
                  onClick={() => openReceivedInBrowser(receivedFile)}
                >
                  在浏览器中打开
                </button>
                <button
                  className="button button-secondary"
                  type="button"
                  onClick={() => downloadFile(receivedFile)}
                >
                  下载
                </button>
              </>
            )}
            {receiverState === "complete" && (
              <button className="button button-secondary" type="button" onClick={receiveAgain}>
                重新接收
              </button>
            )}
          </div>
          <p className={styles.status} aria-live="polite">
            {receiverState === "starting"
              ? "正在请求摄像头并加载本地解码 worker…"
              : receiverState === "receiving"
                ? scanStats.decoded > 0
                  ? `正在恢复 · 有效 ${decodedFrames} · 空 ${scanStats.noData} · ${Math.round(receiverProgress * 100)}%`
                  : `扫描中 · 空 ${scanStats.noData}。码需占满框、屏幕调最亮、两端都选「彩色视觉码」、稳定对准。`
                : receiverState === "complete" && receivedFile
                  ? `接收完成 · ${receivedFile.name} · 可在浏览器中打开`
                  : receiverError || "点击「开启摄像头」后对准发送端。两端都必须选彩色视觉码。"}
          </p>
          {receivedFile && receiverState === "complete" && (
            <div className={styles.receivedFile}>
              <strong>{receivedFile.name}</strong>
              <span>{formatBytes(receivedFile.bytes.length)} · {verification || "正在计算 SHA-256…"}</span>
              {previewUrl && resolvedMime(receivedFile).startsWith("image/") && (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={previewUrl}
                  alt={receivedFile.name}
                  className={styles.inlinePreview}
                />
              )}
              {previewUrl && resolvedMime(receivedFile).startsWith("video/") && (
                <video
                  src={previewUrl}
                  className={styles.inlinePreview}
                  controls
                  playsInline
                />
              )}
              <div className={styles.actions} style={{ marginTop: 10 }}>
                <button
                  className="button button-primary"
                  type="button"
                  onClick={() => openReceivedInBrowser(receivedFile)}
                >
                  在浏览器中打开
                </button>
                <button
                  className="button button-secondary"
                  type="button"
                  onClick={() => downloadFile(receivedFile)}
                >
                  下载
                </button>
              </div>
            </div>
          )}
        </article>
      </div>
    </div>
  );
}
