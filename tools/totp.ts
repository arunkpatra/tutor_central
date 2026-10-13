#!/usr/bin/env bun
/** bun tools/totp.ts <secret>: the current 6-digit code for a base32 TOTP secret (RFC 6238, HMAC-SHA1, 30 s), for the
 *  admin portal's hand runs and its local-stack test (plan decision 12). Node's crypto, no dependency. */
import { createHmac } from "node:crypto";

const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

export function base32(text: string): Uint8Array {
  const clean = text.replace(/[\s=]/g, "").toUpperCase();
  const bytes: number[] = [];
  let bits = 0;
  let value = 0;
  for (const ch of clean) {
    const i = ALPHABET.indexOf(ch);
    if (i < 0) throw new Error(`not base32: ${ch}`);
    value = (value << 5) | i;
    bits += 5;
    if (bits >= 8) {
      bytes.push((value >>> (bits - 8)) & 0xff);
      bits -= 8;
    }
  }
  return new Uint8Array(bytes);
}

export function totp(secretBase32: string, at: number = Date.now(), step = 30, digits = 6): string {
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(at / 1000 / step)));
  const mac = createHmac("sha1", base32(secretBase32)).update(counter).digest();
  const offset = (mac[mac.length - 1] ?? 0) & 0x0f;
  const code = (mac.readUInt32BE(offset) & 0x7fffffff) % 10 ** digits;
  return String(code).padStart(digits, "0");
}

if (import.meta.main) {
  const secret = process.argv[2];
  if (!secret) {
    console.error("usage: bun tools/totp.ts <base32 secret>");
    process.exit(2);
  }
  console.log(totp(secret));
}
