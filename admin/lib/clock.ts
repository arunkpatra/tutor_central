import frame from "../preview/frame.json";
import { preview } from "./env";

/** Now; in preview mode the fixtures' moment (13 Oct 2026, 10:42 in India), so the pictures read as the boards do. */
export function now(): Date {
  return preview() ? new Date(frame.now) : new Date();
}
