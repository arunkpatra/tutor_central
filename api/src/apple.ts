import { createPrivateKey, sign } from "node:crypto";

export type AppleKey = { teamId: string; keyId: string; privateKeyPem: string; clientId: "in.tutorcentral.app" };
export type AppleClient = { revokeAuthorization(code: string): Promise<void> };

export class AppleFailure extends Error {
  constructor(public readonly reason: "refused" | "unreachable") {
    super(reason);
    this.name = "AppleFailure";
  }
}

const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString("base64url");

/** The client secret Apple's token and revoke endpoints take: an ES256 JWT signed with the Sign in with Apple key,
 *  good for five minutes (Apple allows up to six months; a short one leaks less if it ever did). */
export function clientSecret(key: AppleKey, now: Date): string {
  const iat = Math.floor(now.getTime() / 1000);
  const header = b64({ alg: "ES256", kid: key.keyId });
  const payload = b64({ iss: key.teamId, iat, exp: iat + 300, aud: "https://appleid.apple.com", sub: key.clientId });
  const signature = sign("sha256", Buffer.from(`${header}.${payload}`), {
    key: createPrivateKey(key.privateKeyPem),
    dsaEncoding: "ieee-p1363",
  });
  return `${header}.${payload}.${signature.toString("base64url")}`;
}

/** Exchange the app's fresh authorization code for tokens, then revoke the refresh token: Apple's requirement for an
 *  app that deletes accounts (D38). A refused code is the caller's problem (a stale or reused code); a network failure
 *  is ours. */
export function appleHttp(key: AppleKey, fetchImpl: typeof fetch = fetch): AppleClient {
  const post = async (path: string, form: Record<string, string>) => {
    try {
      return await fetchImpl(`https://appleid.apple.com${path}`, {
        method: "POST",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams(form).toString(),
      });
    } catch {
      throw new AppleFailure("unreachable");
    }
  };
  return {
    async revokeAuthorization(code) {
      const secret = clientSecret(key, new Date());
      const token = await post("/auth/token", {
        grant_type: "authorization_code",
        code,
        client_id: key.clientId,
        client_secret: secret,
      });
      if (!token.ok) throw new AppleFailure("refused");
      const { refresh_token } = (await token.json()) as { refresh_token?: string };
      if (!refresh_token) throw new AppleFailure("refused");
      const revoke = await post("/auth/revoke", {
        client_id: key.clientId,
        client_secret: secret,
        token: refresh_token,
        token_type_hint: "refresh_token",
      });
      if (!revoke.ok) throw new AppleFailure("refused");
    },
  };
}
