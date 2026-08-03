"use client";

import { useEffect, useRef, useState } from "react";

import styles from "./cimbar.module.css";

const SEND_WORKER_URL = "/cimbar/node_modules/cimbar-send-bootstrap.js";
const RECEIVE_WORKER_URL = "/cimbar/node_modules/cimbar-receive-worker.js";
const MAX_INPUT_BYTES = 32 * 1024 * 1024;

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

function downloadFile(file: ReceivedFile) {
  if (file.verified !== true) return;
  const bytes = file.bytes.slice().buffer as ArrayBuffer;
  const url = URL.createObjectURL(new Blob([bytes], { type: file.mimeType }));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = file.name;
  anchor.rel = "noreferrer";
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 30_000);
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

export function CimbarTransfer() {
  const [view, setView] = useState<View>("send");
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [senderState, setSenderState] = useState<SenderState>("idle");
  const [senderFrames, setSenderFrames] = useState(0);
  const [senderError, setSenderError] = useState<string | null>(null);
  const [receiverState, setReceiverState] = useState<ReceiverState>("idle");
  const [receiverFrames, setReceiverFrames] = useState(0);
  const [decodedFrames, setDecodedFrames] = useState(0);
  const [receiverProgress, setReceiverProgress] = useState(0);
  const [receiverError, setReceiverError] = useState<string | null>(null);
  const [receivedFile, setReceivedFile] = useState<ReceivedFile | null>(null);
  const [verification, setVerification] = useState<string | null>(null);

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
        setSenderFrames(Number(data.count) || 0);
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
        worker.postMessage({ fun: "setMode", args: [68] });
        worker.postMessage({ fun: "setFPS", args: [15] });
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
    const video = receiverVideoRef.current;
    if (!receiverActiveRef.current || !video) return;

    const videoWithCallback = video as HTMLVideoElement & {
      requestVideoFrameCallback?: (callback: () => void) => number;
    };
    if (typeof videoWithCallback.requestVideoFrameCallback === "function") {
      videoWithCallback.requestVideoFrameCallback(() => {
        void sendVideoFrame();
      });
    } else {
      receiverTimerRef.current = window.setTimeout(() => {
        void sendVideoFrame();
      }, 1000 / 15);
    }
  }

  async function sendVideoFrame() {
    const video = receiverVideoRef.current;
    const worker = receiverWorkerRef.current;
    if (!receiverActiveRef.current || !video || !worker) return;

    try {
      if (receiverFramesInFlightRef.current < 2 && receiverWorkerReadyRef.current) {
        const captured = await captureVideoFrame(video);
        receiverFramesInFlightRef.current += 1;
        setReceiverFrames((count) => count + 1);
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
    setReceiverState("starting");
    setReceiverError(null);
    setReceivedFile(null);
    setVerification(null);
    setReceiverFrames(0);
    setDecodedFrames(0);
    setReceiverProgress(0);

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
          const mimeType = typeof data.mimeType === "string" && data.mimeType
            ? data.mimeType
            : "application/octet-stream";
          const file = {
            name,
            bytes,
            mimeType,
            verified: true,
          } satisfies ReceivedFile;
          stopReceiverResources();
          setReceivedFile(file);
          setReceiverProgress(1);
          setReceiverState("complete");
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
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 15, max: 15 },
        },
      });
      const [stream] = await Promise.all([streamPromise, workerReady]);
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
    setReceivedFile(null);
    setVerification(null);
    setReceiverProgress(0);
    setReceiverFrames(0);
    setDecodedFrames(0);
    setReceiverError(null);
    setReceiverState("idle");
  }

  const receiverActive = receiverState === "starting" || receiverState === "receiving";

  return (
    <div className={styles.lab}>
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
            <span className={styles.liveBadge}>≈ 106 KB/s</span>
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
              width={1024}
              height={1024}
              role="img"
              aria-label="动态 cimbar 彩色视觉码"
            />
            {!selectedFile && <span className={styles.codePlaceholder}>等待本地文件</span>}
          </div>
          <div className={styles.metrics} aria-live="polite">
            <span><small>模式</small><strong>B</strong></span>
            <span><small>参考速度</small><strong>≈ 106 KB/s</strong></span>
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
                ? "正在显示动态 cimbar；让接收设备对准此区域。"
                : senderState === "stopped"
                  ? "已停止显示；可以继续当前文件。"
                  : senderError || "选择文件后，浏览器会在本地开始编码。"}
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
            <span><small>模式</small><strong>B</strong></span>
            <span><small>恢复</small><strong>{Math.round(receiverProgress * 100)}%</strong></span>
            <span><small>扫描帧</small><strong>{receiverFrames}</strong></span>
          </div>
          <div className={styles.actions}>
            {!receiverActive && receiverState !== "complete" && (
              <button className="button button-primary" type="button" onClick={startReceiver}>
                开启 camera <span aria-hidden="true">↗</span>
              </button>
            )}
            {receiverActive && (
              <button className="button button-secondary" type="button" onClick={stopReceiver}>
                停止接收
              </button>
            )}
            {receivedFile && (
              <button className="button button-primary" type="button" onClick={() => downloadFile(receivedFile)}>
                下载已校验文件 <span aria-hidden="true">↓</span>
              </button>
            )}
            {receiverState === "complete" && (
              <button className="button button-secondary" type="button" onClick={receiveAgain}>
                重新接收
              </button>
            )}
          </div>
          <p className={styles.status} aria-live="polite">
            {receiverState === "starting"
              ? "正在请求 camera 并加载本地解码 worker…"
              : receiverState === "receiving"
                ? `正在本地恢复 fountain 帧 · 已识别 ${decodedFrames} 帧`
                : receiverState === "complete" && receivedFile
                  ? `接收完成 · ${receivedFile.name}`
                  : receiverError || "只有点击“开启 camera”后，浏览器才会请求相机权限。"}
          </p>
          {receivedFile && receiverState === "complete" && (
            <div className={styles.receivedFile}>
              <strong>{receivedFile.name}</strong>
              <span>{formatBytes(receivedFile.bytes.length)} · {verification || "正在计算 SHA-256…"}</span>
            </div>
          )}
        </article>
      </div>
    </div>
  );
}
