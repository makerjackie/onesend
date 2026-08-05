import type { Metadata } from "next";
import Link from "next/link";

import { Brand } from "../brand";

export const metadata: Metadata = {
  title: "下载 OneSend",
  description: "下载 OneSend 扫传客户端，在手机和电脑之间离线传输文件。",
};

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

function Arrow() {
  return <span aria-hidden="true">↗</span>;
}

export default function DownloadPage() {
  return (
    <main className="site-compact download-page">
      <header className="site-header page-shell">
        <Brand href="/" />
        <nav aria-label="下载导航">
          <a href="/send">发送</a>
          <a href="/receive">接收</a>
          <a className="is-current" href="/download">
            下载
          </a>
          <a
            className="nav-github"
            href="https://github.com/makerjackie/onesend"
            target="_blank"
            rel="noreferrer"
          >
            GitHub
          </a>
          <Link className="nav-home" href="/">
            首页
          </Link>
        </nav>
      </header>

      <section className="download-hero page-shell" aria-labelledby="download-title">
        <span className="section-index">DOWNLOAD</span>
        <h1 id="download-title">把 OneSend 带到每台设备。</h1>
        <p>
          网页版适合临时传输；安装客户端后，可以更稳定地在手机和电脑之间扫传。
        </p>
      </section>

      <section className="download-list page-shell" aria-label="下载平台">
        <div className="download-list-heading">
          <span className="mono-label">AVAILABLE BUILDS</span>
          <p>选择你的平台，下载最新版本。</p>
        </div>
        <div className="platform-grid platform-grid-compact">
          {platforms.map((platform) => (
            <a href={platform.href} key={platform.name}>
              <span className="platform-mark" aria-hidden="true">
                {platform.mark}
              </span>
              <span className="platform-copy">
                <strong>{platform.name}</strong>
                <small>{platform.detail}</small>
              </span>
              <Arrow />
            </a>
          ))}
        </div>
        <a
          href="https://github.com/makerjackie/onesend/releases/latest"
          className="download-release-link"
        >
          查看全部版本与校验信息 <Arrow />
        </a>
      </section>

      <footer className="site-footer page-shell">
        <Brand href="/" />
        <p>OneSend · 扫传 · MIT License</p>
        <div>
          <a href="/how">原理</a>
          <a href="/privacy">隐私</a>
        </div>
      </footer>
    </main>
  );
}
