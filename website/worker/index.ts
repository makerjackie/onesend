/** Cloudflare Worker entry point for the vinext-starter template. */
import { handleImageOptimization, DEFAULT_DEVICE_SIZES, DEFAULT_IMAGE_SIZES } from "vinext/server/image-optimization";
import handler from "vinext/server/app-router-entry";

interface Env {
  ASSETS: Fetcher;
  DB: D1Database;
  IMAGES: {
    input(stream: ReadableStream): {
      transform(options: Record<string, unknown>): {
        output(options: { format: string; quality: number }): Promise<{ response(): Response }>;
      };
    };
  };
}

interface ExecutionContext {
  waitUntil(promise: Promise<unknown>): void;
  passThroughOnException(): void;
}

// Image security config. SVG sources with .svg extension auto-skip the
// optimization endpoint on the client side (served directly, no proxy).
// To route SVGs through the optimizer (with security headers), set
// dangerouslyAllowSVG: true in next.config.js and uncomment below:
// const imageConfig: ImageConfig = { dangerouslyAllowSVG: true };

const worker = {
  async fetch(request: Request, env: Env | undefined, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    // With assets.run_worker_first, Cloudflare never auto-serves static files.
    // vinext only signals ASSETS for public/ files (icon.png, etc.). Vite's
    // content-hashed client bundles live under /assets/* and would otherwise
    // fall through to the RSC router and 404 — unstyled SSR HTML looks like
    // "乱码". Serve them directly from the ASSETS binding.
    //
    // Dev (vinext/Vite) also links CSS by source path, e.g. /app/globals.css
    // and /app/**/*.module.css, plus Vite virtual modules under /@id/, /@fs/,
    // /@vite/. Those must hit the Vite asset pipeline too — not the RSC router.
    if (shouldServeFromAssets(url.pathname) && env?.ASSETS) {
      return env.ASSETS.fetch(request);
    }

    if (url.pathname === "/_vinext/image" && env?.ASSETS && env.IMAGES) {
      const allowedWidths = [...DEFAULT_DEVICE_SIZES, ...DEFAULT_IMAGE_SIZES];
      return handleImageOptimization(request, {
        fetchAsset: (path) => env.ASSETS.fetch(new Request(new URL(path, request.url))),
        transformImage: async (body, { width, format, quality }) => {
          const result = await env.IMAGES.input(body).transform(width > 0 ? { width } : {}).output({ format, quality });
          return result.response();
        },
      }, allowedWidths);
    }

    return handler.fetch(request, env, ctx);
  },
};

function shouldServeFromAssets(pathname: string): boolean {
  // Production hashed client bundles + vinext fonts.
  if (pathname.startsWith("/assets/")) return true;

  // Vite / vinext virtual modules and absolute file URLs used in dev HMR.
  // Covers /@id/, /@fs/, /@vite/, /@react-refresh, etc.
  if (pathname.startsWith("/@")) return true;
  if (pathname.startsWith("/node_modules/")) return true;

  // vinext dev serves App Router sources as client modules under /app/*
  // (e.g. /app/web-transfer.tsx, /app/globals.css). Without this, SSR HTML
  // paints but React never hydrates — buttons look dead.
  if (pathname.startsWith("/app/")) return true;

  // Other project sources Vite may request with a leading slash.
  if (/\.(?:tsx?|jsx?|mjs|cjs|css|map)(?:$|\?)/.test(pathname)) {
    return true;
  }

  // Files from website/public (icon, og, hero art, sample video, etc.).
  // With assets.run_worker_first these never auto-serve; missing this branch
  // 404s new public assets (e.g. /hero-scan-mark.png) while older ones may
  // still appear cached.
  if (
    /\.(?:png|jpe?g|gif|webp|avif|svg|ico|mp4|webm|woff2?|ttf|otf|txt|xml|json)(?:$|\?)/i.test(
      pathname,
    )
  ) {
    return true;
  }

  return false;
}

export default worker;
