import { expect, test } from "bun:test";
import { createPublicKey, generateKeyPairSync, verify } from "node:crypto";
import { type AppleFailure, appleHttp, clientSecret } from "../src/apple.js";
import { fakeApple } from "../src/apple-fake.js";

const { privateKey } = generateKeyPairSync("ec", { namedCurve: "prime256v1" });
const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
const key = { teamId: "Y7SW6436RD", keyId: "ABC123DEFG", privateKeyPem: pem, clientId: "in.tutorcentral.app" as const };

function decode(part: string) {
  return JSON.parse(Buffer.from(part, "base64url").toString());
}

test("the client secret is an ES256 JWT Apple will accept: the header, the claims, a signature the public key verifies", () => {
  const now = new Date("2026-10-09T10:00:00Z");
  const jwt = clientSecret(key, now);
  const [header = "", payload = "", signature = ""] = jwt.split(".");
  expect(decode(header)).toEqual({ alg: "ES256", kid: "ABC123DEFG" });
  expect(decode(payload)).toEqual({
    iss: "Y7SW6436RD",
    iat: 1791540000,
    exp: 1791540000 + 300,
    aud: "https://appleid.apple.com",
    sub: "in.tutorcentral.app",
  });
  const ok = verify(
    "sha256",
    Buffer.from(`${header}.${payload}`),
    { key: createPublicKey(privateKey), dsaEncoding: "ieee-p1363" },
    Buffer.from(signature, "base64url"),
  );
  expect(ok).toBe(true);
});

test("revokeAuthorization exchanges the code, then revokes the refresh token, as form posts", async () => {
  const calls: { url: string; body: string }[] = [];
  const fetchImpl = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push({ url, body: String(init?.body) });
    if (url.endsWith("/auth/token")) {
      return new Response(JSON.stringify({ refresh_token: "r-1", access_token: "a-1" }), { status: 200 });
    }
    return new Response("", { status: 200 });
  }) as typeof fetch;
  await appleHttp(key, fetchImpl).revokeAuthorization("code-1");
  expect(calls.map((c) => c.url)).toEqual(["https://appleid.apple.com/auth/token", "https://appleid.apple.com/auth/revoke"]);
  const token = new URLSearchParams(calls[0]?.body);
  expect(token.get("grant_type")).toBe("authorization_code");
  expect(token.get("code")).toBe("code-1");
  expect(token.get("client_id")).toBe("in.tutorcentral.app");
  expect(token.get("client_secret")?.split(".").length).toBe(3);
  const revoke = new URLSearchParams(calls[1]?.body);
  expect(revoke.get("token")).toBe("r-1");
  expect(revoke.get("token_type_hint")).toBe("refresh_token");
});

test("a code Apple refuses is 'refused'; a network failure is 'unreachable'", async () => {
  const refusing = (async () => new Response(JSON.stringify({ error: "invalid_grant" }), { status: 400 })) as unknown as typeof fetch;
  await expect(appleHttp(key, refusing).revokeAuthorization("bad")).rejects.toMatchObject({
    reason: "refused",
  } satisfies Partial<AppleFailure>);
  const down = (async () => {
    throw new TypeError("fetch failed");
  }) as unknown as typeof fetch;
  await expect(appleHttp(key, down).revokeAuthorization("x")).rejects.toMatchObject({ reason: "unreachable" });
});

test("the fake records what it revoked and can refuse", async () => {
  const apple = fakeApple({});
  await apple.revokeAuthorization("c");
  expect(apple.revoked).toEqual(["c"]);
  await expect(fakeApple({ refuse: true }).revokeAuthorization("c")).rejects.toMatchObject({ reason: "refused" });
});
