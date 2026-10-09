#!/usr/bin/env bun
/** bun store-shots [--device 'iPhone 17'] [--out docs/store/screenshots]: the App Store screenshots (D51). Each approved
 *  `Store-*` board names its launch state by its picture; the state is photographed in the simulator, dark, at 9:41, the island drawn every time, put
 *  in place of the board's picture, and the board rendered by headless Chrome at 402 × 874 × 3 = 1206 × 2622, as JPEG
 *  (App Store Connect refuses transparency). The boards are the template, so the words live only there. Needs the Debug
 *  simulator build that `bun check` makes. */
import { mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { must, sh } from "./lib/sh";
import { shoot } from "./shots";
import { cdp } from "./web-shots";

export type StoreShotsArgs = { device: string; out: string };
export type StoreBoard = { file: string; number: number; state: string };

const MOCKUPS = join(import.meta.dir, "..", "docs", "design", "mockups");
const FRAME = { width: 402, height: 874, scale: 3 };
const STATUS_BAR = [
  ...["--time", "9:41", "--dataNetwork", "wifi", "--wifiMode", "active", "--wifiBars", "3"],
  ...["--cellularMode", "active", "--cellularBars", "4", "--batteryState", "charged", "--batteryLevel", "100"],
];

export function parseStoreShotsArgs(argv: string[]): StoreShotsArgs {
  const flag = (name: string, fallback: string) => {
    const i = argv.indexOf(name);
    if (i < 0) return fallback;
    const value = argv[i + 1];
    if (!value || value.startsWith("--")) throw new Error(`${name} needs a value`);
    return value;
  };
  return { device: flag("--device", "iPhone 17"), out: flag("--out", "docs/store/screenshots") };
}

/** The `Store-<n>-<name>.dc.html` boards in the store's order, each with the launch state its picture names. */
export function boardsIn(files: string[], read: (file: string) => string): StoreBoard[] {
  return files
    .flatMap((file) => {
      const number = file.match(/^Store-(\d+)-.+\.dc\.html$/)?.[1];
      if (!number) return [];
      const state = read(file).match(/<img src="store\/([a-z0-9-]+)\.jpg"/)?.[1];
      if (!state) throw new Error(`${file} has no store/<launch state>.jpg picture`);
      return [{ file, number: Number(number), state }];
    })
    .sort((a, b) => a.number - b.number);
}

/** The board's frame as a page of its own, the fresh screen in place of the board's picture. */
export function frameHtml(board: string, screen: string): string {
  const frame = board.match(/<\/helmet>([\s\S]*)<\/x-dc>/)?.[1];
  if (!frame) throw new Error("the board has no frame between </helmet> and </x-dc>");
  const page = frame.trim().replace(/<img src="store\/[a-z0-9-]+\.jpg"/, `<img src="${screen}"`);
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><style>body{margin:0}</style></head><body>${page}</body></html>`;
}

export function storeFileName(number: number, state: string): string {
  return `${String(number).padStart(2, "0")}-${state}.jpg`;
}

async function render(boards: StoreBoard[], a: StoreShotsArgs): Promise<void> {
  const screens = join(".shots", "store");
  await sh(["xcrun", "simctl", "boot", a.device]); // already booted is fine
  await must(["xcrun", "simctl", "status_bar", a.device, "override", ...STATUS_BAR]);
  try {
    for (const board of boards) {
      await shoot({ state: board.state, appearances: ["dark"], out: screens, device: a.device, mask: "black" });
    }
  } finally {
    await sh(["xcrun", "simctl", "status_bar", a.device, "clear"]);
  }
  mkdirSync(a.out, { recursive: true });
  const chrome = await cdp([]);
  try {
    await chrome.send("Emulation.setDeviceMetricsOverride", {
      width: FRAME.width,
      height: FRAME.height,
      deviceScaleFactor: FRAME.scale,
      mobile: false,
    });
    for (const board of boards) {
      const png = readFileSync(join(screens, `${board.state}-dark.png`)).toString("base64");
      const html = frameHtml(readFileSync(join(MOCKUPS, board.file), "utf8"), `data:image/png;base64,${png}`);
      const page = Bun.serve({ port: 0, fetch: () => new Response(html, { headers: { "content-type": "text/html" } }) });
      try {
        const loaded = chrome.once("Page.loadEventFired");
        await chrome.send("Page.navigate", { url: `http://127.0.0.1:${page.port}/` });
        await loaded;
        const shot = await chrome.send<{ data: string }>("Page.captureScreenshot", {
          format: "jpeg",
          quality: 92,
          clip: { x: 0, y: 0, width: FRAME.width, height: FRAME.height, scale: 1 },
        });
        const file = join(a.out, storeFileName(board.number, board.state));
        writeFileSync(file, Buffer.from(shot.data, "base64"));
        const size = await must(["sips", "-g", "pixelWidth", "-g", "pixelHeight", file]);
        const [width, height] = [...size.matchAll(/pixel\w+: (\d+)/g)].map((m) => Number(m[1]));
        if (width !== FRAME.width * FRAME.scale || height !== FRAME.height * FRAME.scale) {
          throw new Error(`${file} is ${width} × ${height}, not 1206 × 2622`);
        }
        console.log(`${file} (${width} × ${height})`);
      } finally {
        page.stop(true);
      }
    }
  } finally {
    chrome.close();
  }
}

if (import.meta.main) {
  try {
    const args = parseStoreShotsArgs(process.argv.slice(2));
    await render(
      boardsIn(readdirSync(MOCKUPS), (file) => readFileSync(join(MOCKUPS, file), "utf8")),
      args,
    );
  } catch (e) {
    console.error((e as Error).message);
    process.exit(1);
  }
}
