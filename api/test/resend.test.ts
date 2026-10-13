import { expect, test } from "bun:test";
import { makeResend } from "../src/alerts/resend.js";

test("an email is one POST to Resend with the key, from Tutor Central", async () => {
  const seen: { url: string; init: RequestInit }[] = [];
  const fetcher = (async (url: string, init: RequestInit) => {
    seen.push({ url, init });
    return new Response(JSON.stringify({ id: "e1" }), { status: 200 });
  }) as unknown as typeof fetch;
  await makeResend("re_test", undefined, fetcher).send("you@example.com", "Tutor Central alert: job_failed", "text");
  expect(seen).toHaveLength(1);
  expect(seen[0]?.url).toBe("https://api.resend.com/emails");
  expect(seen[0]?.init.method).toBe("POST");
  expect((seen[0]?.init.headers as Record<string, string>).authorization).toBe("Bearer re_test");
  expect(JSON.parse(String(seen[0]?.init.body))).toEqual({ from: "Tutor Central <hello@tutorcentral.in>", to: ["you@example.com"], subject: "Tutor Central alert: job_failed", text: "text" });
});

test("Resend's refusal throws with its status", async () => {
  const fetcher = (async () => new Response("{}", { status: 422 })) as unknown as typeof fetch;
  await expect(makeResend("re_test", undefined, fetcher).send("a@b.c", "s", "t")).rejects.toThrow("422");
});
