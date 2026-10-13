import { expect, test } from "bun:test";
import { once } from "./admin-smoke";

const ORIGIN = "https://admin.tutorcentral.in";
const SHA = "a".repeat(40);

/** The portal as it should answer: /health with the commit, Sign in, every gated page a redirect to Sign in, http to https. */
function portal(change: Partial<Record<string, () => Response>> = {}): typeof fetch {
  return (async (input: string | URL | Request) => {
    const url = new URL(String(input));
    const key = url.protocol === "http:" ? "http" : url.pathname;
    const answer = change[key];
    if (answer) return answer();
    if (key === "http") return new Response(null, { status: 308, headers: { location: `https://${url.host}/` } });
    if (key === "/health") return Response.json({ ok: true, commit: SHA });
    if (key === "/sign-in") return new Response("<title>Sign in · Tutor Central admin</title><h1>Sign in</h1>", { status: 200 });
    return new Response(null, { status: 307, headers: { location: "/sign-in" } });
  }) as typeof fetch;
}

test("the happy path has no problems", async () => {
  expect(await once(ORIGIN, SHA, portal())).toEqual([]);
});

test("a gated page served without a session is the smoke's failure", async () => {
  const problems = await once(ORIGIN, SHA, portal({ "/centres": () => new Response("<h1>Centres</h1>", { status: 200 }) }));
  expect(problems).toContain("/centres served a page without a session");
});

test("another commit, a missing Sign in, and plain http are each named", async () => {
  const problems = await once(
    ORIGIN,
    SHA,
    portal({
      "/health": () => Response.json({ ok: true, commit: "b".repeat(40) }),
      "/sign-in": () => new Response("down", { status: 500 }),
      http: () => new Response("plain", { status: 200 }),
    }),
  );
  expect(problems).toEqual([`/health serves ${"b".repeat(40)}, not ${SHA}`, "/sign-in answered 500", "http://admin.tutorcentral.in/ does not redirect to https"]);
});

test("an unreachable portal fails in words", async () => {
  const problems = await once(ORIGIN, SHA, (async () => {
    throw new Error("connection refused");
  }) as unknown as typeof fetch);
  expect(problems).toEqual([`could not reach ${ORIGIN}: connection refused`]);
});
