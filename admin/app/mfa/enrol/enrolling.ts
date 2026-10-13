/** The factor being set up, kept between a wrong code and the next try (ten minutes, HttpOnly): its id and its key.
 *  The square itself is too large for a cookie and is not needed again: the phone has it. */
export const ENROLLING = "tc-enrolling";
export type Enrolling = { factorId: string; secret: string };

export function readEnrolling(value: string | undefined): Enrolling | null {
  if (!value) return null;
  try {
    const parsed = JSON.parse(value) as Partial<Enrolling>;
    return typeof parsed.factorId === "string" && typeof parsed.secret === "string"
      ? { factorId: parsed.factorId, secret: parsed.secret }
      : null;
  } catch {
    return null;
  }
}
