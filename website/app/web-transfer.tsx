"use client";

import QRCode from "qrcode";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";

import { Brand } from "./brand";
import { CimbarTransfer } from "./cimbar/cimbar-client";
import {
  TRANSFER_MODES,
  OpticalReceiver,
  OpticalSender,
  decodeTransferFile,
  encodeTransferFile,
  extractScannerFrame,
  formatBytes,
  formatSpeed,
  theoreticalSpeed,
} from "./web-transfer-protocol.mjs";

export type WebTransferCopy = {
  eyebrow: string;
  title: string;
  lead: string;
  localBadge: string;
  pickRole: string;
  pickRoleHint: string;
  senderTitle: string;
  senderBlurb: string;
  receiverTitle: string;
  receiverBlurb: string;
  backToPick: string;
  fileChooser: string;
  noFile: string;
  chooseFile: string;
  sampleVideo: string;
  mode: string;
  modeSettings: string;
  autoFast: string;
  fast: string;
  reliable: string;
  turbo: string;
  color: string;
  fastDetail: string;
  reliableDetail: string;
  turboDetail: string;
  colorDetail: string;
  displayCode: string;
  pause: string;
  resume: string;
  stop: string;
  readyToSend: string;
  sending: string;
  paused: string;
  pass: string;
  cameraIdle: string;
  startCamera: string;
  stopCamera: string;
  scanning: string;
  receiving: string;
  progress: string;
  speed: string;
  frames: string;
  complete: string;
  download: string;
  openPreview: string;
  closePreview: string;
  openInBrowser: string;
  saveFile: string;
  previewUnavailable: string;
  receiveAgain: string;
  cameraNote: string;
  localNote: string;
  interopNote: string;
  browserOnly: string;
  preparing: string;
  errorPrefix: string;
};

export const webTransferCopy: WebTransferCopy = {
  eyebrow: "WEB TRANSFER",
  title: "网页传输",
  lead: "不装 App 也能发。选发送或接收，其他交给 OneSend。",
  localBadge: "仅本地",
  pickRole: "选择",
  pickRoleHint: "",
  senderTitle: "发送",
  senderBlurb: "",
  receiverTitle: "接收",
  receiverBlurb: "",
  backToPick: "返回",
  fileChooser: "文件",
  noFile: "未选文件",
  chooseFile: "选择文件",
  sampleVideo: "测试视频",
  mode: "模式",
  modeSettings: "传输模式设置",
  autoFast: "自动 · 快速",
  fast: "快速",
  reliable: "可靠",
  turbo: "Turbo QR",
  color: "彩色视觉码",
  fastDetail: "",
  reliableDetail: "",
  turboDetail: "",
  colorDetail: "",
  displayCode: "开始发送",
  pause: "暂停",
  resume: "继续",
  stop: "结束",
  readyToSend: "已就绪，点开始发送",
  sending: "发送中",
  paused: "已暂停",
  pass: "轮次",
  cameraIdle: "开启摄像头后对准发送端",
  startCamera: "开启摄像头",
  stopCamera: "停止",
  scanning: "准备摄像头…",
  receiving: "接收中",
  progress: "进度",
  speed: "速度",
  frames: "帧",
  complete: "完成",
  download: "下载",
  openPreview: "预览",
  closePreview: "收起预览",
  openInBrowser: "打开 / 新标签",
  saveFile: "保存",
  previewUnavailable: "此文件格式暂不支持内置预览。",
  receiveAgain: "再收一次",
  cameraNote: "对准发送端的视觉码。",
  localNote: "文件只在本机处理。",
  interopNote: "",
  browserOnly: "浏览器",
  preparing: "准备中…",
  errorPrefix: "错误：",
};

export type TransferRole = "send" | "receive";
type TransferModeChoice = "fast" | "reliable" | "turbo" | "cimbar";
type QrModeChoice = "fast" | "reliable" | "turbo";

/** Shared built-in demo clip (same asset as the Flutter app sample video). */
const SAMPLE_VIDEO_URL = "/onesend-optical-test.mp4";
const SAMPLE_VIDEO_NAME = "onesend-optical-test.mp4";
const SAMPLE_VIDEO_MIME = "video/mp4";

type SenderState = "idle" | "preparing" | "ready" | "sending" | "paused";
type ReceiverState = "idle" | "starting" | "receiving" | "complete" | "error";

type SelectedFile = {
  name: string;
  mimeType: string;
  size: number;
};

type ReceivedFile = {
  name: string;
  mimeType: string;
  bytes: Uint8Array;
};

type ScannerControls = {
  stop: () => void;
};

type ScannerResult = {
  getResultMetadata?: () => Map<number | string, unknown>;
  getRawBytes?: () => Uint8Array;
  getText?: () => string;
};

type ReceiverSnapshot = {
  progress: number;
  totalLength: number;
  framesNew: number;
};

/**
 * QR display policy for the live sender canvas.
 *
 * A QR module must stay an integer number of CSS pixels. Three pixels is the
 * floor for dense optical QR on phone cameras; four is preferred when the
 * viewport can spare it. The desktop budgets leave room for the surrounding
 * workbench while the height budget prevents a short desktop viewport from
 * producing a canvas taller than its useful display area.
 */
export const QR_DISPLAY_POLICY = {
  quietZoneModules: 4,
  minimumModulePx: 3,
  preferredModulePx: 4,
  desktopBreakpointPx: 840,
  desktopWidthRatio: 0.44,
  desktopHeightRatio: 0.46,
  mobileWidthRatio: 0.94,
  maximumDisplayPx: 640,
  fallbackViewport: { width: 1024, height: 768 },
} as const;

export type QrDisplayViewport = {
  width: number;
  height: number;
};

export type QrDisplayMetrics = {
  availableDisplayPx: number;
  modulePx: number;
  pixelSize: number;
};

/** Return deterministic integer-pixel sizing for a QR with the given extent. */
export function getQrDisplayMetrics(
  totalModules: number,
  viewport: QrDisplayViewport,
): QrDisplayMetrics {
  const safeTotalModules = Math.max(1, Math.floor(totalModules));
  const viewportWidth = Math.max(1, Math.floor(viewport.width));
  const viewportHeight = Math.max(1, Math.floor(viewport.height));
  const isDesktop =
    viewportWidth >= QR_DISPLAY_POLICY.desktopBreakpointPx;
  const widthBudget = Math.floor(
    viewportWidth *
      (isDesktop
        ? QR_DISPLAY_POLICY.desktopWidthRatio
        : QR_DISPLAY_POLICY.mobileWidthRatio),
  );
  const heightBudget = isDesktop
    ? Math.floor(viewportHeight * QR_DISPLAY_POLICY.desktopHeightRatio)
    : QR_DISPLAY_POLICY.maximumDisplayPx;
  const availableDisplayPx = Math.max(
    0,
    Math.min(
      QR_DISPLAY_POLICY.maximumDisplayPx,
      widthBudget,
      heightBudget,
    ),
  );
  const modulePx = Math.max(
    QR_DISPLAY_POLICY.minimumModulePx,
    Math.min(
      QR_DISPLAY_POLICY.preferredModulePx,
      Math.floor(availableDisplayPx / safeTotalModules),
    ),
  );

  return {
    availableDisplayPx,
    modulePx,
    pixelSize: safeTotalModules * modulePx,
  };
}

/**
 * Renders a OneSend QR so it stays camera-scannable on real phones.
 *
 * Critical: never let CSS bilinear-scale a dense QR down. Version-30 codes
 * (fast mode) already need ~3–4 CSS pixels per module; scaling a 420px canvas
 * into a 280px box made phone cameras fail completely.
 */
function drawQr(
  canvas: HTMLCanvasElement,
  bytes: Uint8Array,
  mode: QrModeChoice,
) {
  const config = TRANSFER_MODES[mode];
  const maskPattern = bytes.length >= 4 ? bytes[bytes.length - 4] & 7 : 0;
  const symbol = QRCode.create(
    [{ data: new Uint8ClampedArray(bytes), mode: "byte" }],
    {
      errorCorrectionLevel: config.errorCorrectionLevel as "L" | "M" | "Q" | "H",
      maskPattern: maskPattern as 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7,
    },
  );
  const marginModules = QR_DISPLAY_POLICY.quietZoneModules;
  const totalModules = symbol.modules.size + marginModules * 2;
  const viewport =
    typeof window !== "undefined"
      ? { width: window.innerWidth, height: window.innerHeight }
      : QR_DISPLAY_POLICY.fallbackViewport;
  const { modulePx, pixelSize } = getQrDisplayMetrics(
    totalModules,
    viewport,
  );
  if (canvas.width !== pixelSize || canvas.height !== pixelSize) {
    canvas.width = pixelSize;
    canvas.height = pixelSize;
  }
  // Keep CSS size equal to the bitmap so modules are not bilinear-filtered.
  // The compact mobile stylesheet has a max-width !important rule, so these
  // inline declarations must carry the same priority to preserve 1:1 pixels.
  canvas.style.setProperty("width", `${pixelSize}px`, "important");
  canvas.style.setProperty("height", `${pixelSize}px`, "important");
  canvas.style.setProperty("max-width", "none", "important");
  canvas.style.setProperty("image-rendering", "pixelated");

  const context = canvas.getContext("2d");
  if (!context) throw new Error("The browser cannot draw a visual code.");
  context.imageSmoothingEnabled = false;
  context.fillStyle = "#ffffff";
  context.fillRect(0, 0, pixelSize, pixelSize);
  context.fillStyle = "#000000";
  for (let row = 0; row < symbol.modules.size; row += 1) {
    for (let column = 0; column < symbol.modules.size; column += 1) {
      if (!symbol.modules.get(row, column)) continue;
      context.fillRect(
        (column + marginModules) * modulePx,
        (row + marginModules) * modulePx,
        modulePx,
        modulePx,
      );
    }
  }
}

/**
 * Web display interval. Protocol targets are optimistic; real phone cameras
 * need longer dwell — especially dense fast/turbo symbols.
 */
function displayIntervalMs(mode: QrModeChoice) {
  if (mode === "reliable") return 150;
  if (mode === "fast") return 140;
  if (mode === "turbo") return 170;
  return Math.max(140, Math.round(TRANSFER_MODES[mode].frameIntervalMs));
}

function isQrMode(mode: TransferModeChoice): mode is QrModeChoice {
  return mode === "fast" || mode === "reliable" || mode === "turbo";
}

function fileBlob(file: ReceivedFile) {
  const copy = new Uint8Array(file.bytes.byteLength);
  copy.set(file.bytes);
  return new Blob([copy], {
    type: resolvedMime(file),
  });
}

function triggerDownload(file: ReceivedFile) {
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

function resolvedMime(file: ReceivedFile) {
  const mime = (file.mimeType || "").toLowerCase();
  if (mime && mime !== "application/octet-stream") return mime;
  return guessMimeFromName(file.name, mime || "application/octet-stream");
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

/** Open a completed file in a new tab; unsupported formats may download. */
function openReceivedInNewTab(file: ReceivedFile) {
  const url = URL.createObjectURL(fileBlob(file));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.target = "_blank";
  anchor.rel = "noopener noreferrer";
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 180_000);
}

function describeError(error: unknown) {
  if (error instanceof Error && error.message) return error.message;
  return "The browser could not complete this local transfer.";
}

function nowMs() {
  return Date.now();
}

export type WebTransferProps = {
  copy: WebTransferCopy;
  initialRole?: TransferRole;
  lockedRole?: TransferRole;
};

export function WebTransfer({
  copy,
  initialRole = "send",
  lockedRole,
}: WebTransferProps) {
  // Fast is the automatic default. Reliability remains one compact setting away.
  const [role, setRole] = useState<TransferRole>(lockedRole ?? initialRole);
  const [mode, setMode] = useState<TransferModeChoice>("fast");
  const [senderState, setSenderState] = useState<SenderState>("idle");
  const [senderReady, setSenderReady] = useState(false);
  const [selectedFile, setSelectedFile] = useState<SelectedFile | null>(null);
  const [senderProgress, setSenderProgress] = useState(0);
  const [senderPass, setSenderPass] = useState(1);
  const [senderSpeed, setSenderSpeed] = useState("—");
  const [senderError, setSenderError] = useState<string | null>(null);
  const [receiverState, setReceiverState] = useState<ReceiverState>("idle");
  const [receiverProgress, setReceiverProgress] = useState<ReceiverSnapshot | null>(null);
  const [receiverSpeed, setReceiverSpeed] = useState("—");
  const [receiverPaused, setReceiverPaused] = useState(false);
  const [receivedFile, setReceivedFile] = useState<ReceivedFile | null>(null);
  const [previewOpen, setPreviewOpen] = useState(true);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [receiverError, setReceiverError] = useState<string | null>(null);
  const [scanHint, setScanHint] = useState<string | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);
  const senderCanvasRef = useRef<HTMLCanvasElement>(null);
  const senderRef = useRef<OpticalSender | null>(null);
  const senderTimerRef = useRef<number | null>(null);
  const senderStartedAtRef = useRef<number | null>(null);
  const senderFramesRef = useRef(0);
  const receiverVideoRef = useRef<HTMLVideoElement>(null);
  const receiverRef = useRef(new OpticalReceiver());
  const scannerControlsRef = useRef<ScannerControls | null>(null);
  const cameraStreamRef = useRef<MediaStream | null>(null);
  const receiverStartedAtRef = useRef<number | null>(null);
  const lastDecodeMissRef = useRef(0);
  const lastScanOkRef = useRef(0);
  const scanAttemptRef = useRef(0);
  const pendingBytesRef = useRef<Uint8Array | null>(null);
  const selectedFileRef = useRef<SelectedFile | null>(null);
  const selectionVersionRef = useRef(0);
  const sampleAbortRef = useRef<AbortController | null>(null);
  const modeRef = useRef<TransferModeChoice>("fast");
  const modeMenuRef = useRef<HTMLDetailsElement>(null);
  const previewUrlRef = useRef<string | null>(null);
  const usesCimbar = mode === "cimbar";
  const roleIsLocked = lockedRole !== undefined;
  const captureCanvasRef = useRef<HTMLCanvasElement | null>(null);

  function clearSenderTimer() {
    if (senderTimerRef.current !== null) {
      window.clearInterval(senderTimerRef.current);
      senderTimerRef.current = null;
    }
  }

  function stopCameraTracks() {
    scannerControlsRef.current?.stop();
    scannerControlsRef.current = null;
    cameraStreamRef.current?.getTracks().forEach((track) => track.stop());
    cameraStreamRef.current = null;
    const video = receiverVideoRef.current;
    if (video) {
      video.pause();
      video.srcObject = null;
    }
  }

  function clearPreview() {
    if (previewUrlRef.current) {
      URL.revokeObjectURL(previewUrlRef.current);
      previewUrlRef.current = null;
    }
    setPreviewUrl(null);
  }

  function showReceivedFile(file: ReceivedFile) {
    clearPreview();
    setReceivedFile(file);
    setPreviewOpen(true);
    if (isViewableMime(resolvedMime(file))) {
      const url = URL.createObjectURL(fileBlob(file));
      previewUrlRef.current = url;
      setPreviewUrl(url);
    }
  }

  function endSenderQuietly() {
    clearSenderTimer();
    setSenderState((current) => (current === "idle" ? current : "ready"));
  }

  function chooseRole(next: TransferRole) {
    if (lockedRole && next !== lockedRole) return;
    if (next === "send") {
      stopCameraTracks();
      if (receiverState !== "complete") {
        setReceiverState("idle");
        setReceiverError(null);
      }
    } else {
      endSenderQuietly();
    }
    setRole(next);
  }

  function handleRoleKeyDown(event: React.KeyboardEvent<HTMLDivElement>) {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
    event.preventDefault();
    const nextRole: TransferRole =
      event.key === "ArrowLeft"
        ? role === "send"
          ? "receive"
          : "send"
        : role === "send"
          ? "receive"
          : "send";
    chooseRole(nextRole);
    window.requestAnimationFrame(() => {
      document
        .getElementById(`web-transfer-${nextRole}-tab`)
        ?.focus();
    });
  }

  useEffect(() => {
    return () => {
      clearSenderTimer();
      stopCameraTracks();
      sampleAbortRef.current?.abort();
      if (previewUrlRef.current) URL.revokeObjectURL(previewUrlRef.current);
    };
  }, []);

  useEffect(() => {
    function openFromHash() {
      const hash = window.location.hash.replace(/^#/, "");
      if (roleIsLocked) return;
      if (hash === "web-transfer-send" || hash === "send") {
        chooseRole("send");
      } else if (hash === "web-transfer-receive" || hash === "receive") {
        chooseRole("receive");
      }
    }
    openFromHash();
    window.addEventListener("hashchange", openFromHash);
    return () => window.removeEventListener("hashchange", openFromHash);
    // Only react to hash navigation; chooseRole closes over fresh setters.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [roleIsLocked]);

  function buildSenderFromBytes(
    bytes: Uint8Array,
    file: SelectedFile,
    nextMode: QrModeChoice,
  ) {
    // QR-only builder; cimbar uses the dedicated panel.
    const payload = encodeTransferFile({
      name: file.name,
      mimeType: file.mimeType,
      bytes,
    });
    const sender = new OpticalSender(payload, nextMode);
    senderRef.current = sender;
    setSenderReady(true);
    senderStartedAtRef.current = null;
    senderFramesRef.current = 0;
    setSenderProgress(0);
    setSenderPass(1);
    setSenderSpeed("—");
    setSenderState("ready");
    // Draw a static first frame so the user can verify the code is visible
    // before pressing send (and so canvas sizing is correct early).
    requestAnimationFrame(() => {
      const canvas = senderCanvasRef.current;
      if (!canvas || senderRef.current !== sender) return;
      try {
        drawQr(canvas, sender.nextFrame().bytes, nextMode);
        // Rewind logical progress: we peeked one frame only for preview.
        senderRef.current = new OpticalSender(payload, nextMode);
      } catch (error) {
        setSenderError(describeError(error));
      }
    });
  }

  async function prepareSenderFile(input: {
    name: string;
    mimeType: string;
    bytes: Uint8Array;
  }) {
    clearSenderTimer();
    setSenderError(null);
    setSenderState("preparing");
    try {
      if (input.bytes.length > 64 * 1024 * 1024) {
        throw new Error("Files must be 64 MB or smaller.");
      }
      const file = {
        name: input.name,
        mimeType: input.mimeType,
        size: input.bytes.length,
      };
      setSelectedFile(file);
      selectedFileRef.current = file;
      pendingBytesRef.current = input.bytes;
      const qrMode = modeRef.current === "cimbar" ? "reliable" : modeRef.current;
      if (modeRef.current !== "cimbar") {
        buildSenderFromBytes(input.bytes, file, qrMode);
      } else {
        setSenderReady(false);
        setSenderState("idle");
      }
    } catch (error) {
      senderRef.current = null;
      setSenderReady(false);
      pendingBytesRef.current = null;
      setSenderState("idle");
      setSenderError(describeError(error));
    }
  }

  async function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    const selectionVersion = selectionVersionRef.current + 1;
    selectionVersionRef.current = selectionVersion;
    sampleAbortRef.current?.abort();
    try {
      const bytes = new Uint8Array(await file.arrayBuffer());
      if (selectionVersionRef.current !== selectionVersion) return;
      await prepareSenderFile({
        name: file.name,
        mimeType: file.type || "application/octet-stream",
        bytes,
      });
    } catch (error) {
      senderRef.current = null;
      setSenderReady(false);
      setSenderState("idle");
      setSenderError(describeError(error));
    }
  }

  async function loadSampleVideo({ automatic = false } = {}) {
    if (automatic && selectedFileRef.current) return;
    const selectionVersion = selectionVersionRef.current;
    sampleAbortRef.current?.abort();
    const controller = new AbortController();
    sampleAbortRef.current = controller;
    try {
      const response = await fetch(SAMPLE_VIDEO_URL, {
        signal: controller.signal,
      });
      if (!response.ok) {
        throw new Error(`Could not load sample video (${response.status}).`);
      }
      const bytes = new Uint8Array(await response.arrayBuffer());
      if (
        controller.signal.aborted ||
        selectionVersionRef.current !== selectionVersion ||
        (automatic && selectedFileRef.current)
      ) {
        return;
      }
      await prepareSenderFile({
        name: SAMPLE_VIDEO_NAME,
        mimeType: SAMPLE_VIDEO_MIME,
        bytes,
      });
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      senderRef.current = null;
      setSenderReady(false);
      setSenderState("idle");
      setSenderError(describeError(error));
    } finally {
      if (sampleAbortRef.current === controller) {
        sampleAbortRef.current = null;
      }
    }
  }

  useEffect(() => {
    if (role !== "send" || selectedFileRef.current) return;
    const timer = window.setTimeout(() => {
      void loadSampleVideo({ automatic: true });
    }, 0);
    return () => window.clearTimeout(timer);
    // Run only when entering the sender; user selection is guarded by refs.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [role]);

  function emitSenderFrame() {
    const sender = senderRef.current;
    const canvas = senderCanvasRef.current;
    if (!sender || !canvas) return;
    try {
      const frame = sender.nextFrame();
      const qrMode = isQrMode(modeRef.current) ? modeRef.current : "reliable";
      drawQr(canvas, frame.bytes, qrMode);
      senderFramesRef.current += 1;
      const elapsed = Math.max(
        1,
        nowMs() - (senderStartedAtRef.current ?? nowMs()),
      );
      const usefulBytes =
        (senderFramesRef.current * sender.mode.blockLength * 4) / 5;
      setSenderProgress(frame.passProgress);
      setSenderPass(frame.passNumber);
      setSenderSpeed(formatSpeed((usefulBytes * 1000) / elapsed));
    } catch (error) {
      clearSenderTimer();
      setSenderState("ready");
      setSenderError(describeError(error));
    }
  }

  function startSender() {
    if (!senderRef.current) return;
    clearSenderTimer();
    senderStartedAtRef.current = nowMs();
    senderFramesRef.current = 0;
    setSenderError(null);
    setSenderState("sending");
    emitSenderFrame();
    const qrMode = isQrMode(modeRef.current) ? modeRef.current : "reliable";
    senderTimerRef.current = window.setInterval(
      emitSenderFrame,
      displayIntervalMs(qrMode),
    );
  }

  function pauseSender() {
    clearSenderTimer();
    if (senderRef.current) setSenderState("paused");
  }

  function endSender() {
    clearSenderTimer();
    senderStartedAtRef.current = null;
    setSenderProgress(0);
    setSenderPass(1);
    setSenderSpeed("—");
    const bytes = pendingBytesRef.current;
    const file = selectedFile;
    if (bytes && file && isQrMode(modeRef.current)) {
      buildSenderFromBytes(bytes, file, modeRef.current);
    } else {
      senderRef.current = null;
      setSenderReady(false);
      setSenderState("idle");
    }
  }

  function handleModeChange(nextMode: TransferModeChoice) {
    if (senderState === "sending" || senderState === "paused") return;
    if (receiverState === "starting" || receiverState === "receiving") {
      stopCameraTracks();
      if (receiverState !== "complete") setReceiverState("idle");
    }
    if (modeRef.current === nextMode) return;
    modeRef.current = nextMode;
    setMode(nextMode);
    setScanHint(null);
    setReceiverError(null);
    if (nextMode === "cimbar") {
      // Leave QR engine; cimbar panel owns its own workers.
      clearSenderTimer();
      senderRef.current = null;
      setSenderReady(false);
      setSenderState("idle");
      setSenderProgress(0);
      setSenderPass(1);
      setSenderSpeed("—");
      return;
    }
    const bytes = pendingBytesRef.current;
    const file = selectedFile;
    if (bytes && file && isQrMode(nextMode)) {
      clearSenderTimer();
      buildSenderFromBytes(bytes, file, nextMode);
    }
  }

  function renderModeSwitcher() {
    const modeLocked =
      senderState === "sending" ||
      senderState === "paused" ||
      receiverState === "starting" ||
      receiverState === "receiving";
    const options: { id: TransferModeChoice; label: string }[] = [
      { id: "fast", label: copy.autoFast },
      { id: "reliable", label: copy.reliable },
      { id: "turbo", label: copy.turbo },
      { id: "cimbar", label: copy.color },
    ];
    const activeLabel =
      mode === "fast"
        ? copy.autoFast
        : options.find((option) => option.id === mode)?.label ?? copy.autoFast;
    return (
      <details className="web-mode-menu" ref={modeMenuRef}>
        <summary aria-label={`${copy.modeSettings}: ${activeLabel}`}>
          <span className="mono-label">{copy.mode}</span>
          <strong>{activeLabel}</strong>
          <span aria-hidden="true">⌄</span>
        </summary>
        <div className="web-mode-options web-mode-options-compact" role="group" aria-label={copy.modeSettings}>
          {options.map((option) => (
            <button
              key={option.id}
              className={mode === option.id ? "is-selected" : ""}
              type="button"
              aria-pressed={mode === option.id}
              disabled={modeLocked}
              onClick={() => {
                handleModeChange(option.id);
                modeMenuRef.current?.removeAttribute("open");
              }}
            >
              {option.label}
            </button>
          ))}
        </div>
      </details>
    );
  }

  async function handleScannerResult(result: ScannerResult) {
    const rawBytes = extractScannerFrame(result);
    if (!rawBytes) {
      const now = nowMs();
      if (now - lastDecodeMissRef.current > 2000) {
        lastDecodeMissRef.current = now;
        setScanHint("识别到二维码，但不是 OneSend 帧。请两端选同一模式，对准发送码。");
      }
      return;
    }
    lastScanOkRef.current = nowMs();
    setScanHint(null);
    const event = receiverRef.current.consume(rawBytes);
    if (!event?.snapshot) return;
    setReceiverProgress({
      progress: event.snapshot.progress,
      totalLength: event.snapshot.totalLength,
      framesNew: event.snapshot.framesNew,
    });
    const elapsed = Math.max(
      1,
      nowMs() - (receiverStartedAtRef.current ?? nowMs()),
    );
    setReceiverSpeed(
      formatSpeed(
        ((event.snapshot.framesNew *
          (event.snapshot.totalLength /
            Math.max(1, event.snapshot.blockCount))) *
          1000) /
          elapsed,
      ),
    );
    if (event.error) {
      setReceiverState("error");
      setReceiverError(event.error);
      return;
    }
    if (!event.payload || !event.verified) return;
    try {
      const file = await decodeTransferFile(event.payload);
      stopCameraTracks();
      showReceivedFile(file);
      setReceiverPaused(false);
      setReceiverState("complete");
    } catch (error) {
      setReceiverState("error");
      setReceiverError(describeError(error));
    }
  }

  async function startCamera() {
    if (!navigator.mediaDevices?.getUserMedia) {
      setReceiverState("error");
      setReceiverError(
        "摄像头不可用。请在 HTTPS 页面、使用支持的浏览器打开。",
      );
      return;
    }
    const resumeExistingTransfer = receiverPaused && receiverProgress !== null;
    stopCameraTracks();
    if (!resumeExistingTransfer) {
      receiverRef.current.reset();
      clearPreview();
      setReceivedFile(null);
      setReceiverProgress(null);
      setReceiverSpeed("—");
    }
    setReceiverPaused(false);
    setReceiverError(null);
    setScanHint(null);
    setReceiverState("starting");
    receiverStartedAtRef.current = nowMs();
    lastScanOkRef.current = 0;
    scanAttemptRef.current = 0;
    lastDecodeMissRef.current = 0;

    try {
      const {
        BinaryBitmap,
        DecodeHintType,
        HybridBinarizer,
        QRCodeReader,
        RGBLuminanceSource,
        BarcodeFormat,
      } = await import("@zxing/library");

      const video = receiverVideoRef.current;
      if (!video) throw new Error("摄像头预览尚未就绪。");

      // Own the stream ourselves. BrowserQRCodeReader.decodeFromConstraints
      // has been flaky on mobile Safari (no frames / silent stall).
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: false,
        video: {
          facingMode: { ideal: "environment" },
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 30, max: 30 },
        },
      });
      cameraStreamRef.current = stream;
      video.srcObject = stream;
      video.setAttribute("playsinline", "true");
      video.muted = true;
      await video.play();

      const hints = new Map();
      hints.set(DecodeHintType.POSSIBLE_FORMATS, [BarcodeFormat.QR_CODE]);
      hints.set(DecodeHintType.TRY_HARDER, true);
      // Critical for binary OneSend frames (not UTF-8 text QR).
      hints.set(DecodeHintType.CHARACTER_SET, "ISO-8859-1");
      const reader = new QRCodeReader();

      if (!captureCanvasRef.current) {
        captureCanvasRef.current = document.createElement("canvas");
      }
      const capture = captureCanvasRef.current;
      const context = capture.getContext("2d", {
        willReadFrequently: true,
        alpha: false,
      });
      if (!context) throw new Error("无法创建扫码画布。");

      let cancelled = false;
      let timer: number | null = null;
      let busy = false;

      const stop = () => {
        cancelled = true;
        if (timer !== null) {
          window.clearTimeout(timer);
          timer = null;
        }
      };

      scannerControlsRef.current = { stop };

      const schedule = (delayMs: number) => {
        if (cancelled) return;
        timer = window.setTimeout(() => {
          void tick();
        }, delayMs);
      };

      const tick = async () => {
        if (cancelled || busy) {
          schedule(40);
          return;
        }
        busy = true;
        try {
          const vw = video.videoWidth;
          const vh = video.videoHeight;
          if (vw < 32 || vh < 32 || video.readyState < 2) {
            schedule(80);
            return;
          }

          // Center-crop square: QR is square; letterboxing confuses detectors.
          const side = Math.min(vw, vh);
          const sx = Math.floor((vw - side) / 2);
          const sy = Math.floor((vh - side) / 2);
          // Cap decode resolution for mobile CPU while keeping dense modules.
          const out = Math.min(side, 960);
          if (capture.width !== out || capture.height !== out) {
            capture.width = out;
            capture.height = out;
          }
          context.imageSmoothingEnabled = false;
          context.drawImage(video, sx, sy, side, side, 0, 0, out, out);
          const image = context.getImageData(0, 0, out, out);
          const luminance = new Uint8ClampedArray(out * out);
          const pixels = image.data;
          for (let i = 0, j = 0; i < pixels.length; i += 4, j += 1) {
            // BT.601 luminance, integer approx.
            luminance[j] =
              (pixels[i] * 306 + pixels[i + 1] * 601 + pixels[i + 2] * 117) >>
              10;
          }

          scanAttemptRef.current += 1;
          try {
            const source = new RGBLuminanceSource(luminance, out, out);
            const bitmap = new BinaryBitmap(new HybridBinarizer(source));
            const result = reader.decode(bitmap, hints);
            await handleScannerResult(result as ScannerResult);
          } catch (error) {
            const name =
              error && typeof error === "object" && "name" in error
                ? String((error as { name?: string }).name)
                : "";
            if (name !== "NotFoundException" && name !== "ChecksumException" && name !== "FormatException") {
              // Keep scanning on soft decode errors.
            }
            // Nudge the user if nothing has decoded for a while.
            const now = nowMs();
            if (
              lastScanOkRef.current === 0 &&
              now - (receiverStartedAtRef.current ?? now) > 4000 &&
              now - lastDecodeMissRef.current > 2500
            ) {
              lastDecodeMissRef.current = now;
              setScanHint(
                "还没扫到有效帧。请把发送码放满取景框、屏幕调亮；优先用「可靠」模式。",
              );
            }
          } finally {
            try {
              reader.reset();
            } catch {
              // ignore
            }
          }
        } finally {
          busy = false;
          // ~12–15 Hz scan loop — enough for 140ms sender dwell without melting phone CPUs.
          schedule(70);
        }
      };

      setReceiverState("receiving");
      schedule(30);
    } catch (error) {
      stopCameraTracks();
      setReceiverState("error");
      setReceiverError(describeError(error));
    }
  }

  function stopCamera() {
    stopCameraTracks();
    if (receiverState === "starting" || receiverState === "receiving") {
      setReceiverPaused(true);
      setReceiverState("idle");
    } else if (receiverState !== "complete") {
      setReceiverState("idle");
    }
  }

  function receiveAgain() {
    stopCameraTracks();
    receiverRef.current.reset();
    clearPreview();
    setReceivedFile(null);
    setReceiverProgress(null);
    setReceiverSpeed("—");
    setReceiverPaused(false);
    setReceiverError(null);
    setReceiverState("idle");
  }

  const senderIsActive = senderState === "sending" || senderState === "paused";
  const cameraIsActive = receiverState === "starting" || receiverState === "receiving";
  const receiverPercent = Math.round((receiverProgress?.progress ?? 0) * 100);
  const showSender = role === "send";
  const showReceiver = role === "receive";

  return (
    <section
      className="section gray-section web-transfer-section"
      id="web-transfer"
      data-transfer-role={lockedRole ?? "switchable"}
      aria-labelledby="web-transfer-title"
    >
      <div className="page-shell web-transfer-shell">
        <div className="web-transfer-header">
          <div>
            <span className="section-index">{copy.eyebrow}</span>
            <h2 id="web-transfer-title">{copy.title}</h2>
            <p>{copy.lead}</p>
          </div>
          <div className="web-transfer-badges" aria-label={copy.localBadge}>
            <span>{copy.localBadge}</span>
            <span>{copy.browserOnly}</span>
          </div>
        </div>

        <div className="web-lab">
            {!roleIsLocked && (
            <div className="web-role-tabs web-role-tabs-compact" role="tablist" aria-label={copy.pickRole} onKeyDown={handleRoleKeyDown}>
              <button
                id="web-transfer-send-tab"
                type="button"
                role="tab"
                aria-selected={showSender}
                aria-controls="web-transfer-send-panel"
                tabIndex={showSender ? 0 : -1}
                className={showSender ? "is-selected" : ""}
                onClick={() => chooseRole("send")}
              >
                {copy.senderTitle}
              </button>
              <button
                id="web-transfer-receive-tab"
                type="button"
                role="tab"
                aria-selected={showReceiver}
                aria-controls="web-transfer-receive-panel"
                tabIndex={showReceiver ? 0 : -1}
                className={showReceiver ? "is-selected" : ""}
                onClick={() => chooseRole("receive")}
              >
                {copy.receiverTitle}
              </button>
            </div>
            )}

            {showSender && (
              <article
                id="web-transfer-send-panel"
                className="web-transfer-card web-transfer-card-compact"
                role={roleIsLocked ? undefined : "tabpanel"}
                aria-labelledby={roleIsLocked ? "web-transfer-title" : "web-transfer-send-tab"}
              >
                {renderModeSwitcher()}
                {usesCimbar ? (
                  <div className="web-cimbar-embed">
                    <CimbarTransfer
                      key="cimbar-send"
                      direction="send"
                      embedded
                    />
                  </div>
                ) : (
                  <div className="web-workbench web-workbench-send">
                    <div className="web-workbench-left">
                      <section className="web-task-block" aria-labelledby="web-send-file-title">
                        <div className="web-task-heading">
                          <span className="web-task-index">1.</span>
                          <h3 id="web-send-file-title">选择文件</h3>
                        </div>
                        <div className="web-toolbar">
                          <label className="web-file-picker web-file-picker-compact" htmlFor="web-transfer-file">
                            <span className="web-file-picker-mark" aria-hidden="true">＋</span>
                            <span>
                              <strong>{selectedFile?.name ?? copy.chooseFile}</strong>
                              <small>
                                {selectedFile
                                  ? `${formatBytes(selectedFile.size)} · ${selectedFile.mimeType}`
                                  : copy.noFile}
                              </small>
                            </span>
                          </label>
                          <input
                            ref={fileInputRef}
                            className="visually-hidden"
                            id="web-transfer-file"
                            type="file"
                            onChange={handleFileChange}
                          />
                          <button
                            className="button button-secondary button-compact"
                            type="button"
                            disabled={senderState === "preparing" || senderIsActive}
                            onClick={() => {
                              void loadSampleVideo();
                            }}
                          >
                            {copy.sampleVideo}
                          </button>
                        </div>
                      </section>

                      <section className="web-task-block web-send-controls" aria-labelledby="web-send-action-title">
                        <div className="web-task-heading">
                          <span className="web-task-index">2.</span>
                          <h3 id="web-send-action-title">准备发送</h3>
                        </div>
                        <div className="web-transfer-actions web-transfer-actions-primary">
                          {!senderIsActive && (
                            <button
                              className="button button-primary"
                              type="button"
                              disabled={!senderReady || senderState === "preparing"}
                              onClick={startSender}
                            >
                              {senderState === "preparing" ? copy.preparing : copy.displayCode}
                            </button>
                          )}
                          {senderState === "sending" && (
                            <button className="button button-secondary" type="button" onClick={pauseSender}>
                              {copy.pause}
                            </button>
                          )}
                          {senderState === "paused" && (
                            <button className="button button-primary" type="button" onClick={startSender}>
                              {copy.resume}
                            </button>
                          )}
                          {senderIsActive && (
                            <button className="button button-secondary" type="button" onClick={endSender}>
                              {copy.stop}
                            </button>
                          )}
                        </div>
                        <p className="web-status web-status-compact" aria-live="polite">
                          {senderState === "sending"
                            ? `${copy.sending} · ${copy.pass} ${senderPass}`
                            : senderState === "paused"
                              ? copy.paused
                              : senderState === "ready"
                                ? copy.readyToSend
                                : senderError
                                  ? `${copy.errorPrefix} ${senderError}`
                                  : copy.preparing}
                        </p>
                        <div className="web-transfer-stats web-transfer-stats-inline" aria-live="polite">
                          <span>{copy.speed}<strong>{senderSpeed}</strong></span>
                          <span>{copy.progress}<strong>{Math.round(senderProgress * 100)}%</strong></span>
                          <span>{copy.pass}<strong>{senderPass}</strong></span>
                        </div>
                      </section>
                    </div>

                    <section className="web-workbench-right" aria-labelledby="web-send-code-title">
                      <div className="web-task-heading">
                        <span className="web-task-index">3.</span>
                        <h3 id="web-send-code-title">扫码连接</h3>
                      </div>
                      <div className="web-code-stage web-code-stage-compact">
                        <canvas
                          ref={senderCanvasRef}
                          className="web-code-canvas"
                          width={360}
                          height={360}
                          role="img"
                          aria-label={copy.displayCode}
                        />
                        {!selectedFile && (
                          <span className="web-code-placeholder">{copy.preparing}</span>
                        )}
                      </div>
                      <p className="web-stage-note">请用另一台 OneSend / 扫传设备扫描。</p>
                    </section>
                  </div>
                )}
              </article>
            )}

            {showReceiver && (
              <article
                id="web-transfer-receive-panel"
                className="web-transfer-card web-transfer-card-compact"
                role={roleIsLocked ? undefined : "tabpanel"}
                aria-labelledby={roleIsLocked ? "web-transfer-title" : "web-transfer-receive-tab"}
              >
                {renderModeSwitcher()}
                {usesCimbar ? (
                  <div className="web-cimbar-embed">
                    <CimbarTransfer
                      key="cimbar-receive"
                      direction="receive"
                      embedded
                    />
                  </div>
                ) : (
                  <div className="web-workbench web-workbench-receive">
                    <section className="web-workbench-left web-receive-controls" aria-labelledby="web-receive-action-title">
                      <div className="web-task-heading">
                        <span className="web-task-index">1.</span>
                        <h3 id="web-receive-action-title">开启接收</h3>
                      </div>
                      <div className="web-transfer-actions web-transfer-actions-primary">
                        {!cameraIsActive && receiverState !== "complete" && (
                          <button className="button button-primary" type="button" onClick={startCamera}>
                            {receiverPaused ? copy.resume : copy.startCamera}
                          </button>
                        )}
                        {cameraIsActive && (
                          <button className="button button-secondary" type="button" onClick={stopCamera}>
                            {copy.pause}
                          </button>
                        )}
                        {receiverState === "complete" && (
                          <button className="button button-secondary" type="button" onClick={receiveAgain}>
                            {copy.receiveAgain}
                          </button>
                        )}
                      </div>
                      <p className="web-status web-status-compact" aria-live="polite">
                        {receiverState === "starting"
                          ? copy.scanning
                          : receiverState === "receiving"
                            ? `${copy.receiving} · ${receiverPercent}% · 帧 ${receiverProgress?.framesNew ?? 0}${scanHint ? ` · ${scanHint}` : ""}`
                            : receiverState === "complete" && receivedFile
                              ? `${copy.complete} · ${receivedFile.name}`
                              : receiverError
                                ? `${copy.errorPrefix} ${receiverError}`
                              : copy.cameraNote}
                      </p>
                      <div className="web-transfer-stats web-transfer-stats-inline" aria-live="polite">
                        <span>{copy.speed}<strong>{receiverSpeed}</strong></span>
                        <span>
                          {copy.progress}
                          <strong>{receiverProgress ? `${receiverPercent}%` : "—"}</strong>
                        </span>
                        <span>
                          {copy.frames}
                          <strong>{receiverProgress?.framesNew ?? 0}</strong>
                        </span>
                      </div>
                    </section>

                    <section className="web-workbench-right" aria-labelledby="web-receive-stage-title">
                      <div className="web-task-heading">
                        <span className="web-task-index">2.</span>
                        <h3 id="web-receive-stage-title">摄像头 / 完成文件</h3>
                      </div>
                      {receivedFile && receiverState === "complete" ? (
                        <div className="web-receipt" aria-live="polite">
                        <div className="web-receipt-heading">
                          <div>
                            <span className="mono-label">RECEIVED FILE</span>
                            <strong>{receivedFile.name}</strong>
                            <span>
                              {formatBytes(receivedFile.bytes.length)} · {resolvedMime(receivedFile)}
                            </span>
                          </div>
                          <span className="web-receipt-status">{copy.complete}</span>
                        </div>
                        {previewOpen && previewUrl ? (
                          <div className="web-receipt-preview" aria-label={copy.openPreview}>
                            {resolvedMime(receivedFile).startsWith("image/") && (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img src={previewUrl} alt={receivedFile.name} />
                            )}
                            {resolvedMime(receivedFile).startsWith("video/") && (
                              <video src={previewUrl} controls playsInline />
                            )}
                            {resolvedMime(receivedFile).startsWith("audio/") && (
                              <audio src={previewUrl} controls />
                            )}
                            {(resolvedMime(receivedFile).startsWith("text/") ||
                              resolvedMime(receivedFile) === "application/json" ||
                              resolvedMime(receivedFile) === "application/pdf") && (
                              <iframe title={receivedFile.name} src={previewUrl} />
                            )}
                          </div>
                        ) : (
                          <p className="web-preview-unavailable">{copy.previewUnavailable}</p>
                        )}
                        <div className="web-receipt-actions">
                          {previewUrl && (
                            <button
                              className="button button-secondary button-compact"
                              type="button"
                              onClick={() => setPreviewOpen((open) => !open)}
                            >
                              {previewOpen ? copy.closePreview : copy.openPreview}
                            </button>
                          )}
                          <button
                            className="button button-primary button-compact"
                            type="button"
                            onClick={() => openReceivedInNewTab(receivedFile)}
                          >
                            {copy.openInBrowser}
                          </button>
                          <button
                            className="button button-secondary button-compact"
                            type="button"
                            onClick={() => triggerDownload(receivedFile)}
                          >
                            {copy.saveFile}
                          </button>
                        </div>
                      </div>
                      ) : (
                        <div className={`web-camera-stage web-camera-stage-compact${cameraIsActive ? " is-active" : ""}`}>
                          <video
                            ref={receiverVideoRef}
                            className="web-camera-video"
                            aria-label={copy.scanning}
                            autoPlay
                            muted
                            playsInline
                          />
                          {!cameraIsActive && (
                            <div className="web-camera-placeholder">
                              <span>{copy.cameraIdle}</span>
                            </div>
                          )}
                          <span className="camera-corner camera-corner-tl" />
                          <span className="camera-corner camera-corner-tr" />
                          <span className="camera-corner camera-corner-bl" />
                          <span className="camera-corner camera-corner-br" />
                        </div>
                      )}
                    </section>
                  </div>
                )}
              </article>
            )}
        </div>

        <div className="web-transfer-notes web-transfer-notes-compact">
          <p>
            <strong>{copy.localNote}</strong>
            {usesCimbar ? " 当前：彩色视觉码。" : ""}
          </p>
        </div>
      </div>
    </section>
  );
}

export function webTransferSpeed(mode: QrModeChoice) {
  return formatSpeed(theoreticalSpeed(mode));
}

export function StandaloneTransferPage({ role }: { role: TransferRole }) {
  const copy =
    role === "send"
      ? {
          ...webTransferCopy,
          title: "发送文件",
          lead: "选一个文件，让另一台设备用摄像头扫描屏幕上的视觉码。",
        }
      : {
          ...webTransferCopy,
          title: "接收文件",
          lead: "打开摄像头，对准发送端的视觉码；文件会留在这台设备上。",
        };

  return (
    <main className={`site-compact transfer-page transfer-page-${role}`}>
      <header className="site-header page-shell">
        <Brand href="/" />
        <nav aria-label="传输导航">
          <a className={role === "send" ? "is-current" : ""} href="/send">
            发送
          </a>
          <a className={role === "receive" ? "is-current" : ""} href="/receive">
            接收
          </a>
          <a className="nav-download" href="/download">
            下载
          </a>
          <Link className="nav-home" href="/">
            首页
          </Link>
        </nav>
      </header>

      <WebTransfer
        copy={copy}
        initialRole={role}
        lockedRole={role}
      />

      <footer className="site-footer page-shell">
        <Brand href="/" />
        <p>OneSend · 扫传 · 本地处理</p>
        <div>
          <a href="/how">原理</a>
          <a href="/privacy">隐私</a>
        </div>
      </footer>
    </main>
  );
}
