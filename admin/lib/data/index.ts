import { preview } from "../env";
import { previewData } from "./preview";
import { realData } from "./real";
import type { Data } from "./types";

let override: Data | null = null;

/** The `Data` a page reads: the fixtures in preview mode (D96), else the database as the platform. */
export function data(): Data {
  return override ?? (preview() ? previewData : realData());
}

/** A test's seam: run `fn` with a fake `Data` in place of the real one. */
export async function withData<T>(fake: Data, fn: () => Promise<T>): Promise<T> {
  override = fake;
  try {
    return await fn();
  } finally {
    override = null;
  }
}
