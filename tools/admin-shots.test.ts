import { expect, test } from "bun:test";
import { DEFAULT_PAGES, parseAdminShotsArgs, shotName, wrongStatus, LOADING_SHOWN } from "./admin-shots";

test("the defaults are the boards' pages (Phase 19's fifteen, Phase 22's) at both widths and appearances", () => {
  expect(parseAdminShotsArgs([])).toEqual({ pages: DEFAULT_PAGES, widths: [1280, 390], appearances: ["dark", "light"], out: ".shots/admin" });
  expect(DEFAULT_PAGES.length).toBe(23);
});

test("the flags narrow the pages, widths and appearance, and refuse what they cannot use", () => {
  expect(parseAdminShotsArgs(["--pages", "/cost,/alerts", "--widths", "390", "--appearance", "light"])).toMatchObject({
    pages: ["/cost", "/alerts"],
    widths: [390],
    appearances: ["light"],
  });
  expect(() => parseAdminShotsArgs(["--pages"])).toThrow("--pages needs a value");
  expect(() => parseAdminShotsArgs(["--pages", "cost"])).toThrow("each starting with /");
  expect(() => parseAdminShotsArgs(["--widths", "wide"])).toThrow("--widths");
  expect(() => parseAdminShotsArgs(["--appearance", "sepia"])).toThrow("--appearance");
});

test("a page's picture is named by its path and query", () => {
  expect(shotName("/centres/preview?ask=1", 390, "dark")).toBe("centres-preview-ask-390-dark.png");
  expect(shotName("/jobs?open=preview-failed", 1280, "light")).toBe("jobs-open-preview-failed-1280-light.png");
  expect(shotName("/mfa/enrol", 1280, "dark")).toBe("mfa-enrol-1280-dark.png");
  expect(shotName("/", 390, "dark")).toBe("home-390-dark.png");
});

test("a page must answer 200, the not-found page 404", () => {
  expect(wrongStatus("/cost", 200)).toBeNull();
  expect(wrongStatus("/cost", 307)).toBe("/cost answered 307, not 200");
  expect(wrongStatus("/nothing-here", 404)).toBeNull();
});

test("a page is photographed once its loading frame has gone: the check reads the frame's marks (D97)", () => {
  expect(LOADING_SHOWN).toContain('section[aria-busy="true"]');
  expect(LOADING_SHOWN).toContain(".loadBar");
});
