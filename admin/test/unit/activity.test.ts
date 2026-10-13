import { expect, test } from "bun:test";
import { activityWords } from "../../content/activity";

test("the events' kinds in words, by screen", () => {
  expect(activityWords("app_opened", null)).toBe("Opened the app");
  expect(activityWords("tab_opened", "today")).toBe("Opened Today");
  expect(activityWords("link_opened", "fees")).toBe("Opened a link · Fees");
  expect(activityWords("signed_in", null)).toBe("Signed in");
  expect(activityWords("signed_out", null)).toBe("Signed out");
});

test("a kind not listed answers its own words", () => {
  expect(activityWords("plan_opened_again", null)).toBe("plan opened again");
});
