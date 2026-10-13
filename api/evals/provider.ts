// promptfoo's provider (D101): each test runs the kind's agent on the case, as a route would, over an in-memory record
// (the evals touch no database). The real client with ANTHROPIC_API_KEY, or the fake with AI_FAKE=1. The output is what
// was asked and the answer, so the graders judge the answer against the request (as the agent's check does); a refusal's
// answer is `{ "refused": reason }`.
import table from "../models.json" with { type: "json" };
import { runAgent } from "../src/agents/agent.js";
import { anthropicClaude } from "../src/claude.js";
import { fakeClaude, localAnswer } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { agentFor, loadCases, PROBE_CENTRE } from "../src/evals/cases.js";

type Context = { vars: { kind: string; id: string } };

export default class AgentProvider {
  id(): string {
    return "tutor-central-agent";
  }

  async callApi(_prompt: string, context: Context) {
    const { kind, id } = context.vars;
    const found = loadCases([kind]).find((c) => c.id === id);
    if (!found) return { error: `no case ${id}` };
    const { spec, input } = agentFor(found);
    const key = process.env.ANTHROPIC_API_KEY;
    const fake = process.env.AI_FAKE === "1" || !key;
    const claude = fake ? fakeClaude((r) => ({ answer: localAnswer(r) })) : anthropicClaude(key);
    const db = fakeDb();
    const outcome = await runAgent({ db, claude, token: "", requestId: `evals-${id}`, centre: PROBE_CENTRE, key: `evals:${id}`, inputHash: id }, spec, input);
    const paise = db.rows.reduce((n, r) => n + (r.finish?.costPaise ?? 0), 0);
    const tokens = db.rows.reduce((n, r) => ({ prompt: n.prompt + (r.finish?.tokensIn ?? 0), completion: n.completion + (r.finish?.tokensOut ?? 0) }), { prompt: 0, completion: 0 });
    const asked = spec.draft(input);
    const answer = outcome.kind === "ok" ? outcome.parsed : { refused: outcome.kind === "failed" ? outcome.reason : outcome.kind, words: outcome.kind === "failed" ? outcome.words : "service" };
    const output = JSON.stringify({ asked: [asked.system.own, asked.text].filter(Boolean).join("\n"), answer });
    return {
      output,
      cost: fake ? 0 : paise / 100 / table.rupeesPerDollar,
      tokenUsage: { ...tokens, total: tokens.prompt + tokens.completion },
      metadata: {
        repaired: outcome.kind === "ok" && outcome.repaired,
        rows: db.rows.map((r) => `${r.agentStep}:${r.model}:${r.finish?.costPaise ?? 0}`),
        // What the checks found, for a case looked at by hand.
        findings: db.rows.filter((r) => r.agentStep === "check").map((r) => r.finish?.output ?? null),
      },
    };
  }
}
