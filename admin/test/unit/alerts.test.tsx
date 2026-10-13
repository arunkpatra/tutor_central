import { afterAll, beforeAll, expect, test } from "bun:test";
import { renderToStaticMarkup } from "react-dom/server";
import { acknowledge } from "../../app/alerts/actions";
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
    "a centre over ₹60 in a day",
    "₹72 · over ₹60",
    "14 min · over 10",
    "6.1% · over 5%",
    "The lines change in Phase 22.",
  ])
    expect(html).toContain(words);
  expect(html.match(/>Acknowledge</g)?.length).toBe(2);
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
