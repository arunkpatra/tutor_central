import { expect, test } from "bun:test";
import { ago, count, latency, maskIp, monthOf, rupees, seconds, shortId, when } from "../../lib/format";

// 13 Oct 2026, 10:42 in India.
const now = new Date("2026-10-13T05:12:00Z");

test("rupees from paise: two decimals under ₹10, none above, with India's commas", () => {
  expect(rupees(7)).toBe("₹0.07");
  expect(rupees(284)).toBe("₹2.84");
  expect(rupees(18200)).toBe("₹182");
  expect(rupees(124000)).toBe("₹1,240");
  expect(rupees(0)).toBe("₹0.00");
});

test("when: today, yesterday, then the day, in India's clock", () => {
  expect(when("2026-10-13T01:18:00Z", now)).toBe("Today 06:48");
  expect(when("2026-10-12T13:50:00Z", now)).toBe("Yesterday 19:20");
  expect(when("2026-10-11T12:40:00Z", now)).toBe("11 Oct 18:10");
  expect(when("2026-10-13T05:12:16Z", now, true)).toBe("Today 10:42:16");
  // 23:00 IST on the 12th is yesterday, though it is the 12th in UTC too; 00:30 IST on the 13th is today.
  expect(when("2026-10-12T19:00:00Z", now)).toBe("Today 00:30");
});

test("ago: days for anything before yesterday", () => {
  expect(ago("2026-10-10T05:00:00Z", now)).toBe("3 days ago");
  expect(ago("2026-10-13T01:18:00Z", now)).toBe("Today 06:48");
});

test("seconds, latency, counts, ids, addresses, months", () => {
  expect(seconds(56)).toBe("56 s");
  expect(seconds(0.4)).toBe("0.4 s");
  expect(seconds(840)).toBe("14 min");
  expect(latency(2200)).toBe("2.2 s");
  expect(latency(110004)).toBe("110 s");
  expect(count(1842)).toBe("1,842");
  expect(shortId("7a1e2b3c-0000-0000-0000-00000000c0d4")).toBe("7a1e…c0d4");
  expect(maskIp("49.207.1.1")).toBe("49.207.x.x");
  expect(maskIp(null)).toBe("—");
  expect(monthOf("2026-09", now)).toBe("2026-09-01");
  expect(monthOf(undefined, now)).toBe("2026-10-01");
  expect(monthOf("junk", now)).toBe("2026-10-01");
});
