import { expect, test } from "bun:test";
import { decodeImage, MAX_IMAGE_BYTES } from "../src/images.js";

const b64 = (bytes: number[]) => Buffer.from(bytes).toString("base64");
const jpeg = b64([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]);
const png = b64([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const webp = b64([0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50]);

test("bytes that are not the declared type are refused", () => {
  expect(decodeImage({ imageBase64: jpeg, mediaType: "image/jpeg" })).toMatchObject({ mediaType: "image/jpeg", bytes: 8 });
  expect(decodeImage({ imageBase64: png, mediaType: "image/png" })).toMatchObject({ bytes: 8 });
  expect(decodeImage({ imageBase64: webp, mediaType: "image/webp" })).toMatchObject({ bytes: 12 });
  expect(decodeImage({ imageBase64: png, mediaType: "image/jpeg" })).toBe("That photo isn't a JPEG, PNG or WebP.");
  expect(decodeImage({ imageBase64: b64([1, 2, 3, 4]), mediaType: "image/png" })).toBe("That photo isn't a JPEG, PNG or WebP.");
});

test("base64 that does not decode, and a photo over 3 MB, are refused", () => {
  expect(decodeImage({ imageBase64: "!!!!", mediaType: "image/jpeg" })).toBe("That photo didn't arrive whole.");
  const big = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff]), Buffer.alloc(MAX_IMAGE_BYTES)]).toString("base64");
  expect(decodeImage({ imageBase64: big, mediaType: "image/jpeg" })).toBe("That photo is over 3 MB.");
});
