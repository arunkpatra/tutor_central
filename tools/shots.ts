#!/usr/bin/env bun
/** bun shots <state> [--appearance dark|light|both] [--out dir] [--device name]: the app in the simulator, launched
 *  into a LaunchState (`--state <name>`), photographed in each appearance as <out>/<state>-<appearance>.png (D7).
 *  Needs the Debug simulator build that `bun check` makes. */
import { mkdir } from "node:fs/promises";
import { must, sh } from "./lib/sh";

/** `mask`: how the display's cutouts are drawn; unset, as the simulator draws them (the island only now and then). */
export type ShotsArgs = { state: string; appearances: string[]; out: string; device: string; mask?: "black" };

const USAGE = "usage: bun shots <state> [--appearance dark|light|both] [--out dir] [--device 'iPhone 17']";
const BUNDLE = "in.tutorcentral.app"; // D27

export function parseShotsArgs(argv: string[]): ShotsArgs {
  const [state, ...rest] = argv;
  if (!state || state.startsWith("--")) throw new Error(USAGE);
  const flag = (name: string, fallback: string) => {
    const i = rest.indexOf(name);
    if (i < 0) return fallback;
    const value = rest[i + 1];
    if (!value || value.startsWith("--")) throw new Error(`${name} needs a value`);
    return value;
  };
  const appearance = flag("--appearance", "both");
  if (!["dark", "light", "both"].includes(appearance)) throw new Error("--appearance is dark, light or both");
  return {
    state,
    appearances: appearance === "both" ? ["dark", "light"] : [appearance],
    out: flag("--out", `.shots/${state}`),
    device: flag("--device", "iPhone 17"),
  };
}

/** The app reads both (AppShell: LaunchState, Appearance). The app opens dark unless told otherwise (D23). */
export function launchArguments(state: string, appearance: string): string[] {
  return ["--state", state, "--appearance", appearance];
}

export function screenshotCommand(device: string, file: string, mask?: "black"): string[] {
  return ["xcrun", "simctl", "io", device, "screenshot", ...(mask ? [`--mask=${mask}`] : []), file];
}

export async function shoot(a: ShotsArgs): Promise<void> {
  await mkdir(a.out, { recursive: true });
  await sh(["xcrun", "simctl", "boot", a.device]); // already booted is fine
  await must(["xcrun", "simctl", "bootstatus", a.device, "-b"]);
  const found = await must([
    "sh",
    "-c",
    "ls -td ~/Library/Developer/Xcode/DerivedData/TutorCentral-*/Build/Products/Debug-iphonesimulator/TutorCentral.app 2>/dev/null | head -1",
  ]);
  const app = found.trim();
  if (!app) throw new Error("no Debug-iphonesimulator build of TutorCentral: run bun check first");
  await must(["xcrun", "simctl", "install", a.device, app]);
  for (const appearance of a.appearances) {
    await must(["xcrun", "simctl", "ui", a.device, "appearance", appearance]);
    await sh(["xcrun", "simctl", "terminate", a.device, BUNDLE]);
    await must(["xcrun", "simctl", "launch", a.device, BUNDLE, ...launchArguments(a.state, appearance)]);
    await Bun.sleep(1500);
    const file = `${a.out}/${a.state}-${appearance}.png`;
    await must(screenshotCommand(a.device, file, a.mask));
    console.log(file);
  }
}

if (import.meta.main) {
  try {
    await shoot(parseShotsArgs(process.argv.slice(2)));
  } catch (e) {
    console.error((e as Error).message);
    process.exit(1);
  }
}
