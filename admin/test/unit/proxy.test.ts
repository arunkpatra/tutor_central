import { expect, test } from "bun:test";
import { config } from "../../proxy";

/** The proxy's matcher as Next reads it: a request it matches meets the session check; one it does not is served as is. */
const matched = (path: string) => config.matcher.some((m) => new RegExp(`^${m}$`).test(path));

test("the tab icons and the health check are served without a session; the pages are not (D78, D122)", () => {
  for (const path of ["/icon.svg", "/favicon.ico", "/health"]) expect(matched(path), path).toBe(false);
  for (const path of ["/centres", "/sign-in", "/calls/abc", "/"]) expect(matched(path), path).toBe(true);
});
