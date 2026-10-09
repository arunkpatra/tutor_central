#!/usr/bin/env bun
/** bun tools/release-dev-certificate.ts <serial>...: revokes, through the App Store Connect API, the Apple Development
 *  certificates this CI run made while signing the archive, matched by serial number. A fresh runner makes one each run
 *  and Apple caps how many an account may hold (build 12 stopped on it). Distribution certificates are never touched.
 *  Reads APP_STORE_CONNECT_KEY_PATH, APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID. */
import { createPrivateKey, sign } from "node:crypto";
import { readFileSync } from "node:fs";

export type Certificate = { id: string; attributes: { serialNumber: string; certificateType: string } };
export type AscKey = { keyId: string; issuerId: string; privateKeyPem: string };

const DEVELOPMENT = new Set(["DEVELOPMENT", "IOS_DEVELOPMENT"]);

/** Serials compare as hex, without case or leading zeros (openssl and the API write them differently). */
function normal(serial: string): string {
  return serial.replace(/^serial=/i, "").replace(/[^0-9a-f]/gi, "").replace(/^0+/, "").toUpperCase();
}

/** The ids of the development certificates whose serial this run holds; nothing else. */
export function certificatesToRevoke(list: Certificate[], serials: string[]): string[] {
  const held = new Set(serials.map(normal).filter((s) => s.length > 0));
  return list
    .filter((c) => DEVELOPMENT.has(c.attributes.certificateType) && held.has(normal(c.attributes.serialNumber)))
    .map((c) => c.id);
}

/** The API's bearer token: ES256 over the key, 15 minutes. */
export function ascToken(key: AscKey, now: Date): string {
  const b64 = (o: object) => Buffer.from(JSON.stringify(o)).toString("base64url");
  const iat = Math.floor(now.getTime() / 1000);
  const head = `${b64({ alg: "ES256", kid: key.keyId, typ: "JWT" })}.${b64({ iss: key.issuerId, iat, exp: iat + 900, aud: "appstoreconnect-v1" })}`;
  const signature = sign("sha256", Buffer.from(head), { key: createPrivateKey(key.privateKeyPem), dsaEncoding: "ieee-p1363" });
  return `${head}.${signature.toString("base64url")}`;
}

const API = "https://api.appstoreconnect.apple.com/v1/certificates";

if (import.meta.main) {
  const serials = process.argv.slice(2);
  const path = process.env.APP_STORE_CONNECT_KEY_PATH;
  const keyId = process.env.APP_STORE_CONNECT_KEY_ID;
  const issuerId = process.env.APP_STORE_CONNECT_ISSUER_ID;
  if (!path || !keyId || !issuerId) {
    console.error("APP_STORE_CONNECT_KEY_PATH, APP_STORE_CONNECT_KEY_ID and APP_STORE_CONNECT_ISSUER_ID must be set");
    process.exit(2);
  }
  if (serials.length === 0) {
    console.log("no development certificate in this run's keychain; nothing to revoke");
    process.exit(0);
  }
  const auth = { authorization: `Bearer ${ascToken({ keyId, issuerId, privateKeyPem: readFileSync(path, "utf8") }, new Date())}` };
  const listed = await fetch(`${API}?filter[certificateType]=DEVELOPMENT,IOS_DEVELOPMENT&limit=200`, { headers: auth });
  if (!listed.ok) {
    console.error(`listing certificates answered ${listed.status}`);
    process.exit(1);
  }
  const ids = certificatesToRevoke(((await listed.json()) as { data: Certificate[] }).data, serials);
  for (const id of ids) {
    const gone = await fetch(`${API}/${id}`, { method: "DELETE", headers: auth });
    console.log(`revoked the run's development certificate ${id}: ${gone.status}`);
    if (!gone.ok) process.exit(1);
  }
  if (ids.length === 0) console.log("the run's certificate is not in the account's list; nothing revoked");
}
