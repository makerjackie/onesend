import type { Metadata } from "next";

import { StandaloneTransferPage } from "../web-transfer";

export const metadata: Metadata = {
  title: "发送文件",
  description: "用 OneSend 网页端把文件显示为视觉码，发送到另一台设备。",
};

export default function SendPage() {
  return <StandaloneTransferPage role="send" />;
}
