import { expect, test } from "bun:test";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { boardsIn, frameHtml, parseStoreShotsArgs, storeFileName } from "./store-shots";

const MOCKUPS = join(import.meta.dir, "..", "docs", "design", "mockups");
const LAUNCH_STATES = readFileSync(
  join(import.meta.dir, "..", "ios", "TutorCentralKit", "Sources", "AppShell", "LaunchState.swift"),
  "utf8",
);

test("defaults: iPhone 17, into docs/store/screenshots", () => {
  expect(parseStoreShotsArgs([])).toEqual({ device: "iPhone 17", out: "docs/store/screenshots" });
  expect(parseStoreShotsArgs(["--device", "iPhone 17 Pro", "--out", "x"])).toEqual({ device: "iPhone 17 Pro", out: "x" });
  expect(() => parseStoreShotsArgs(["--out"])).toThrow("--out needs a value");
});

test("the boards in the store's order, each naming its launch state by its picture", () => {
  const files = ["Store-2-Fees.dc.html", "P8-Home.dc.html", "Store-10-Last.dc.html", "Store-1-Today.dc.html"];
  const read = (file: string) => `<img src="store/${file.split("-")[2]?.toLowerCase().replace(".dc.html", "")}-x.jpg">`;
  expect(boardsIn(files, read).map((b) => [b.number, b.state])).toEqual([
    [1, "today-x"],
    [2, "fees-x"],
    [10, "last-x"],
  ]);
});

test("a board without a store picture is refused", () => {
  expect(() => boardsIn(["Store-1-Today.dc.html"], () => "<div></div>")).toThrow("Store-1-Today.dc.html");
});

test("the approved boards: six, numbered 1 to 6, each a launch state the app has", () => {
  const boards = boardsIn(readdirSync(MOCKUPS), (file) => readFileSync(join(MOCKUPS, file), "utf8"));
  expect(boards.map((b) => b.number)).toEqual([1, 2, 3, 4, 5, 6]);
  for (const board of boards) expect(LAUNCH_STATES).toContain(`= "${board.state}"`);
});

test("the frame is the board's own, with the fresh screen in place of the board's picture", () => {
  const board = `<x-dc><helmet><style>body{margin:0}</style></helmet>
<div style="width:402px;height:874px"><div>Caption</div><img src="store/fees-due.jpg" alt=""></div>
</x-dc>`;
  const html = frameHtml(board, "data:image/png;base64,AAAA");
  expect(html).toContain('<img src="data:image/png;base64,AAAA" alt="">');
  expect(html).toContain("Caption");
  expect(html).not.toContain("store/fees-due.jpg");
  expect(html).not.toContain("<x-dc>");
  expect(() => frameHtml("<div>no frame</div>", "data:")).toThrow("frame");
});

test("files sort in the store's order and name the screen", () => {
  expect(storeFileName(1, "today-evening")).toBe("01-today-evening.jpg");
  expect(storeFileName(12, "fees-due")).toBe("12-fees-due.jpg");
});
