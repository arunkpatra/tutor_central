import { type AppleClient, AppleFailure } from "./apple.js";

export type AppleScript = { refuse?: boolean; unreachable?: boolean };

/** Tests and local runs (APPLE_FAKE=1): no network, a record of every code. */
export function fakeApple(script: AppleScript): AppleClient & { revoked: string[] } {
  const revoked: string[] = [];
  return {
    revoked,
    async revokeAuthorization(code) {
      if (script.unreachable) throw new AppleFailure("unreachable");
      if (script.refuse) throw new AppleFailure("refused");
      revoked.push(code);
    },
  };
}
