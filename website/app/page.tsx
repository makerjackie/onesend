"use client";

import { useEffect } from "react";

import { Brand } from "./brand";

function Arrow() {
  return <span aria-hidden="true">↗</span>;
}

function routeForLegacyHash(hash: string) {
  if (hash === "#web-transfer-receive" || hash === "#receive") return "/receive";
  if (
    hash === "#web-transfer" ||
    hash === "#web-transfer-send" ||
    hash === "#send"
  ) {
    return "/send";
  }
  if (hash === "#download") return "/download";
  return null;
}

export default function Home() {
  useEffect(() => {
    const route = routeForLegacyHash(window.location.hash);
    if (route) window.location.replace(route);
  }, []);

  return (
    <main id="top" className="site-home site-compact">
      <header className="site-header page-shell">
        <Brand href="#top" />
        <nav aria-label="主导航">
          <a href="/send">发送</a>
          <a href="/receive">接收</a>
          <a className="nav-download" href="/download">
            下载
          </a>
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

      <section className="home-hero page-shell" aria-labelledby="hero-title">
        <div className="home-hero-content">
          <span className="eyebrow">
            <span className="live-dot" /> OFFLINE · 无账号 · 本地处理
          </span>
          <h1 id="hero-title">文件，用光传过去。</h1>
          <p className="home-value">
            用屏幕和摄像头在设备之间直接传文件，不装 App，也不经过云端。
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href="/send">
              网页传输 <Arrow />
            </a>
            <a className="button button-secondary" href="/receive">
              接收文件
            </a>
          </div>
          <a className="home-download-link" href="/download">
            下载 OneSend <Arrow />
          </a>
        </div>
      </section>

      <footer className="site-footer page-shell">
        <Brand href="#top" />
        <p>OneSend · 扫传 · MIT License</p>
        <div>
          <a href="/how">原理</a>
          <a href="/privacy">隐私</a>
        </div>
      </footer>
    </main>
  );
}
