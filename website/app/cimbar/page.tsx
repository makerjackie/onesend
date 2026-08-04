import { redirect } from "next/navigation";

/**
 * Color high-speed (cimbar) lives in the main web-transfer mode switcher now.
 * Keep this route as a short redirect so old bookmarks still work.
 */
export default function CimbarPage() {
  redirect("/#web-transfer");
}
