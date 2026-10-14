import type { Kind } from "./agents/agent.js";
import { kindFor } from "./agents/kinds/index.js";
import type { MakeInput } from "./schemas.js";

/** The kind's agent for a body of `/ai/make` (D99; plan/phase-18-plan.md decision 12): the route and the plan, note and
 *  exam jobs run the same agent for the same kind, with the body as its input. Every made kind has one (Phase 21). */
export function makeAgent(v: MakeInput): Kind<unknown, unknown> {
  const spec = kindFor(v.kind);
  if (!spec) throw new Error(`${v.kind} has no agent`);
  return spec;
}
