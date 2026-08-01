import Image from "next/image";

const releaseBase =
  "https://github.com/makerjackie/onesend/releases/latest/download";

const platforms = [
  {
    mark: "A",
    name: "Android",
    detail: "APK · arm64 / x64",
    href: `${releaseBase}/onesend-android.apk`,
    action: "下载 APK",
  },
  {
    mark: "M",
    name: "macOS",
    detail: "已公证 DMG · Apple Silicon / Intel",
    href: `${releaseBase}/onesend-macos.dmg`,
    action: "下载 DMG",
  },
  {
    mark: "W",
    name: "Windows",
    detail: "ZIP · Windows 10+",
    href: `${releaseBase}/onesend-windows.zip`,
    action: "下载 ZIP",
  },
  {
    mark: "L",
    name: "Linux",
    detail: "TAR.GZ · x64",
    href: `${releaseBase}/onesend-linux.tar.gz`,
    action: "下载 TAR.GZ",
  },
];

function qrMatrix(seed: number) {
  const size = 21;
  return Array.from({ length: size * size }, (_, index) => {
    const x = index % size;
    const y = Math.floor(index / size);
    const finder = (originX: number, originY: number) => {
      const dx = x - originX;
      const dy = y - originY;
      if (dx < 0 || dx > 6 || dy < 0 || dy > 6) return false;
      return (
        dx === 0 ||
        dx === 6 ||
        dy === 0 ||
        dy === 6 ||
        (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4)
      );
    };
    const inFinderArea =
      (x <= 7 && y <= 7) ||
      (x >= size - 8 && y <= 7) ||
      (x <= 7 && y >= size - 8);
    if (inFinderArea) {
      return (
        finder(0, 0) || finder(size - 7, 0) || finder(0, size - 7)
      );
    }
    return ((x * 11 + y * 7 + x * y + seed * (x + 3 * y)) % 9) < 4;
  });
}

const qrFrames = [qrMatrix(3), qrMatrix(7), qrMatrix(11)];

function Brand() {
  return (
    <a className="brand" href="#top" aria-label="OneSend 首页">
      <span className="brand-mark">1</span>
      <span>OneSend</span>
    </a>
  );
}

function Arrow() {
  return <span aria-hidden="true">↗</span>;
}

export default function Home() {
  return (
    <main id="top">
      <header className="site-header page-shell">
        <Brand />
        <nav aria-label="主导航">
          <a href="#how">原理</a>
          <a href="#reliability">可靠性</a>
          <a href="#download">下载</a>
          <a
            className="nav-github"
            href="https://github.com/makerjackie/onesend"
          >
            GitHub <Arrow />
          </a>
        </nav>
      </header>

      <section className="hero page-shell" aria-labelledby="hero-title">
        <div className="hero-copy">
          <div className="eyebrow">
            <span className="live-dot" /> OFFLINE OPTICAL TRANSFER
          </div>
          <h1 id="hero-title">
            文件，
            <br />
            用光传过去。
          </h1>
          <p className="hero-lead">
            不用网络，不用配对。OneSend 把文件变成持续变化的二维码，另一台设备只用摄像头就能接收。
          </p>
          <div className="hero-actions">
            <a
              className="button button-primary"
              href="https://github.com/makerjackie/onesend/releases/latest"
            >
              下载 OneSend <Arrow />
            </a>
            <a
              className="button button-secondary"
              href="https://github.com/makerjackie/onesend"
            >
              查看源码
            </a>
          </div>
          <ul className="trust-row" aria-label="产品特性">
            <li>无需网络</li>
            <li>无需账号</li>
            <li>MIT 开源</li>
          </ul>
        </div>

        <div className="hero-demo" aria-label="OneSend 光学传输演示">
          <div className="demo-glow" />
          <div className="phone-frame receiver-phone">
            <div className="phone-island" />
            <div className="app-shot-window">
              <Image
                src="/app-home.png"
                alt="OneSend iPhone 首页"
                width={1206}
                height={2622}
                priority
                unoptimized
              />
            </div>
          </div>

          <div className="light-path" aria-hidden="true">
            <i />
            <i />
            <i />
          </div>

          <div className="sender-panel">
            <div className="window-bar">
              <span />
              <span />
              <span />
              <b>OneSend · 可靠模式</b>
            </div>
            <div className="qr-stage">
              <div className="qr-stack" aria-hidden="true">
                {qrFrames.map((frame, frameIndex) => (
                  <div
                    className={`qr-layer qr-layer-${frameIndex + 1}`}
                    key={frameIndex}
                  >
                    {frame.map((dark, index) => (
                      <span className={dark ? "dark" : ""} key={index} />
                    ))}
                  </div>
                ))}
              </div>
              <div className="frame-counter">
                <span>持续播放</span>
                <b>08 fps</b>
              </div>
            </div>
            <div className="file-progress">
              <span className="file-icon">TXT</span>
              <div>
                <strong>field-notes.txt</strong>
                <small>第 2 轮 · 原始块 + 修复块</small>
              </div>
              <em>↗</em>
            </div>
          </div>
        </div>
      </section>

      <section className="signal-strip" aria-label="OneSend 协议摘要">
        <div className="page-shell signal-grid">
          <div>
            <strong>2</strong>
            <span>可靠 / 快速模式</span>
          </div>
          <div>
            <strong>4+1</strong>
            <span>原始块 + 修复块交织</span>
          </div>
          <div>
            <strong>CRC32</strong>
            <span>逐帧与完整文件校验</span>
          </div>
          <div>
            <strong>0</strong>
            <span>服务器、账号与云上传</span>
          </div>
        </div>
      </section>

      <section className="section page-shell" id="how">
        <div className="section-heading split-heading">
          <div>
            <span className="section-index">01 / HOW IT WORKS</span>
            <h2>三步，文件穿过空气。</h2>
          </div>
          <p>
            OneSend 使用单向光学通道。发送端只负责不断显示，接收端可以在任意时刻加入。
          </p>
        </div>
        <div className="steps-grid">
          <article>
            <span className="step-number">01</span>
            <div className="step-icon lime">↗</div>
            <h3>选择文件</h3>
            <p>文件留在本机，自动封装文件名、类型、长度和完整性校验。</p>
          </article>
          <article>
            <span className="step-number">02</span>
            <div className="step-icon blue">▦</div>
            <h3>持续显示</h3>
            <p>原始块和 LT 修复块交织成二维码流，漏掉几帧也不必重来。</p>
          </article>
          <article>
            <span className="step-number">03</span>
            <div className="step-icon cream">◎</div>
            <h3>扫描还原</h3>
            <p>摄像头边扫边恢复，校验通过后保存，可立即打开或系统分享。</p>
          </article>
        </div>
      </section>

      <section className="section modes-section" id="modes">
        <div className="page-shell">
          <div className="section-heading centered-heading">
            <span className="section-index">02 / TWO PROFILES</span>
            <h2>先稳，再快。</h2>
            <p>可靠模式是默认选择；当两台设备固定、光线稳定时，再切到快速模式。</p>
          </div>
          <div className="mode-grid">
            <article className="mode-card mode-reliable">
              <div className="mode-topline">
                <span>RELIABLE</span>
                <b>默认</b>
              </div>
              <h3>可靠模式</h3>
              <p>更强的二维码纠错，更从容的刷新节奏，适合手持和普通环境。</p>
              <dl>
                <div>
                  <dt>帧率</dt>
                  <dd>约 8 fps</dd>
                </div>
                <div>
                  <dt>每帧</dt>
                  <dd>720 B</dd>
                </div>
                <div>
                  <dt>QR 纠错</dt>
                  <dd>Medium</dd>
                </div>
              </dl>
            </article>
            <article className="mode-card mode-fast">
              <div className="mode-topline">
                <span>FAST</span>
                <b>清晰环境</b>
              </div>
              <h3>快速模式</h3>
              <p>更高的数据密度和刷新率，适合支架固定、屏幕明亮、对焦稳定。</p>
              <dl>
                <div>
                  <dt>帧率</dt>
                  <dd>约 15 fps</dd>
                </div>
                <div>
                  <dt>每帧</dt>
                  <dd>1320 B</dd>
                </div>
                <div>
                  <dt>QR 纠错</dt>
                  <dd>Low</dd>
                </div>
              </dl>
            </article>
          </div>
        </div>
      </section>

      <section className="section page-shell reliability" id="reliability">
        <div className="reliability-visual" aria-hidden="true">
          <div className="packet-labels">
            <span>SOURCE</span>
            <span>REPAIR</span>
          </div>
          <div className="packet-track packet-track-one">
            {Array.from({ length: 16 }, (_, index) => (
              <i
                className={index === 4 || index === 11 ? "lost" : "source"}
                key={index}
              />
            ))}
          </div>
          <div className="packet-track packet-track-two">
            {Array.from({ length: 16 }, (_, index) => (
              <i
                className={index % 5 === 4 ? "repair" : "source"}
                key={index}
              />
            ))}
          </div>
          <div className="recovered-badge">✓ 已恢复缺失块</div>
        </div>
        <div className="reliability-copy">
          <span className="section-index">03 / BUILT FOR LOSS</span>
          <h2>漏帧，不等于失败。</h2>
          <p>
            摄像头会受抖动、反光、滚动快门和自动对焦影响。OneSend 不假设每一帧都会被看见，而是从协议层接受丢失。
          </p>
          <ul className="check-list">
            <li>受损二维码先通过逐帧 CRC32 拒绝</li>
            <li>乱序、重复和中途加入都可继续恢复</li>
            <li>暂停后保留当前进度，继续扫描即可</li>
            <li>最终文件再次校验原文长度与 CRC32</li>
          </ul>
        </div>
      </section>

      <section className="section download-section" id="download">
        <div className="page-shell">
          <div className="section-heading split-heading download-heading">
            <div>
              <span className="section-index">04 / DOWNLOAD</span>
              <h2>你的设备，应该都能用。</h2>
            </div>
            <a
              href="https://github.com/makerjackie/onesend/releases/latest"
              className="text-link"
            >
              查看版本与 SHA256 <Arrow />
            </a>
          </div>
          <div className="platform-grid">
            {platforms.map((platform) => (
              <a href={platform.href} key={platform.name}>
                <span className="platform-mark">{platform.mark}</span>
                <div>
                  <strong>{platform.name}</strong>
                  <small>{platform.detail}</small>
                </div>
                <em>{platform.action} ↗</em>
              </a>
            ))}
            <div className="platform-testflight" id="testflight">
              <span className="platform-mark">i</span>
              <div>
                <strong>iPhone / iPad</strong>
                <small>TestFlight 公测</small>
              </div>
              <em>审核准备中</em>
            </div>
          </div>
        </div>
      </section>

      <section className="section privacy-section page-shell">
        <div className="privacy-card">
          <div>
            <span className="section-index">PRIVACY BY ABSENCE</span>
            <h2>不是“少上传”，是根本没有上传。</h2>
          </div>
          <div>
            <p>
              没有账号、分析 SDK、广告、云存储或文件服务器。摄像头画面和文件内容只在你的设备上处理。
            </p>
            <a href="/privacy" className="text-link">
              阅读隐私说明 <Arrow />
            </a>
          </div>
        </div>
        <p className="security-note">
          OneSend 是离线传输工具，不是加密工具。能完整看到二维码流的人也可能重建文件。
        </p>
      </section>

      <section className="open-source page-shell">
        <span className="source-orbit" aria-hidden="true">MIT</span>
        <div>
          <span className="section-index">OPEN SOURCE</span>
          <h2>简单到可以看清，可靠到值得改进。</h2>
          <p>协议、Flutter 客户端、测试和发布流程全部公开。欢迎审计、提交问题和贡献代码。</p>
        </div>
        <a
          className="button button-light"
          href="https://github.com/makerjackie/onesend"
        >
          GitHub 上查看 <Arrow />
        </a>
      </section>

      <footer className="site-footer page-shell">
        <Brand />
        <p>OneSend · 一传 — 文件，用光传过去。</p>
        <div>
          <a href="/privacy">隐私</a>
          <a href="https://github.com/makerjackie/onesend/blob/main/LICENSE">
            MIT License
          </a>
          <span>© 2026 OneSend contributors</span>
        </div>
      </footer>
    </main>
  );
}
