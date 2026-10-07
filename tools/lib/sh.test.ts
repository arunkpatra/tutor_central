import { expect, test } from "bun:test";
import { must, sh } from "./sh";

test("sh captures stdout and exit code", async () => {
  const r = await sh(["sh", "-c", "echo hi; exit 3"]);
  expect(r.stdout.trim()).toBe("hi");
  expect(r.code).toBe(3);
});

test("sh passes cwd and env", async () => {
  const r = await sh(["sh", "-c", "pwd; echo $TC_X"], { cwd: "/tmp", env: { TC_X: "y" } });
  expect(r.stdout).toContain("/tmp");
  expect(r.stdout).toContain("y");
});

test("sh reports a missing program as exit 127 instead of throwing", async () => {
  const r = await sh(["tc-no-such-program-xyz"]);
  expect(r.code).toBe(127);
  expect(r.stderr).toContain("tc-no-such-program-xyz");
});

test("must throws with the command and stderr on failure", async () => {
  await expect(must(["sh", "-c", "echo boom >&2; exit 1"])).rejects.toThrow(/boom/);
});

test("sh feeds stdin when given", async () => {
  const r = await sh(["cat"], { stdin: "fed\0through" });
  expect(r.stdout).toBe("fed\0through");
});
