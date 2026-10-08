import type { ImageInput } from "./claude.js";

export type DecodedImage = ImageInput & { bytes: number };
export const MAX_IMAGE_BYTES = 3 * 1024 * 1024;

const SIGNATURES: Record<ImageInput["mediaType"], (b: Buffer) => boolean> = {
  "image/jpeg": (b) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff,
  "image/png": (b) => b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  "image/webp": (b) => b.subarray(0, 4).toString("latin1") === "RIFF" && b.subarray(8, 12).toString("latin1") === "WEBP",
};

/** The photo checked before it costs anything: whole base64, at most 3 MB, and bytes that are what the body says they
 *  are. A string is the refusal, in words. */
export function decodeImage(image: { imageBase64: string; mediaType: ImageInput["mediaType"] }): DecodedImage | string {
  const bytes = Buffer.from(image.imageBase64, "base64");
  const strip = (s: string) => s.replace(/=+$/, "");
  if (strip(bytes.toString("base64")) !== strip(image.imageBase64)) return "That photo didn't arrive whole.";
  if (bytes.length > MAX_IMAGE_BYTES) return "That photo is over 3 MB.";
  if (!SIGNATURES[image.mediaType](bytes)) return "That photo isn't a JPEG, PNG or WebP.";
  return { mediaType: image.mediaType, base64: image.imageBase64, bytes: bytes.length };
}
