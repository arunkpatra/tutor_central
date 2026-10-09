import { expect, test } from "bun:test";
import { createPrivateKey, createPublicKey, generateKeyPairSync, verify } from "node:crypto";
import { certificatesToRevoke, ascToken } from "./release-dev-certificate";

const distribution = { id: "C", attributes: { serialNumber: "5C1F00AA", certificateType: "DISTRIBUTION" } };
const list = [
  { id: "A", attributes: { serialNumber: "5C1F00AA", certificateType: "DEVELOPMENT" } },
  { id: "B", attributes: { serialNumber: "77AB", certificateType: "DEVELOPMENT" } },
  distribution,
];

test("only the development certificate whose serial this run holds is revoked", () => {
  // openssl prints "serial=5C1F00AA"; the keychain may give leading zeros or lower case.
  expect(certificatesToRevoke(list, ["005c1f00aa"])).toEqual(["A"]);
});

test("nothing is revoked when the run holds no matching serial", () => {
  expect(certificatesToRevoke(list, [])).toEqual([]);
  expect(certificatesToRevoke(list, ["1234"])).toEqual([]);
});

test("a distribution certificate is never revoked, even with a matching serial", () => {
  expect(certificatesToRevoke([distribution], ["5C1F00AA"])).toEqual([]);
});

test("the App Store Connect token is an ES256 JWT for the key, valid under twenty minutes", () => {
  const { privateKey } = generateKeyPairSync("ec", { namedCurve: "P-256" });
  const pem = privateKey.export({ type: "pkcs8", format: "pem" }).toString();
  const token = ascToken({ keyId: "KEY1", issuerId: "ISS", privateKeyPem: pem }, new Date("2026-10-09T10:00:00Z"));
  const [h = "", p = "", s = ""] = token.split(".");
  const header = JSON.parse(Buffer.from(h, "base64url").toString());
  const claims = JSON.parse(Buffer.from(p, "base64url").toString());
  expect(header).toEqual({ alg: "ES256", kid: "KEY1", typ: "JWT" });
  expect(claims.iss).toBe("ISS");
  expect(claims.aud).toBe("appstoreconnect-v1");
  expect(claims.exp - claims.iat).toBeLessThanOrEqual(1200);
  const ok = verify(
    "sha256",
    Buffer.from(`${h}.${p}`),
    { key: createPublicKey(createPrivateKey(pem)), dsaEncoding: "ieee-p1363" },
    Buffer.from(s, "base64url"),
  );
  expect(ok).toBe(true);
});
