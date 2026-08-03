import type { Metadata } from "next";
import Link from "next/link";

import { CimbarTransfer } from "./cimbar-client";
import styles from "./cimbar.module.css";

export const metadata: Metadata = {
  title: "彩色高速（实验）",
  description:
    "OneSend 的本地 cimbar 彩色高速实验：mode B、约 106 KB/s，不上传文件。",
};

function Brand() {
  return (
    <Link className="brand" href="/" aria-label="OneSend 首页">
      <span className="brand-mark">1</span>
      <span>OneSend</span>
    </Link>
  );
}

function Arrow() {
  return <span aria-hidden="true">↗</span>;
}

export default function CimbarPage() {
  return (
    <main className={styles.page} id="top">
      <header className="site-header page-shell">
        <Brand />
        <nav aria-label="实验页导航">
          <Link className="nav-github" href="/">
            返回 OneSend <Arrow />
          </Link>
        </nav>
      </header>

      <section className={`page-shell ${styles.hero}`} aria-labelledby="cimbar-title">
        <div>
          <div className="eyebrow">
            <span className="live-dot" /> COLOR HIGH-SPEED / EXPERIMENTAL
          </div>
          <h1 id="cimbar-title">彩色高速（实验）</h1>
          <p className={styles.heroLead}>
            基于 libcimbar v0.6.7c 的本地彩色视觉码实验。默认使用 mode B，上游特定设备参考约 106 KB/s；这不是 OneSend 真机实测，实际速度取决于屏幕、距离、光线和相机。
          </p>
          <p className={styles.experimentalNote}>
            实验功能：文件和相机画面只在你的设备内处理，不上传，也不依赖远程脚本。
          </p>
        </div>
        <div className={styles.heroFacts} aria-label="实验参数">
          <div>
            <strong>MODE B</strong>
            <span>默认彩色编码配置</span>
          </div>
          <div>
            <strong>≤ 32 MB</strong>
            <span>当前浏览器实验文件上限</span>
          </div>
          <div>
            <strong>≈ 106 KB/s</strong>
            <span>libcimbar 上游参考值</span>
          </div>
          <div>
            <strong>0 UPLOAD</strong>
            <span>同源 WASM / Worker</span>
          </div>
        </div>
      </section>

      <section className={`section ${styles.transferSection}`} aria-labelledby="cimbar-lab-title">
        <div className="page-shell">
          <div className={`section-heading ${styles.transferHeading}`}>
            <span className="section-index">01 / CIMBAR LAB</span>
            <h2 id="cimbar-lab-title">在浏览器里试一次。</h2>
            <p>
              发送端显示动态 cimbar；接收端只有在你点击按钮后才请求 camera。恢复完成后，先通过 libcimbar 的 fountain + zstd 流程，再由浏览器下载文件。
            </p>
          </div>
          <CimbarTransfer />
          <details className={styles.licenseNote}>
            <summary>许可、来源与 OneSend 的边界</summary>
            <p>
              OneSend 网站与本页 wrapper 保持 OneSend MIT；libcimbar v0.6.7c 的未修改发布 JS/WASM 是独立的 MPL-2.0 Covered Software，两套许可彼此分离。完整文本见仓库的 <code>licenses/libcimbar-MPL-2.0.txt</code> 与 <code>THIRD_PARTY_NOTICES.md</code>。
            </p>
            <p>
              对应源码提供于{" "}
              <a href="https://github.com/sz3/libcimbar/tree/e5bebd04fb777cbf31d67a7f1e35e7fa3a4cea44">
                sz3/libcimbar · v0.6.7c / e5bebd0
              </a>
              ；本页只使用同源本地资产，不在运行时从该地址加载代码。
            </p>
          </details>
        </div>
      </section>

      <footer className="site-footer page-shell">
        <Brand />
        <p>OneSend · 彩色高速（实验）</p>
        <div>
          <Link href="/">OneSend 首页</Link>
          <a href="https://github.com/sz3/libcimbar">libcimbar 源码</a>
          <span>MIT + MPL-2.0 分离</span>
        </div>
      </footer>
    </main>
  );
}
