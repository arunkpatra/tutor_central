import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import { acknowledge, saveLines } from "../../app/alerts/actions";
import AlertsPage from "../../app/alerts/page";
import AuditPage from "../../app/audit/page";
import { auditDetail, valueLine } from "../../content/alerts";
import { withData } from "../../lib/data";
import { previewData } from "../../lib/data/preview";

beforeAll(() => {
  process.env.ADMIN_PREVIEW = "1";
});
afterAll(() => {
  delete process.env.ADMIN_PREVIEW;
});

test("alerts: open first with Acknowledge, the acknowledged ones, the lines", async () => {
  const html = renderToStaticMarkup(await AlertsPage({ searchParams: Promise.resolve({}) }));
  for (const words of [
    "Open first",
    "acknowledged this week",
    "Email + push",
    "acknowledged · 07:20",
    "acknowledged · yesterday",
    "The lines, checked every ten minutes by the alerts job",
    "₹72 · over ₹60",
    "14 min · over 10",
    "6.1% · over 5%",
    "cost_day · ₹ a centre in a day",
    "error_rate · % of an hour’s requests",
    "error_rate · at least this many requests",
    "job_stuck · minutes with no step",
    'name="cost_day" ',
    'value="60"',
    "Save the lines",
    "The next check reads the new lines (within ten minutes).",
    "last changed 11 Oct 18:02 by you · written to the audit",
    "has no line: any job failed after its last try is raised.",
  ])
    expect(html).toContain(words);
  expect(html).not.toContain("The lines change in Phase 22.");
  expect(html.match(/>Acknowledge</g)?.length).toBe(2);
  const bad = renderToStaticMarkup(await AlertsPage({ searchParams: Promise.resolve({ bad: "lines" }) }));
  expect(bad).toContain("Whole numbers, 0 or more; the rate may have a decimal");
});

test("Save the lines: rupees to paise, numbers 0 or more, back to the alerts", async () => {
  const seen: unknown[] = [];
  const fake = { ...previewData, setLines: async (_a: string, l: unknown) => void seen.push(l) };
  const form = (cost: string) => {
    const f = new FormData();
    for (const [k, v] of Object.entries({ cost_day: cost, error_rate: "4.5", error_min: "30", stuck: "15" }))
      f.set(k, v);
    return f;
  };
  const go = async (f: FormData) =>
    ((await withData(fake, () => saveLines(f)).catch((e: { digest?: string }) => e)) as { digest?: string }).digest ??
    "";
  expect(await go(form("-5"))).toContain("/alerts?bad=lines");
  expect(await go(form("sixty"))).toContain("/alerts?bad=lines");
  expect(seen).toHaveLength(0);
  expect(await go(form("90"))).toContain("/alerts");
  expect(seen[0]).toEqual({
    cost_day_paise: 9000,
    error_rate_pct: 4.5,
    error_rate_min_requests: 30,
    stuck_minutes: 15,
  });
});

test("acknowledge goes back to the alerts", async () => {
  const f = new FormData();
  f.set("alert", "preview-a1");
  f.set("show", "newest");
  const to = ((await acknowledge(f).catch((e: { digest?: string }) => e)) as { digest?: string }).digest ?? "";
  expect(to).toContain("/alerts?show=newest");
  const fake = { ...previewData, acknowledge: async () => false };
  const again =
    ((await withData(fake, () => acknowledge(f)).catch((e: { digest?: string }) => e)) as { digest?: string }).digest ??
    "";
  expect(again).toContain("/alerts?show=newest");
});

test("the audit: every action, you for the viewer's rows, the other email for the refusal", async () => {
  const html = renderToStaticMarkup(await AuditPage({ searchParams: Promise.resolve({}) }));
  for (const words of [
    "open_record",
    "retry_job",
    "acknowledge_alert",
    "refused",
    "enrol_totp",
    "someone@example.com",
    "49.207.x.x",
    "plan · Class 8 Science · 13 Oct · from make:2",
  ])
    expect(html).toContain(words);
  expect(html).toContain(">you<");
  expect(html).not.toContain("49.207.12.40");
});

test("an alert's value against its line, and an audit row's detail", () => {
  expect(valueLine("cost_day", 7200, 6000)).toBe("₹72 · over ₹60");
  expect(valueLine("job_failed", 1, 0)).toBe("1 · over 0");
  expect(auditDetail({ action: "cancel_job", reason: null, target: { kind: "export" }, subject: "a student" })).toBe(
    "export · a student",
  );
  expect(auditDetail({ action: "acknowledge_alert", reason: null, target: { kind: "cost_day" }, subject: null })).toBe(
    "cost_day",
  );
  expect(auditDetail({ action: "sign_in", reason: "second factor verified", target: {}, subject: null })).toBe(
    "second factor verified",
  );
});

test("the audit names a lines change by its values and a model change by its kind and step", () => {
  expect(
    auditDetail({
      action: "set_alert_lines",
      reason: null,
      subject: null,
      target: { cost_day_paise: 9000, error_rate_pct: 4.5, error_rate_min_requests: 30, stuck_minutes: 15 },
    }),
  ).toBe("cost_day ₹90 · error_rate 4.5% of 30 · job_stuck 15 min");
  expect(
    auditDetail({
      action: "set_model",
      reason: null,
      subject: null,
      target: { kind: "brief", step: "draft", enabled: false },
    }),
  ).toBe("brief · draft · off");
});
