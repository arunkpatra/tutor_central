import { expect, test } from "bun:test";
import { base32, totp } from "./totp";

// RFC 6238's SHA-1 vectors: the secret "12345678901234567890", eight digits in the RFC, the last six here.
const SECRET = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";

test("totp answers RFC 6238's SHA-1 codes", () => {
  expect(totp(SECRET, 59_000)).toBe("287082");
  expect(totp(SECRET, 1_111_111_109_000)).toBe("081804");
  expect(totp(SECRET, 1_234_567_890_000)).toBe("005924");
  expect(totp(SECRET, 2_000_000_000_000)).toBe("279037");
});

test("base32 reads the alphabet, ignores spaces and case, and refuses what is not in it", () => {
  expect(new TextDecoder().decode(base32("gezd gnbv"))).toBe("12345");
  expect(() => base32("GEZ1")).toThrow("not base32");
});
