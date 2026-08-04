"use client";

import { useEffect, useRef, useState } from "react";

import styles from "./cimbar.module.css";

const SEND_WORKER_URL = "/cimbar/node_modules/cimbar-send-bootstrap.js";
const RECEIVE_WORKER_URL = "/cimbar/node_modules/cimbar-receive-worker.js";
/**
 * Peak experimental profile for high-end phones (e.g. two iPhones).
 * Matches upstream libcimbar Mode B demo: full density + full display rate.
 * Encode and decode must stay on the same mode id.
 */
const MAX_INPUT_BYTES = 33 * 1024 * 1024;
const CIMBAR_MODE = 68;
const CIMBAR_MODE_LABEL = "B";
/** Upstream peak display rate (~106 KB/s reference conditions). */
const CIMBAR_DISPLAY_FPS = 15;
/**
 * Sample the camera faster than the 15 fps display so dwell frames are
 * more likely to be captured on iPhone-class sensors.
 */
const RECEIVE_CAPTURE_INTERVAL_MS = 33;
/** Full Mode B grid. Keep bitmap size == CSS size (no downscale). */
const CIMBAR_CANVAS_SIZE = 1024;

function resolveCimbarCanvasSize() {
  return CIMBAR_CANVAS_SIZE;
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
type SenderState =
  | "idle"
  | "loading"
  | "ready"
  | "sending"
  | "paused"
  | "error";
type ReceiverState = "idle" | "starting" | "receiving" | "complete" | "error";

const SAMPLE_VIDEO_URL = "/onesend-optical-test.mp4";
const SAMPLE_VIDEO_NAME = "onesend-optical-test.mp4";
const SAMPLE_VIDEO_MIME = "video/mp4";

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
  const [previewOpen, setPreviewOpen] = useState(true);

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

  const fileInputRef = useRef<HTMLInputElement>(null);
  const senderCanvasRef = useRef<HTMLCanvasElement>(null);
  const senderWorkerRef = useRef<Worker | null>(null);
  const senderReadyRef = useRef(false);
  const pendingFileRef = useRef<File | null>(null);
  const startWhenReadyRef = useRef(false);
  const sampleAbortRef = useRef<AbortController | null>(null);
  const sampleLoadedRef = useRef(false);

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
  const wakeLockRef = useRef<{ release: () => Promise<void> } | null>(null);

  async function requestWakeLock() {
    try {
      const nav = navigator as Navigator & {
        wakeLock?: {
          request: (
            type: "screen",
          ) => Promise<{ release: () => Promise<void> }>;
        };
      };
      if (!nav.wakeLock?.request) return;
      wakeLockRef.current = await nav.wakeLock.request("screen");
    } catch {
      // Optional on browsers that deny or lack the API.
    }
  }

  async function releaseWakeLock() {
    const lock = wakeLockRef.current;
    wakeLockRef.current = null;
    if (!lock) return;
    try {
      await lock.release();
    } catch {
      // ignore
    }
  }

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
    void releaseWakeLock();
  }

  useEffect(() => {
    return () => {
      sampleAbortRef.current?.abort();
      senderWorkerRef.current?.terminate();
      stopReceiverResources();
      revokePreviewUrl();
      void releaseWakeLock();
    };
  }, []);

  function markSenderReady(file: File) {
    pendingFileRef.current = file;
    setSelectedFile(file);
    setSenderFrames(0);
    setSenderError(null);
    setSenderState("ready");
  }

  function postSenderFile(file: File) {
    pendingFileRef.current = file;
    const worker = senderWorkerRef.current;
    if (!worker || !senderReadyRef.current) {
      startWhenReadyRef.current = true;
      setSenderState("loading");
      ensureSenderWorker(file);
      return;
    }
    startWhenReadyRef.current = false;
    setSenderState("sending");
    setSenderFrames(0);
    setSenderError(null);
    void requestWakeLock();
    worker.postMessage({ type: "load", file });
  }

  function ensureSenderWorker(file: File) {
    pendingFileRef.current = file;
    if (senderWorkerRef.current) {
      if (senderReadyRef.current) {
        markSenderReady(file);
      } else {
        setSenderState("loading");
      }
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
        // Prepare only — user presses 开始发送, same as QR modes.
        // If they already pressed start while WASM was loading, begin now.
        if (pendingFileRef.current && startWhenReadyRef.current) {
          postSenderFile(pendingFileRef.current);
        } else if (pendingFileRef.current) {
          markSenderReady(pendingFileRef.current);
        }
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

  function prepareSelectedFile(file: File) {
    if (file.size > MAX_INPUT_BYTES) {
      setSenderState("error");
      setSenderError("这个浏览器实验目前支持不超过 33 MB 的文件。");
      return;
    }
    // Stop any active broadcast before swapping files.
    if (senderState === "sending" || senderState === "paused") {
      senderWorkerRef.current?.postMessage({ type: "stop" });
    }
    markSenderReady(file);
    ensureSenderWorker(file);
  }

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    sampleLoadedRef.current = true;
    prepareSelectedFile(file);
  }

  async function loadSampleVideo({ automatic = false } = {}) {
    if (automatic && (sampleLoadedRef.current || selectedFile)) return;
    sampleAbortRef.current?.abort();
    const controller = new AbortController();
    sampleAbortRef.current = controller;
    try {
      setSenderState("loading");
      setSenderError(null);
      const response = await fetch(SAMPLE_VIDEO_URL, {
        signal: controller.signal,
      });
      if (!response.ok) {
        throw new Error(`无法加载测试视频（${response.status}）。`);
      }
      const buffer = await response.arrayBuffer();
      if (controller.signal.aborted) return;
      if (automatic && sampleLoadedRef.current) return;
      const file = new File([buffer], SAMPLE_VIDEO_NAME, {
        type: SAMPLE_VIDEO_MIME,
      });
      sampleLoadedRef.current = true;
      prepareSelectedFile(file);
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      setSenderState("error");
      setSenderError(describeError(error));
    } finally {
      if (sampleAbortRef.current === controller) {
        sampleAbortRef.current = null;
      }
    }
  }

  useEffect(() => {
    if (view !== "send") return;
    const timer = window.setTimeout(() => {
      void loadSampleVideo({ automatic: true });
    }, 0);
    return () => window.clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [view]);

  function startSender() {
    const file = pendingFileRef.current ?? selectedFile;
    if (!file) return;
    postSenderFile(file);
  }

  function pauseSender() {
    senderWorkerRef.current?.postMessage({ type: "stop" });
    setSenderState((state) => (state === "sending" ? "paused" : state));
    void releaseWakeLock();
  }

  function stopSender() {
    senderWorkerRef.current?.postMessage({ type: "stop" });
    void releaseWakeLock();
    if (pendingFileRef.current || selectedFile) {
      setSenderState("ready");
      setSenderFrames(0);
      return;
    }
    pendingFileRef.current = null;
    setSenderState("idle");
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
      // Peak receive path for modern phones: 1080p-class stream + 30 fps so
      // the 15 fps color display is oversampled rather than under-sampled.
      const streamPromise = navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          facingMode: { ideal: "environment" },
          width: { min: 720, ideal: 1920 },
          height: { min: 720, ideal: 1080 },
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
      void requestWakeLock();
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

  const receiverActive =
    receiverState === "starting" || receiverState === "receiving";
  const senderIsActive =
    senderState === "sending" || senderState === "paused";
  const senderReady =
    senderState === "ready" ||
    senderState === "paused" ||
    (senderState === "loading" && !!selectedFile);
  const showTabs = !embedded && !direction;
  const fileInputId = embedded
    ? `cimbar-file-${direction ?? view}`
    : "cimbar-file";

  const senderStatusText =
    senderState === "loading"
      ? "准备中…"
      : senderState === "sending"
        ? `发送中 · ${senderFrames} 帧`
        : senderState === "paused"
          ? "已暂停"
          : senderState === "ready"
            ? "已就绪，点开始发送"
            : senderError
              ? `错误：${senderError}`
              : "准备中…";

  const receiverStatusText =
    receiverState === "starting"
      ? "准备摄像头…"
      : receiverState === "receiving"
        ? scanStats.decoded > 0
          ? `接收中 · ${Math.round(receiverProgress * 100)}%`
          : "接收中"
        : receiverState === "complete" && receivedFile
          ? `完成 · ${receivedFile.name}`
          : receiverError
            ? `错误：${receiverError}`
            : "开启摄像头后对准发送端";

  return (
    <div className={embedded ? "web-cimbar-shell" : styles.lab}>
      {showTabs && (
        <div className="web-role-switch" role="tablist" aria-label="彩色视觉码">
          <button
            type="button"
            role="tab"
            className={view === "send" ? "is-selected" : ""}
            aria-selected={view === "send"}
            onClick={() => changeView("send")}
          >
            发送
          </button>
          <button
            type="button"
            role="tab"
            className={view === "receive" ? "is-selected" : ""}
            aria-selected={view === "receive"}
            onClick={() => changeView("receive")}
          >
            接收
          </button>
        </div>
      )}

      {view === "send" && (
        <div className="web-workbench web-workbench-send">
          <div className="web-workbench-left">
            <section className="web-task-block" aria-labelledby="cimbar-send-file-title">
              <div className="web-task-heading">
                <span className="web-task-index">1.</span>
                <h3 id="cimbar-send-file-title">选择文件</h3>
              </div>
              <div className="web-toolbar">
                <label className="web-file-picker web-file-picker-compact" htmlFor={fileInputId}>
                  <span className="web-file-picker-mark" aria-hidden="true">
                    ＋
                  </span>
                  <span>
                    <strong>{selectedFile?.name ?? "选择文件"}</strong>
                    <small>
                      {selectedFile
                        ? `${formatBytes(selectedFile.size)} · ${selectedFile.type || "application/octet-stream"}`
                        : "未选文件"}
                    </small>
                  </span>
                </label>
                <input
                  ref={fileInputRef}
                  className="visually-hidden"
                  id={fileInputId}
                  type="file"
                  onChange={handleFileChange}
                />
                <button
                  className="button button-secondary button-compact"
                  type="button"
                  disabled={senderIsActive || senderState === "loading"}
                  onClick={() => {
                    void loadSampleVideo();
                  }}
                >
                  测试视频
                </button>
              </div>
            </section>

            <section className="web-task-block web-send-controls" aria-labelledby="cimbar-send-action-title">
              <div className="web-task-heading">
                <span className="web-task-index">2.</span>
                <h3 id="cimbar-send-action-title">准备发送</h3>
              </div>
              <div className="web-transfer-actions web-transfer-actions-primary">
                {!senderIsActive && (
                  <button
                    className="button button-primary"
                    type="button"
                    disabled={!selectedFile || senderState === "loading"}
                    onClick={startSender}
                  >
                    {senderState === "loading" ? "准备中…" : "开始发送"}
                  </button>
                )}
                {senderState === "sending" && (
                  <button
                    className="button button-secondary"
                    type="button"
                    onClick={pauseSender}
                  >
                    暂停
                  </button>
                )}
                {senderState === "paused" && (
                  <button
                    className="button button-primary"
                    type="button"
                    onClick={startSender}
                  >
                    继续
                  </button>
                )}
                {senderIsActive && (
                  <button
                    className="button button-secondary"
                    type="button"
                    onClick={stopSender}
                  >
                    结束
                  </button>
                )}
              </div>
              <p className="web-status web-status-compact" aria-live="polite">
                {senderStatusText}
              </p>
              <div className="web-transfer-stats web-transfer-stats-inline" aria-live="polite">
                <span>
                  速度<strong>—</strong>
                </span>
                <span>
                  进度<strong>{senderIsActive ? "播放中" : senderReady ? "就绪" : "—"}</strong>
                </span>
                <span>
                  帧<strong>{senderFrames}</strong>
                </span>
              </div>
            </section>
          </div>

          <section className="web-workbench-right" aria-labelledby="cimbar-send-code-title">
            <div className="web-task-heading">
              <span className="web-task-index">3.</span>
              <h3 id="cimbar-send-code-title">扫码连接</h3>
            </div>
            <div className="web-code-stage web-code-stage-compact">
              <canvas
                ref={senderCanvasRef}
                className="web-code-canvas"
                width={canvasSize}
                height={canvasSize}
                style={{
                  // Keep bitmap == CSS size; CSS downscaling breaks color cells.
                  width: canvasSize,
                  height: canvasSize,
                  imageRendering: "pixelated",
                }}
                role="img"
                aria-label="彩色视觉码"
              />
              {!selectedFile && (
                <span className="web-code-placeholder">准备中…</span>
              )}
            </div>
            <p className="web-stage-note">
              峰值实验 · Mode {CIMBAR_MODE_LABEL} · {CIMBAR_DISPLAY_FPS}
              fps · 请用另一台设备选「彩色视觉码」扫描，屏幕调最亮。
            </p>
          </section>
        </div>
      )}

      {view === "receive" && (
        <div className="web-workbench web-workbench-receive">
          <section
            className="web-workbench-left web-receive-controls"
            aria-labelledby="cimbar-receive-action-title"
          >
            <div className="web-task-heading">
              <span className="web-task-index">1.</span>
              <h3 id="cimbar-receive-action-title">开启接收</h3>
            </div>
            <div className="web-transfer-actions web-transfer-actions-primary">
              {!receiverActive && receiverState !== "complete" && (
                <button
                  className="button button-primary"
                  type="button"
                  onClick={startReceiver}
                >
                  开启摄像头
                </button>
              )}
              {receiverActive && (
                <button
                  className="button button-secondary"
                  type="button"
                  onClick={stopReceiver}
                >
                  暂停
                </button>
              )}
              {receiverState === "complete" && (
                <button
                  className="button button-secondary"
                  type="button"
                  onClick={receiveAgain}
                >
                  再收一次
                </button>
              )}
            </div>
            <p className="web-status web-status-compact" aria-live="polite">
              {receiverStatusText}
            </p>
            <div className="web-transfer-stats web-transfer-stats-inline" aria-live="polite">
              <span>
                速度<strong>—</strong>
              </span>
              <span>
                进度<strong>{Math.round(receiverProgress * 100)}%</strong>
              </span>
              <span>
                帧<strong>{decodedFrames}</strong>
              </span>
            </div>
            {receivedFile && receiverState === "complete" && (
              <div className="web-received-actions">
                <button
                  className="button button-primary"
                  type="button"
                  onClick={() => openReceivedInBrowser(receivedFile)}
                >
                  打开 / 新标签
                </button>
                <button
                  className="button button-secondary"
                  type="button"
                  onClick={() => downloadFile(receivedFile)}
                >
                  保存
                </button>
                {previewUrl && (
                  <button
                    className="button button-secondary"
                    type="button"
                    onClick={() => setPreviewOpen((open) => !open)}
                  >
                    {previewOpen ? "收起预览" : "预览"}
                  </button>
                )}
                {verification && (
                  <p className="web-stage-note">{verification}</p>
                )}
                {previewOpen && previewUrl && resolvedMime(receivedFile).startsWith("image/") && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={previewUrl}
                    alt={receivedFile.name}
                    className={styles.inlinePreview}
                  />
                )}
                {previewOpen && previewUrl && resolvedMime(receivedFile).startsWith("video/") && (
                  <video
                    src={previewUrl}
                    className={styles.inlinePreview}
                    controls
                    playsInline
                  />
                )}
              </div>
            )}
          </section>

          <section className="web-workbench-right" aria-labelledby="cimbar-receive-stage-title">
            <div className="web-task-heading">
              <span className="web-task-index">2.</span>
              <h3 id="cimbar-receive-stage-title">扫码连接</h3>
            </div>
            <div
              className={`web-camera-stage web-camera-stage-compact${
                receiverActive ? " is-active" : ""
              }`}
            >
              <video
                ref={receiverVideoRef}
                className="web-camera-video"
                autoPlay
                muted
                playsInline
                aria-label="相机预览"
              />
              {!receiverActive && (
                <span className="web-camera-placeholder">开启摄像头后对准发送端</span>
              )}
            </div>
            <canvas
              ref={captureCanvasRef}
              className={styles.captureCanvas}
              aria-hidden="true"
            />
            <p className="web-stage-note">对准发送端的视觉码。</p>
          </section>
        </div>
      )}
    </div>
  );
}
