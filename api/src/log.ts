/** The API's logs (D77): one JSON line per event, with the request id, so Vercel's hour of logs reads by request. */
export type Level = "info" | "warn" | "error";

function plain(value: unknown): unknown {
  return value instanceof Error ? { name: value.name, message: value.message } : value;
}

export function line(level: Level, fields: Record<string, unknown>): string {
  const out: Record<string, unknown> = { t: new Date().toISOString(), level };
  for (const [key, value] of Object.entries(fields)) out[key] = plain(value);
  return JSON.stringify(out);
}

export const log = {
  info: (fields: Record<string, unknown>) => console.log(line("info", fields)),
  warn: (fields: Record<string, unknown>) => console.warn(line("warn", fields)),
  error: (fields: Record<string, unknown>) => console.error(line("error", fields)),
};
