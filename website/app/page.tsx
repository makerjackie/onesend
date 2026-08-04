import { WebTransfer } from "./web-transfer";
import { Brand } from "./brand";

const releaseBase =
  "https://github.com/makerjackie/onesend/releases/latest/download";

const platforms = [
  {
    mark: "i",
    name: "iPhone",
    detail: "TestFlight",
    href: "https://testflight.apple.com/join/n2t1KrCp",
  },
  {
    mark: "A",
    name: "Android",
    detail: "APK",
    href: `${releaseBase}/onesend-android.apk`,
  },
  {
    mark: "W",
    name: "Windows",
    detail: "安装器",
    href: `${releaseBase}/onesend-windows-setup.exe`,
  },
  {
    mark: "M",
    name: "macOS",
    detail: "DMG",
    href: `${releaseBase}/onesend-macos-universal.dmg`,
  },
  {
    mark: "L",
    name: "Linux",
    detail: "TAR.GZ",
    href: `${releaseBase}/onesend-linux-x64.tar.gz`,
  },
];

const webTransferCopy = {
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
} as const;

function Arrow() {
  return <span aria-hidden="true">↗</span>;
}

export default function Home() {
  return (
    <main id="top" className="site-compact">
      <header className="site-header page-shell">
        <Brand href="#top" />
        <nav aria-label="主导航">
          <a href="#web-transfer">网页试用</a>
          <a href="#download">下载</a>
          <details className="more-menu">
            <summary>
              更多 <span aria-hidden="true">⌄</span>
            </summary>
            <div className="more-menu-popover">
              <a href="/how">原理</a>
              <a href="https://github.com/makerjackie/onesend">GitHub</a>
              <a href="/privacy">隐私</a>
            </div>
          </details>
        </nav>
      </header>

      <section className="hero hero-compact page-shell" aria-labelledby="hero-title">
        <div className="hero-copy">
          <div className="eyebrow">
            <span className="live-dot" /> OFFLINE · 无账号 · 端到端直连
          </div>
          <h1 id="hero-title">
            文件，用光传过去。
          </h1>
          <div className="hero-actions">
            <a className="button button-primary" href="#web-transfer">
              网页试用
            </a>
            <a className="button button-secondary" href="#download">
              下载 App
            </a>
          </div>
        </div>
      </section>

      <WebTransfer copy={webTransferCopy} />

      <section className="section download-section download-compact" id="download" aria-labelledby="download-title">
        <div className="page-shell">
          <div className="download-strip">
            <div className="download-strip-heading">
              <span className="section-index">DOWNLOAD</span>
              <h2 id="download-title">下载 OneSend / 扫传</h2>
            </div>
            <div className="platform-grid platform-grid-compact" aria-label="下载平台">
              {platforms.map((platform) => (
                <a href={platform.href} key={platform.name}>
                  <span className="platform-mark" aria-hidden="true">{platform.mark}</span>
                  <span className="platform-copy">
                    <strong>{platform.name}</strong>
                    <small>{platform.detail}</small>
                  </span>
                </a>
              ))}
            </div>
            <a
              href="https://github.com/makerjackie/onesend/releases/latest"
              className="download-more"
            >
              更多平台 <Arrow />
            </a>
          </div>
        </div>
      </section>

      <footer className="site-footer page-shell">
        <Brand href="#top" />
        <p>OneSend · 扫传 · MIT License</p>
      </footer>
    </main>
  );
}
