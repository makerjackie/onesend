import type { Metadata } from "next";
import Link from "next/link";
import { Brand } from "../brand";

export const metadata: Metadata = {
  title: "原理 · OneSend",
  description: "OneSend 如何用视觉码离线传文件。",
};

export default function HowPage() {
  return (
    <main id="top">
      <header className="site-header page-shell">
        <Brand href="/" />
        <nav aria-label="导航">
          <Link href="/#web-transfer">试用</Link>
          <Link href="/#download">下载</Link>
          <Link className="nav-github" href="/">
            返回首页
          </Link>
        </nav>
      </header>

      <section className="section page-shell how-page">
        <span className="section-index">HOW IT WORKS</span>
        <h1 className="how-title">三步，文件穿过空气。</h1>
        <p className="how-lead">
          OneSend 使用单向光学通道：发送端只显示，接收端随时加入扫描。无网络、无配对、无上传。
        </p>

        <div className="steps-grid how-steps">
          <article>
            <span className="step-number">01</span>
            <h3>选文件</h3>
            <p>文件留在本机，封装文件名与校验信息。</p>
          </article>
          <article>
            <span className="step-number">02</span>
            <h3>持续显示</h3>
            <p>按所选模式生成标准 / 兼容 / 快速二维码或彩色码流。</p>
          </article>
          <article>
            <span className="step-number">03</span>
            <h3>扫描还原</h3>
            <p>摄像头边扫边恢复，校验通过后保存到本机。</p>
          </article>
        </div>

        <div className="how-modes">
          <h2>传输模式</h2>
          <ul>
            <li>
              <strong>标准（推荐）</strong> — 日常默认，约 33 KB/s
            </li>
            <li>
              <strong>兼容</strong> — 更稳更慢，约 4.7 KB/s
            </li>
            <li>
              <strong>快速</strong> — 更快，约 56 KB/s，对设备要求更高
            </li>
            <li>
              <strong>彩色（实验）</strong> — 峰值更高，两端都要选彩色
            </li>
          </ul>
          <p className="how-note">
            两端请选同一模式。彩色与二维码互不兼容。什么都不改时使用标准。
          </p>
        </div>

        <div className="how-privacy">
          <h2>隐私</h2>
          <p>
            没有账号、分析、广告或文件服务器。画面与文件只在设备本地处理。
          </p>
          <Link href="/privacy" className="text-link">
            隐私说明 ↗
          </Link>
        </div>
      </section>

      <footer className="site-footer page-shell">
        <Brand href="/" />
        <p>OneSend · 扫传</p>
        <div>
          <Link href="/">首页</Link>
          <Link href="/privacy">隐私</Link>
        </div>
      </footer>
    </main>
  );
}
