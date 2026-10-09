import { expect, test } from "bun:test";
import { launchArguments, parseShotsArgs, screenshotCommand } from "./shots";

test("defaults: both appearances, iPhone 17, .shots/<state>", () => {
  expect(parseShotsArgs(["placeholder"])).toEqual({
    state: "placeholder",
    appearances: ["dark", "light"],
    out: ".shots/placeholder",
    device: "iPhone 17",
  });
});

test("one appearance, another folder and device", () => {
  expect(parseShotsArgs(["today-empty", "--appearance", "light", "--out", "x", "--device", "iPhone 17 Pro"])).toEqual({
    state: "today-empty",
    appearances: ["light"],
    out: "x",
    device: "iPhone 17 Pro",
  });
});

test("refuses no state, an unknown appearance or a flag without a value", () => {
  expect(() => parseShotsArgs([])).toThrow("usage");
  expect(() => parseShotsArgs(["s", "--appearance", "sepia"])).toThrow("dark, light or both");
  expect(() => parseShotsArgs(["s", "--out"])).toThrow("--out needs a value");
});

test("the app is launched into the state and the appearance being photographed", () => {
  expect(launchArguments("placeholder", "light")).toEqual(["--state", "placeholder", "--appearance", "light"]);
});

test("a store shot draws the display's cutouts in black, so the island shows in every picture", () => {
  expect(screenshotCommand("iPhone 17", "a.png")).toEqual(["xcrun", "simctl", "io", "iPhone 17", "screenshot", "a.png"]);
  expect(screenshotCommand("iPhone 17", "a.png", "black")).toEqual([
    "xcrun",
    "simctl",
    "io",
    "iPhone 17",
    "screenshot",
    "--mask=black",
    "a.png",
  ]);
});
