import { expect, test } from "bun:test";

// The deploy's three jobs deploy one commit (the review's finding 3): the gate resolves it, the migration and the API
// take the gate's, so a main that moves during the run cannot put another commit behind a green gate.
const workflow = await Bun.file(`${import.meta.dir}/../.github/workflows/deploy.yml`).text();
const job = (name: string) => {
  const start = workflow.indexOf(`\n  ${name}:\n`);
  const next = workflow.slice(start + 1).search(/\n {2}[a-z-]+:\n/);
  return next < 0 ? workflow.slice(start) : workflow.slice(start, start + 1 + next);
};

test("the gate names the commit; the migration and the API take it and resolve none of their own", () => {
  expect(job("gate")).toContain("sha: ${{ steps.commit.outputs.sha }}");
  for (const name of ["migrate", "deploy"]) {
    expect(job(name)).toContain("needs.gate.outputs.sha");
    expect(job(name)).not.toContain("git rev-parse origin/main");
  }
});
