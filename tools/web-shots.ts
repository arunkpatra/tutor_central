#!/usr/bin/env bun
/** bun web-shots [--pages a,b] [--widths 1280,390] [--appearance dark|light|both] [--out dir]: the site's export (web/out,
 *  built by `bun check` or `cd web && bun run build`) served locally and photographed by headless Chrome over its DevTools
 *  protocol at each width and appearance, full page, 2× (D46). No dependency: Bun's fetch and WebSocket. */
import { existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";

export type Appearance = "dark" | "light";
export type WebShotsArgs = { pages: string[]; widths: number[]; appearances: Appearance[]; out: string };
const USAGE =
  "usage: bun web-shots [--pages /,/privacy] [--widths 1280,390] [--appearance dark|light|both] [--out .shots/web]";
const DEFAULT_PAGES = ["/", "/privacy", "/terms", "/support", "/anything-else"];
const OUT_DIR = join(import.meta.dir, "..", "web", "out");
const CHROME = process.env.TC_CHROME ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const inExport = (file: string) => existsSync(join(OUT_DIR, file));

export function parseWebShotsArgs(argv: string[]): WebShotsArgs {
  const flag = (name: string, fallback: string) => {
    const i = argv.indexOf(name);
    if (i < 0) return fallback;
    const value = argv[i + 1];
    if (!value || value.startsWith("--")) throw new Error(`${name} needs a value\n${USAGE}`);
    return value;
  };
  const appearance = flag("--appearance", "both");
  if (!["dark", "light", "both"].includes(appearance)) throw new Error("--appearance is dark, light or both");
  const widths = flag("--widths", "1280,390").split(",").map(Number);
  if (widths.some((w) => !Number.isInteger(w) || w < 200)) throw new Error("--widths is a list of numbers (CSS px)");
  return {
    pages: flag("--pages", DEFAULT_PAGES.join(",")).split(","),
    widths,
    appearances: appearance === "both" ? ["dark", "light"] : [appearance as Appearance],
    out: flag("--out", ".shots/web"),
  };
}

/** The export's file for a path: Vercel serves `x.html` at `/x` (and `/x/`) and `404.html` for the rest. */
export function fileFor(path: string, exists: (file: string) => boolean = inExport): string {
  const clean = path.replace(/\/+$/, "") || "/";
  if (clean === "/") return "index.html";
  if (clean.includes(".")) return clean.slice(1);
  const file = `${clean.slice(1)}.html`;
  return exists(file) ? file : "404.html";
}

export function shotName(
  path: string,
  width: number,
  appearance: string,
  exists: (file: string) => boolean = inExport,
): string {
  const page = path === "/" ? "home" : fileFor(path, exists) === "404.html" ? "not-found" : path.replace(/^\/|\/$/g, "");
  return `${page}-${width}-${appearance}.png`;
}

/** A page laid out wider than its viewport scrolls sideways on a phone; the picture clips to the width and hides it. */
export function sideways(path: string, width: number, scrollWidth: number): string | null {
  return scrollWidth > width ? `${path} at ${width} lays out ${scrollWidth} px wide: it scrolls sideways` : null;
}

/** The export on a local port, the way Vercel would serve it. `stop()` closes it. */
export function serveExport(): { origin: string; stop: () => void } {
  const server = Bun.serve({
    port: 0,
    fetch(request) {
      const file = fileFor(new URL(request.url).pathname);
      return new Response(Bun.file(join(OUT_DIR, file)), { status: file === "404.html" ? 404 : 200 });
    },
  });
  return { origin: `http://127.0.0.1:${server.port}`, stop: () => server.stop(true) };
}

type Message = { id?: number; method?: string; result?: unknown; error?: { message: string } };

/** A tiny DevTools client on one page target: commands by id, one waiter per event. */
export async function cdp(chromeArgs: string[]) {
  const dataDir = join(process.env.TMPDIR ?? "/tmp", `tc-web-shots-${process.pid}`);
  const proc = Bun.spawn(
    [
      CHROME,
      "--headless=new",
      "--disable-gpu",
      "--hide-scrollbars",
      "--remote-debugging-port=0",
      `--user-data-dir=${dataDir}`,
      "--no-first-run",
      ...chromeArgs,
      "about:blank",
    ],
    { stderr: "pipe", stdout: "ignore" },
  );
  const reader = proc.stderr.getReader();
  let text = "";
  while (!text.includes("DevTools listening on ")) {
    const { value, done } = await reader.read();
    if (done) throw new Error(`Chrome did not start: ${text}`);
    text += new TextDecoder().decode(value);
  }
  // Keep reading: a chatty Chrome would otherwise fill the pipe and stall.
  void (async () => {
    while (!(await reader.read()).done) {}
  })();
  const browserWs = text.match(/DevTools listening on (ws:\/\/\S+)/)?.[1];
  if (!browserWs) throw new Error("no DevTools address");
  const port = new URL(browserWs).port;
  const targets = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()) as {
    webSocketDebuggerUrl: string;
    type: string;
  }[];
  const page = targets.find((t) => t.type === "page");
  if (!page) throw new Error("no page target");
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise<void>((resolve, reject) => {
    ws.onopen = () => resolve();
    ws.onerror = () => reject(new Error("could not reach Chrome's page"));
  });
  let id = 0;
  const waiting = new Map<number, { resolve: (r: unknown) => void; reject: (e: Error) => void }>();
  const events = new Map<string, () => void>();
  ws.onmessage = (m) => {
    const msg = JSON.parse(String(m.data)) as Message;
    if (msg.id !== undefined) {
      const waiter = waiting.get(msg.id);
      waiting.delete(msg.id);
      if (msg.error) waiter?.reject(new Error(msg.error.message));
      else waiter?.resolve(msg.result);
    } else if (msg.method) {
      events.get(msg.method)?.();
      events.delete(msg.method);
    }
  };
  const send = <T>(method: string, params: Record<string, unknown> = {}): Promise<T> =>
    new Promise((resolve, reject) => {
      id += 1;
      waiting.set(id, { resolve: resolve as (r: unknown) => void, reject });
      ws.send(JSON.stringify({ id, method, params }));
    });
  const once = (method: string) => new Promise<void>((resolve) => events.set(method, resolve));
  await send("Page.enable");
  return {
    send,
    once,
    close() {
      ws.close();
      proc.kill();
      rmSync(dataDir, { recursive: true, force: true });
    },
  };
}

if (import.meta.main) {
  const args = parseWebShotsArgs(process.argv.slice(2));
  if (!inExport("index.html")) {
    console.error("web/out is missing: run `bun check --only=web` (or `cd web && bun run build`) first");
    process.exit(2);
  }
  mkdirSync(args.out, { recursive: true });
  const site = serveExport();
  const chrome = await cdp([]);
  const problems: string[] = [];
  try {
    for (const path of args.pages) {
      for (const width of args.widths) {
        for (const appearance of args.appearances) {
          const metrics = { width, deviceScaleFactor: 2, mobile: width < 768 };
          await chrome.send("Emulation.setDeviceMetricsOverride", { ...metrics, height: 900 });
          await chrome.send("Emulation.setEmulatedMedia", {
            features: [{ name: "prefers-color-scheme", value: appearance }],
          });
          const loaded = chrome.once("Page.loadEventFired");
          await chrome.send("Page.navigate", { url: site.origin + path });
          await loaded;
          const scroll = await chrome.send<{ result: { value: number } }>("Runtime.evaluate", {
            expression: "document.documentElement.scrollWidth",
            returnByValue: true,
          });
          const wide = sideways(path, width, scroll.result.value);
          if (wide) problems.push(wide);
          const layout = await chrome.send<{ cssContentSize: { height: number } }>("Page.getLayoutMetrics");
          const height = Math.ceil(layout.cssContentSize.height);
          await chrome.send("Emulation.setDeviceMetricsOverride", { ...metrics, height });
          const shot = await chrome.send<{ data: string }>("Page.captureScreenshot", {
            format: "png",
            captureBeyondViewport: true,
            clip: { x: 0, y: 0, width, height, scale: 1 },
          });
          const file = join(args.out, shotName(path, width, appearance));
          writeFileSync(file, Buffer.from(shot.data, "base64"));
          console.log(`${file} (${width} × ${height})`);
        }
      }
    }
  } finally {
    chrome.close();
    site.stop();
  }
  if (problems.length > 0) {
    console.error(problems.join("\n"));
    process.exit(1);
  }
}
