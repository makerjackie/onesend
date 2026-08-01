import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://onesend.01mvp.com"),
  title: {
    default: "OneSend · 扫传 — 文件，用光传过去",
    template: "%s · OneSend",
  },
  description:
    "无需网络、无需配对，只用持续变化的二维码和摄像头，在手机与电脑之间离线传输文件。",
  applicationName: "OneSend",
  keywords: [
    "OneSend",
    "扫传",
    "二维码文件传输",
    "离线传输",
    "Flutter",
    "animated QR",
  ],
  authors: [{ name: "OneSend contributors" }],
  icons: {
    icon: "/icon.png",
    shortcut: "/icon.png",
    apple: "/icon.png",
  },
  openGraph: {
    type: "website",
    locale: "zh_CN",
    url: "/",
    siteName: "OneSend · 扫传",
    title: "OneSend · 扫传 — 文件，用光传过去",
    description:
      "无需网络、无需配对，只用屏幕和摄像头离线传输文件。",
    images: [
      {
        url: "/og.png",
        width: 1730,
        height: 909,
        alt: "OneSend · 扫传 — 文件，用光传过去。",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "OneSend · 扫传 — 文件，用光传过去",
    description:
      "无需网络、无需配对，只用屏幕和摄像头离线传输文件。",
    images: ["/og.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className={`${geistSans.variable} ${geistMono.variable}`}>
        {children}
      </body>
    </html>
  );
}
