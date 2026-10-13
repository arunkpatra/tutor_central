// promptfoo's javascript assertion (D101): the case's free checks (the schema, the kind's verify, its expectations), by
// the same code the nightly scores with (src/evals/cases.ts). A fake run (AI_FAKE=1) holds the schema and verify alone:
// the fake's samples are not the cases' answers, so their expectations are a real run's.
import type { AgentOutcome } from "../src/agents/agent.js";
import { agentFor, evaluate, loadCases } from "../src/evals/cases.js";

type Context = { vars: { kind: string; id: string } };

export default (output: string, context: Context) => {
  const found = loadCases([context.vars.kind]).find((c) => c.id === context.vars.id);
  if (!found) return { pass: false, score: 0, reason: `no case ${context.vars.id}` };
  const parsed = (JSON.parse(output) as { answer: Record<string, unknown> }).answer;
  const outcome: AgentOutcome<unknown> =
    typeof parsed.refused === "string"
      ? { kind: "failed", id: "", costPaise: 0, reason: parsed.refused, words: parsed.words === "service" ? "service" : "refused" }
      : { kind: "ok", id: "", parsed, costPaise: 0, repaired: false, replay: false };
  const fake = process.env.AI_FAKE === "1";
  if (fake && found.expect.refused) return { pass: true, score: 1, reason: "a refusal is a real run's" };
  const scored = evaluate(found, agentFor(found).input, outcome);
  const pass = scored.schema && scored.verify && (fake || scored.expect);
  return { pass, score: pass ? 1 : 0, reason: pass ? "the schema, verify and the case hold" : scored.reasons.join("; ") };
};
