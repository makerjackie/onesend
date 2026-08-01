import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "隐私说明",
  description: "OneSend 如何在设备本地处理文件、摄像头画面与传输记录。",
};

export default function PrivacyPage() {
  return (
    <main className="privacy-page">
      <header className="site-header page-shell">
        <Link className="brand" href="/" aria-label="返回 OneSend 首页">
          <span className="brand-mark">1</span>
          <span>OneSend</span>
        </Link>
        <nav aria-label="隐私页面导航">
          <Link className="nav-github" href="/">
            返回首页 ↙
          </Link>
        </nav>
      </header>

      <article className="privacy-document page-shell">
        <span className="section-index">PRIVACY NOTICE</span>
        <h1>隐私说明</h1>
        <p className="updated">最后更新：2026 年 8 月 1 日</p>

        <section>
          <h2>一句话版本</h2>
          <p>
            OneSend 使用屏幕和摄像头在设备之间直接传输文件。我们不运营文件服务器，也不收集文件、摄像头画面、传输记录或使用数据。
          </p>
        </section>

        <section>
          <h2>在你的设备上处理的数据</h2>
          <ul>
            <li>你选择的文件会在发送设备本地读取、压缩并编码为二维码帧。</li>
            <li>接收设备的摄像头画面只在本地用于识别二维码。</li>
            <li>还原并校验后的文件会写入 OneSend 的本地接收目录。</li>
            <li>文件名、大小、方向、时间、状态和本地路径会保存在最近传输记录中。</li>
          </ul>
        </section>

        <section>
          <h2>我们不收集的数据</h2>
          <p>
            OneSend 不包含账号系统、分析服务、广告 SDK、崩溃上报、云存储、远程文件上传或网络传输服务。应用不会把文件内容或摄像头画面发送给 OneSend 维护者。
          </p>
        </section>

        <section>
          <h2>权限</h2>
          <ul>
            <li>摄像头：仅在接收文件时扫描持续变化的二维码。</li>
            <li>文件选择与存储：用于读取你明确选择的文件，以及保存接收文件。</li>
            <li>保持屏幕唤醒：传输进行中避免设备自动休眠；暂停或完成后关闭。</li>
          </ul>
        </section>

        <section>
          <h2>安全边界</h2>
          <p>
            OneSend 是离线传输工具，不是加密工具。能完整拍摄二维码流的人也可能重建文件。传输敏感内容时，请控制屏幕和摄像头的物理可见范围，或先加密文件。
          </p>
        </section>

        <section>
          <h2>开源与联系</h2>
          <p>
            OneSend 的客户端和协议实现以 MIT License 开源。隐私问题或安全报告可以通过
            <a href="https://github.com/makerjackie/onesend/issues"> GitHub Issues </a>
            联系维护者。
          </p>
        </section>
      </article>
    </main>
  );
}
