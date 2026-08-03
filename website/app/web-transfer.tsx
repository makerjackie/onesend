"use client";

import QRCode from "qrcode";
import { useEffect, useRef, useState } from "react";
import { ResultMetadataType } from "@zxing/library";

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
  senderTitle: string;
  receiverTitle: string;
  fileChooser: string;
  noFile: string;
  chooseFile: string;
  mode: string;
  fast: string;
  reliable: string;
  fastDetail: string;
  reliableDetail: string;
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
  receiveAgain: string;
  cameraNote: string;
  localNote: string;
  interopNote: string;
  browserOnly: string;
  preparing: string;
  errorPrefix: string;
};

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
  getResultMetadata?: () => Map<ResultMetadataType, unknown>;
  getRawBytes?: () => Uint8Array;
};

type ReceiverSnapshot = {
  progress: number;
  totalLength: number;
  framesNew: number;
};

function drawQr(canvas: HTMLCanvasElement, bytes: Uint8Array, mode: "fast" | "reliable") {
  const config = TRANSFER_MODES[mode];
  const maskPattern = bytes.length >= 4 ? bytes[bytes.length - 4] & 7 : 0;
  const symbol = QRCode.create(
    [{ data: new Uint8ClampedArray(bytes), mode: "byte" }],
    {
      errorCorrectionLevel: config.errorCorrectionLevel,
      maskPattern,
    },
  );
  const marginModules = 4;
  const totalModules = symbol.modules.size + marginModules * 2;
  const physicalModuleSize = Math.max(
    1,
    Math.floor(canvas.width / totalModules),
  );
  const renderedSize = physicalModuleSize * totalModules;
  const origin = Math.floor((canvas.width - renderedSize) / 2);
  const context = canvas.getContext("2d");
  if (!context) throw new Error("The browser cannot draw a visual code.");
  context.imageSmoothingEnabled = false;
  context.fillStyle = "#ffffff";
  context.fillRect(0, 0, canvas.width, canvas.height);
  context.fillStyle = "#000000";
  for (let row = 0; row < symbol.modules.size; row += 1) {
    for (let column = 0; column < symbol.modules.size; column += 1) {
      if (!symbol.modules.get(row, column)) continue;
      context.fillRect(
        origin + (column + marginModules) * physicalModuleSize,
        origin + (row + marginModules) * physicalModuleSize,
        physicalModuleSize,
        physicalModuleSize,
      );
    }
  }
}

function triggerDownload(file: ReceivedFile) {
  const url = URL.createObjectURL(new Blob([file.bytes], { type: file.mimeType }));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = file.name;
  anchor.rel = "noreferrer";
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 30_000);
}

function describeError(error: unknown) {
  if (error instanceof Error && error.message) return error.message;
  return "The browser could not complete this local transfer.";
}

export function WebTransfer({ copy }: { copy: WebTransferCopy }) {
  const [mode, setMode] = useState<"fast" | "reliable">("fast");
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
  const [receivedFile, setReceivedFile] = useState<ReceivedFile | null>(null);
  const [receiverError, setReceiverError] = useState<string | null>(null);

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

  useEffect(() => {
    return () => {
      clearSenderTimer();
      stopCameraTracks();
    };
  }, []);

  async function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    if (!file) return;
    clearSenderTimer();
    setSenderError(null);
    setSenderState("preparing");
    try {
      if (file.size > 64 * 1024 * 1024) {
        throw new Error("Files must be 64 MB or smaller.");
      }
      const bytes = new Uint8Array(await file.arrayBuffer());
      const payload = encodeTransferFile({
        name: file.name,
        mimeType: file.type || "application/octet-stream",
        bytes,
      });
      senderRef.current = new OpticalSender(payload, mode);
      setSenderReady(true);
      senderStartedAtRef.current = null;
      senderFramesRef.current = 0;
      setSelectedFile({
        name: file.name,
        mimeType: file.type || "application/octet-stream",
        size: file.size,
      });
      setSenderProgress(0);
      setSenderPass(1);
      setSenderSpeed("—");
      setSenderState("ready");
    } catch (error) {
      senderRef.current = null;
      setSenderReady(false);
      setSenderState("idle");
      setSenderError(describeError(error));
    }
  }

  function emitSenderFrame() {
    const sender = senderRef.current;
    const canvas = senderCanvasRef.current;
    if (!sender || !canvas) return;
    try {
      const frame = sender.nextFrame();
      drawQr(canvas, frame.bytes, mode);
      senderFramesRef.current += 1;
      const elapsed = Math.max(1, Date.now() - (senderStartedAtRef.current ?? Date.now()));
      const usefulBytes = senderFramesRef.current * sender.mode.blockLength * 4 / 5;
      setSenderProgress(frame.passProgress);
      setSenderPass(frame.passNumber);
      setSenderSpeed(formatSpeed(usefulBytes * 1000 / elapsed));
    } catch (error) {
      clearSenderTimer();
      setSenderState("ready");
      setSenderError(describeError(error));
    }
  }

  function startSender() {
    if (!senderRef.current) return;
    clearSenderTimer();
    senderStartedAtRef.current ??= Date.now();
    setSenderError(null);
    setSenderState("sending");
    emitSenderFrame();
    senderTimerRef.current = window.setInterval(
      emitSenderFrame,
      Math.max(42, Math.round(TRANSFER_MODES[mode].frameIntervalMs)),
    );
  }

  function pauseSender() {
    clearSenderTimer();
    if (senderRef.current) setSenderState("paused");
  }

  function endSender() {
    clearSenderTimer();
    senderRef.current = null;
    setSenderReady(false);
    senderStartedAtRef.current = null;
    setSenderProgress(0);
    setSenderPass(1);
    setSenderSpeed("—");
    setSenderState("idle");
    const canvas = senderCanvasRef.current;
    const context = canvas?.getContext("2d");
    if (canvas && context) {
      context.fillStyle = "#ffffff";
      context.fillRect(0, 0, canvas.width, canvas.height);
    }
  }

  function handleModeChange(nextMode: "fast" | "reliable") {
    if (senderState === "sending" || senderState === "paused") return;
    setMode(nextMode);
    if (selectedFile) endSender();
  }

  async function handleScannerResult(result: ScannerResult) {
    const rawBytes = extractScannerFrame(result);
    if (!rawBytes) return;
    const event = receiverRef.current.consume(rawBytes);
    if (!event?.snapshot) return;
    setReceiverProgress({
      progress: event.snapshot.progress,
      totalLength: event.snapshot.totalLength,
      framesNew: event.snapshot.framesNew,
    });
    const elapsed = Math.max(1, Date.now() - (receiverStartedAtRef.current ?? Date.now()));
    setReceiverSpeed(formatSpeed((event.snapshot.framesNew * (event.snapshot.totalLength / Math.max(1, event.snapshot.blockCount))) * 1000 / elapsed));
    if (event.error) {
      setReceiverState("error");
      setReceiverError(event.error);
      return;
    }
    if (!event.payload || !event.verified) return;
    try {
      const file = await decodeTransferFile(event.payload);
      stopCameraTracks();
      setReceivedFile(file);
      setReceiverState("complete");
      triggerDownload(file);
    } catch (error) {
      setReceiverState("error");
      setReceiverError(describeError(error));
    }
  }

  async function startCamera() {
    if (!navigator.mediaDevices?.getUserMedia) {
      setReceiverState("error");
      setReceiverError("Camera access is unavailable. Use a secure HTTPS page in a supported browser.");
      return;
    }
    stopCameraTracks();
    receiverRef.current.reset();
    setReceivedFile(null);
    setReceiverProgress(null);
    setReceiverSpeed("—");
    setReceiverError(null);
    setReceiverState("starting");
    receiverStartedAtRef.current = Date.now();
    try {
      const { BrowserQRCodeReader } = await import("@zxing/browser");
      const video = receiverVideoRef.current;
      if (!video) throw new Error("The camera preview is not ready.");
      const reader = new BrowserQRCodeReader();
      const controls = await reader.decodeFromConstraints(
        {
          audio: false,
          video: {
            facingMode: { ideal: "environment" },
            width: { ideal: 1280 },
            height: { ideal: 720 },
          },
        },
        video,
        (result) => {
          if (result) void handleScannerResult(result);
        },
      );
      scannerControlsRef.current = controls;
      cameraStreamRef.current = video.srcObject as MediaStream | null;
      setReceiverState("receiving");
    } catch (error) {
      stopCameraTracks();
      setReceiverState("error");
      setReceiverError(describeError(error));
    }
  }

  function stopCamera() {
    stopCameraTracks();
    if (receiverState !== "complete") setReceiverState("idle");
  }

  function receiveAgain() {
    stopCameraTracks();
    receiverRef.current.reset();
    setReceivedFile(null);
    setReceiverProgress(null);
    setReceiverSpeed("—");
    setReceiverError(null);
    setReceiverState("idle");
  }

  const senderIsActive = senderState === "sending" || senderState === "paused";
  const cameraIsActive = receiverState === "starting" || receiverState === "receiving";
  const receiverPercent = Math.round((receiverProgress?.progress ?? 0) * 100);

  return (
    <section className="section gray-section web-transfer-section" id="web-transfer" aria-labelledby="web-transfer-title">
      <div className="page-shell">
        <div className="section-heading section-heading-wide">
          <span className="section-index">{copy.eyebrow}</span>
          <h2 id="web-transfer-title">{copy.title}</h2>
          <p>{copy.lead}</p>
          <div className="web-transfer-badges" aria-label={copy.localBadge}>
            <span>{copy.localBadge}</span>
            <span>{copy.browserOnly}</span>
          </div>
        </div>

        <div className="web-transfer-grid">
          <article className="web-transfer-card">
            <div className="web-transfer-card-heading">
              <span className="card-index">01</span>
              <div>
                <span className="mono-label">WEB SENDER</span>
                <h3>{copy.senderTitle}</h3>
              </div>
            </div>
            <label className="web-file-picker" htmlFor="web-transfer-file">
              <span className="web-file-picker-mark" aria-hidden="true">＋</span>
              <span>
                <strong>{selectedFile?.name ?? copy.chooseFile}</strong>
                <small>{selectedFile ? `${formatBytes(selectedFile.size)} · ${selectedFile.mimeType}` : copy.noFile}</small>
              </span>
            </label>
            <input
              ref={fileInputRef}
              className="visually-hidden"
              id="web-transfer-file"
              type="file"
              onChange={handleFileChange}
            />

            <div className="web-mode-control">
              <span className="mono-label">{copy.mode}</span>
              <div className="web-mode-options" role="group" aria-label={copy.mode}>
                <button
                  className={mode === "fast" ? "is-selected" : ""}
                  type="button"
                  aria-pressed={mode === "fast"}
                  onClick={() => handleModeChange("fast")}
                >
                  {copy.fast}<small>{copy.fastDetail}</small>
                </button>
                <button
                  className={mode === "reliable" ? "is-selected" : ""}
                  type="button"
                  aria-pressed={mode === "reliable"}
                  onClick={() => handleModeChange("reliable")}
                >
                  {copy.reliable}<small>{copy.reliableDetail}</small>
                </button>
              </div>
            </div>

            <div className="web-code-stage">
              <canvas
                ref={senderCanvasRef}
                className="web-code-canvas"
                width={600}
                height={600}
                role="img"
                aria-label={copy.displayCode}
              />
              {!selectedFile && <span className="web-code-placeholder">{copy.noFile}</span>}
            </div>
            <div className="web-transfer-stats" aria-live="polite">
              <span>{copy.speed}<strong>{senderSpeed}</strong></span>
              <span>{copy.progress}<strong>{Math.round(senderProgress * 100)}%</strong></span>
              <span>{copy.pass}<strong>{senderPass}</strong></span>
            </div>
            <div className="web-transfer-actions">
              {!senderIsActive && (
                <button className="button button-primary" type="button" disabled={!senderReady || senderState === "preparing"} onClick={startSender}>
                  {senderState === "preparing" ? copy.preparing : copy.displayCode} <span aria-hidden="true">↗</span>
                </button>
              )}
              {senderState === "sending" && <button className="button button-secondary" type="button" onClick={pauseSender}>{copy.pause}</button>}
              {senderState === "paused" && <button className="button button-primary" type="button" onClick={startSender}>{copy.resume}</button>}
              {senderIsActive && <button className="button button-secondary" type="button" onClick={endSender}>{copy.stop}</button>}
            </div>
            <p className="web-status" aria-live="polite">
              {senderState === "sending" ? `${copy.sending} · ${copy.pass} ${senderPass}` : senderState === "paused" ? copy.paused : senderState === "ready" ? copy.readyToSend : senderError ? `${copy.errorPrefix} ${senderError}` : copy.noFile}
            </p>
          </article>

          <article className="web-transfer-card">
            <div className="web-transfer-card-heading">
              <span className="card-index">02</span>
              <div>
                <span className="mono-label">WEB RECEIVER</span>
                <h3>{copy.receiverTitle}</h3>
              </div>
            </div>
            <div className={`web-camera-stage${cameraIsActive ? " is-active" : ""}`}>
              <video
                ref={receiverVideoRef}
                className="web-camera-video"
                aria-label={copy.scanning}
                autoPlay
                muted
                playsInline
              />
              {!cameraIsActive && <div className="web-camera-placeholder"><b>◎</b><span>{copy.cameraIdle}</span></div>}
              <span className="camera-corner camera-corner-tl" />
              <span className="camera-corner camera-corner-tr" />
              <span className="camera-corner camera-corner-bl" />
              <span className="camera-corner camera-corner-br" />
            </div>
            <div className="web-transfer-stats" aria-live="polite">
              <span>{copy.speed}<strong>{receiverSpeed}</strong></span>
              <span>{copy.progress}<strong>{receiverProgress ? `${receiverPercent}%` : "—"}</strong></span>
              <span>{copy.frames}<strong>{receiverProgress?.framesNew ?? 0}</strong></span>
            </div>
            <div className="web-transfer-actions">
              {!cameraIsActive && receiverState !== "complete" && (
                <button className="button button-primary" type="button" onClick={startCamera}>
                  {copy.startCamera} <span aria-hidden="true">↗</span>
                </button>
              )}
              {cameraIsActive && <button className="button button-secondary" type="button" onClick={stopCamera}>{copy.stopCamera}</button>}
              {receivedFile && <button className="button button-primary" type="button" onClick={() => triggerDownload(receivedFile)}>{copy.download} <span aria-hidden="true">↓</span></button>}
              {receiverState === "complete" && <button className="button button-secondary" type="button" onClick={receiveAgain}>{copy.receiveAgain}</button>}
            </div>
            <p className="web-status" aria-live="polite">
              {receiverState === "starting" ? copy.scanning : receiverState === "receiving" ? `${copy.receiving} · ${receiverPercent}%` : receiverState === "complete" && receivedFile ? `${copy.complete} · ${receivedFile.name}` : receiverError ? `${copy.errorPrefix} ${receiverError}` : copy.cameraNote}
            </p>
            {receivedFile && receiverState === "complete" && (
              <div className="web-received-file">
                <strong>{receivedFile.name}</strong>
                <span>{formatBytes(receivedFile.bytes.length)} · {receivedFile.mimeType}</span>
              </div>
            )}
          </article>
        </div>

        <div className="web-transfer-notes">
          <p><strong>{copy.localNote}</strong> {copy.interopNote}</p>
          <a className="text-link" href="/cimbar">试用彩色高速实验 <span aria-hidden="true">↗</span></a>
        </div>
      </div>
    </section>
  );
}

export function webTransferSpeed(mode: "fast" | "reliable") {
  return formatSpeed(theoreticalSpeed(mode));
}
