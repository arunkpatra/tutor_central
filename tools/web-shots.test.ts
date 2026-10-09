import { expect, test } from "bun:test";
import { fileFor, parseWebShotsArgs, shotName, sideways } from "./web-shots";

test("defaults: the five pages at both widths and both appearances into .shots/web", () => {
  expect(parseWebShotsArgs([])).toEqual({
    pages: ["/", "/privacy", "/terms", "/support", "/anything-else"],
    widths: [1280, 390],
    appearances: ["dark", "light"],
    out: ".shots/web",
  });
});

test("flags: some pages, one width, one appearance, another folder", () => {
  expect(parseWebShotsArgs(["--pages", "/", "--widths", "320", "--appearance", "light", "--out", "x"])).toEqual({
    pages: ["/"],
    widths: [320],
    appearances: ["light"],
    out: "x",
  });
  expect(() => parseWebShotsArgs(["--appearance", "sepia"])).toThrow("dark, light or both");
  expect(() => parseWebShotsArgs(["--widths", "wide"])).toThrow("--widths is a list of numbers");
});

/** An export with the five pages, whatever web/out holds on this machine (CI's iOS job never builds the site). */
const exported = (file: string) => ["index.html", "privacy.html", "terms.html", "support.html", "404.html"].includes(file);

test("the export's file for a path, as Vercel serves it", () => {
  expect(fileFor("/", exported)).toBe("index.html");
  expect(fileFor("/privacy", exported)).toBe("privacy.html");
  expect(fileFor("/privacy/", exported)).toBe("privacy.html");
  expect(fileFor("/anything-else", exported)).toBe("404.html");
  expect(fileFor("/students/abc", exported)).toBe("404.html");
  expect(fileFor("/icon.svg", exported)).toBe("icon.svg");
});

test("a picture's name", () => {
  expect(shotName("/", 1280, "dark", exported)).toBe("home-1280-dark.png");
  expect(shotName("/privacy", 390, "light", exported)).toBe("privacy-390-light.png");
  expect(shotName("/anything-else", 390, "dark", exported)).toBe("not-found-390-dark.png");
});

test("a page wider than its viewport is reported: the picture clips to the width and would hide it", () => {
  expect(sideways("/", 320, 320)).toBeNull();
  expect(sideways("/", 320, 804)).toBe("/ at 320 lays out 804 px wide: it scrolls sideways");
});
