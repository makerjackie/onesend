import type { Metadata } from "next";

import { StandaloneTransferPage } from "../web-transfer";

export const metadata: Metadata = {
  title: "接收文件",
  description: "用 OneSend 网页端扫描视觉码，在本地接收文件。",
};

export default function ReceivePage() {
  return <StandaloneTransferPage role="receive" />;
}
