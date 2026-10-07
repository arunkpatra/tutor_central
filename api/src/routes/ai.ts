import { Hono } from "hono";
import type { ZodType } from "zod";
import type { Vars } from "../auth";
import { CheckPaperInput, GenerateInput, ScanRegisterInput } from "../schemas";

const ROUTES: [path: string, schema: ZodType][] = [
  ["/generate", GenerateInput],
  ["/scan-register", ScanRegisterInput],
  ["/check-paper", CheckPaperInput],
];

/** The AI routes. Each validates its body; the work itself arrives in Phase 6 (docs/spec.md section 6). */
export const aiRoutes = new Hono<Vars>();

for (const [path, schema] of ROUTES) {
  aiRoutes.post(path, async (c) => {
    const body: unknown = await c.req.json().catch(() => undefined);
    const parsed = schema.safeParse(body);
    if (!parsed.success) {
      const issues = parsed.error.issues.map((i) => (i.path.length ? `${i.path.join(".")}: ${i.message}` : i.message));
      return c.json({ error: issues.join("; ") }, 400);
    }
    return c.json({ error: "not built yet", contract: "Phase 6", route: `/ai${path}` }, 501);
  });
}
