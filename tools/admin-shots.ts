#!/usr/bin/env bun
/** bun admin-shots [--pages a,b] [--widths 1280,390] [--appearance dark|light|both] [--out .shots/admin]: the admin
 *  portal built and started in preview mode (D96: every page from the checked-in fixtures, no session), photographed by
 *  headless Chrome over its DevTools protocol at each width and appearance, full page, 2× (D46's method). */
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { type Appearance, cdp, sideways } from "./web-shots";

export type AdminShotsArgs = { pages: string[]; widths: number[]; appearances: Appearance[]; out: string };
const USAGE =
  "usage: bun admin-shots [--pages /centres,/jobs?open=preview-failed] [--widths 1280,390] [--appearance dark|light|both] [--out .shots/admin]";
/** The fifteen boards' pages and states (P19 boards, row 27). */
export const DEFAULT_PAGES = [
  "/sign-in",
  "/mfa/enrol",
  "/mfa/verify",
  "/refused",
  "/centres",
  "/centres/preview",
  "/centres/preview?ask=1",
  "/centres/preview/record",
  "/cost",
  "/calls",
  "/calls/preview",
  "/jobs?open=preview-failed",
  "/errors",
  "/alerts",
  "/audit",
  // Phase 22's boards (P22-*).
  "/models",
  "/models/preview",
  "/models/preview?off=1",
  "/centres/preview?allowance=1",
  "/figures",
  "/evals",
  "/syllabi?open=preview",
  "/calls/preview-feedback",
  "/calls/preview-reduced",
];
/** A page drawn to answer 404: the not-found page in the frame. */
const NOT_FOUND = "/nothing-here";
const ADMIN = join(import.meta.dir, "..", "admin");
/** The build's variables: probes, never a real key (the preview reads nothing). */
const PROBES = {
  SUPABASE_URL: "http://127.0.0.1:54321",
  SUPABASE_ANON_KEY: "probe",
  SUPABASE_SERVICE_ROLE_KEY: "sb_secret_build_probe_do_not_use",
  ADMIN_PREVIEW: "1",
};

export function parseAdminShotsArgs(argv: string[]): AdminShotsArgs {
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
  const pages = flag("--pages", DEFAULT_PAGES.join(",")).split(",");
  if (pages.some((p) => !p.startsWith("/"))) throw new Error("--pages is a list of paths, each starting with /");
  return { pages, widths, appearances: appearance === "both" ? ["dark", "light"] : [appearance as Appearance], out: flag("--out", ".shots/admin") };
}

/** `/centres/preview?ask=1` at 390 in dark → `centres-preview-ask-390-dark.png`; a query's `1` names its key alone. */
export function shotName(path: string, width: number, appearance: string): string {
  const [route = "", query = ""] = path.split("?");
  const parts = route.split("/").filter(Boolean);
  for (const pair of query.split("&").filter(Boolean)) {
    const [k = "", v = ""] = pair.split("=");
    parts.push(v === "1" || v === "" ? k : `${k}-${v}`);
  }
  return `${parts.join("-") || "home"}-${width}-${appearance}.png`;
}

/** What a page must answer: 200, or 404 for the not-found page. */
export function wrongStatus(path: string, status: number): string | null {
  const want = path === NOT_FOUND ? 404 : 200;
  return status === want ? null : `${path} answered ${status}, not ${want}`;
}

/** True while the portal's loading frame (`PageLoading`: `section[aria-busy]`, the `.loadBar`) is on screen. */
export const LOADING_SHOWN = `!!document.querySelector('section[aria-busy="true"], .loadBar')`;

async function freePort(): Promise<number> {
  const server = Bun.serve({ port: 0, fetch: () => new Response() });
  const port = server.port as number;
  server.stop(true);
  return port;
}

async function must(cmd: string[], env: Record<string, string>) {
  const proc = Bun.spawn(cmd, { cwd: ADMIN, env: { ...process.env, ...env }, stdout: "pipe", stderr: "pipe" });
  if ((await proc.exited) !== 0) throw new Error(`${cmd.join(" ")} failed:\n${await new Response(proc.stderr).text()}${await new Response(proc.stdout).text()}`);
}

if (import.meta.main) {
  const args = parseAdminShotsArgs(process.argv.slice(2));
  mkdirSync(args.out, { recursive: true });
  console.log("building admin/ in preview mode…");
  await must(["bunx", "next", "build"], PROBES);
  const port = await freePort();
  const server = Bun.spawn(["bunx", "next", "start", "-p", String(port)], { cwd: ADMIN, env: { ...process.env, ...PROBES }, stdout: "ignore", stderr: "inherit" });
  const origin = `http://127.0.0.1:${port}`;
  const problems: string[] = [];
  const chrome = await cdp([]);
  try {
    for (let i = 0; ; i++) {
      const up = await fetch(`${origin}/health`).then((r) => r.ok, () => false);
      if (up) break;
      if (i > 60) throw new Error("the portal did not start");
      await Bun.sleep(500);
    }
    for (const path of args.pages) {
      const status = (await fetch(origin + path, { redirect: "manual" })).status;
      const wrong = wrongStatus(path, status);
      if (wrong) {
        problems.push(wrong);
        continue;
      }
      for (const width of args.widths) {
        for (const appearance of args.appearances) {
          const metrics = { width, deviceScaleFactor: 2, mobile: width < 768 };
          await chrome.send("Emulation.setDeviceMetricsOverride", { ...metrics, height: 900 });
          await chrome.send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: appearance }] });
          const loaded = chrome.once("Page.loadEventFired");
          await chrome.send("Page.navigate", { url: origin + path });
          await loaded;
          // The load event can fire while Next still streams the page behind its loading frame (D97): the first page on
          // a cold server was photographed loading. Wait for the frame to go.
          for (let i = 0; i < 40; i++) {
            const busy = await chrome.send<{ result: { value: boolean } }>("Runtime.evaluate", { expression: LOADING_SHOWN, returnByValue: true });
            if (!busy.result.value) break;
            await Bun.sleep(250);
          }
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
    server.kill();
  }
  if (problems.length > 0) {
    console.error(problems.join("\n"));
    process.exit(1);
  }
}
