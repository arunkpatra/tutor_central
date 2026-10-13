import { log } from "../log.js";

/** An email out (D95): Resend's HTTP API with a sending-only key on the domain D30 verified. */
export type Sender = { send(to: string, subject: string, text: string): Promise<void> };

export function makeResend(apiKey: string, from = "Tutor Central <hello@tutorcentral.in>", fetcher: typeof fetch = fetch): Sender {
  return {
    async send(to, subject, text) {
      const res = await fetcher("https://api.resend.com/emails", {
        method: "POST",
        headers: { authorization: `Bearer ${apiKey}`, "content-type": "application/json" },
        body: JSON.stringify({ from, to: [to], subject, text }),
      });
      if (!res.ok) throw new Error(`Resend answered ${res.status}`);
    },
  };
}

/** A sender in memory (tests, and a local run without RESEND_API_KEY): it keeps and logs what it would send. */
export function fakeSender({ fail = false }: { fail?: boolean } = {}) {
  const sent: { to: string; subject: string; text: string }[] = [];
  const sender: Sender & { sent: typeof sent } = {
    sent,
    async send(to, subject, text) {
      if (fail) throw new Error("Resend answered 500");
      sent.push({ to, subject, text });
      log.info({ message: "an alert email (fake sender)", to, subject, text });
    },
  };
  return sender;
}
