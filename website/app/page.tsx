"use client";

import Image from "next/image";
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
          <a
            className="nav-github"
            href="https://github.com/makerjackie/onesend"
            target="_blank"
            rel="noreferrer"
          >
            GitHub
          </a>
          <details className="more-menu">
            <summary>
              更多 <span aria-hidden="true">⌄</span>
            </summary>
            <div className="more-menu-popover">
              <a href="/how">原理</a>
              <a href="/privacy">隐私</a>
            </div>
          </details>
        </nav>
      </header>

      <section className="home-hero page-shell" aria-labelledby="hero-title">
        <div className="home-hero-grid">
          <div className="home-hero-content">
            <span className="eyebrow">
              <span className="live-dot" /> OFFLINE · 无账号 · 本地处理
            </span>
            <h1 id="hero-title">
              文件，<br />用光传过去。
            </h1>
            <p className="home-value">
              其实就是扫码传文件：一端屏幕播视觉码，另一端摄像头扫，文件在本地还原。不经云端；手机打开网页也能发、也能收。
            </p>

            {/*
              Product model (mobile-first):
              - Web transfer is TWO equal jobs: send OR receive — never collapse
                to a single "/send" button that hides receive.
              - Download is important but secondary for "I just need to transfer
                now without installing".
            */}
            <div className="hero-actions" aria-label="开始传输">
              <p className="hero-actions-label">网页传文件 · 不用装 App</p>
              <div className="hero-actions-row hero-actions-web">
                <a className="button button-primary" href="/send">
                  发送
                </a>
                <a className="button button-primary" href="/receive">
                  接收
                </a>
              </div>
              <a className="button button-secondary hero-download-cta" href="/download">
                下载 OneSend <Arrow />
              </a>
              <p className="hero-actions-hint">
                装 App 更稳、更好调摄像头；只传一次，用网页就够。
              </p>
            </div>
          </div>

          <aside className="home-hero-visual" aria-label="扫码传文件示意">
            <figure className="hero-demo-card">
              <Image
                className="hero-demo-mark"
                src="/hero-scan-mark.png"
                width={480}
                height={480}
                alt="文件变成视觉码，再被扫描框对准 — 扫码传文件"
                priority
                unoptimized
              />
              <figcaption className="hero-demo-caption">
                <span>屏幕播码</span>
                <span className="hero-demo-caption-arrow" aria-hidden="true">
                  →
                </span>
                <span>摄像头扫</span>
                <span className="hero-demo-caption-arrow" aria-hidden="true">
                  →
                </span>
                <span>文件到手</span>
              </figcaption>
              <p className="hero-demo-note">屏幕 ↔ 摄像头 · 只走光，不走网</p>
            </figure>
          </aside>
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
