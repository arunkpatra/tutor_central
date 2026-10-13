import { expect, test } from "bun:test";

// The admin portal's deploy (D78): one commit from the gate, and that commit in the running portal, not only in the build
// (the review's R-a1: /health reads TC_COMMIT at request time, so a build-time variable answers "local" and the smoke fails).
const workflow = await Bun.file(`${import.meta.dir}/../.github/workflows/deploy-admin.yml`).text();

test("the deploy job takes the gate's commit and resolves none of its own", () => {
  expect(workflow).toContain("sha: ${{ steps.commit.outputs.sha }}");
  const deploy = workflow.slice(workflow.indexOf("\n  deploy:\n"));
  expect(deploy).toContain("needs.gate.outputs.sha");
  expect(deploy).not.toContain("git rev-parse origin/main");
});

test("the commit reaches the running portal: the deploy sets TC_COMMIT, as the API's does", () => {
  expect(workflow).toMatch(/vercel deploy --prebuilt --prod --env TC_COMMIT="\$COMMIT"|"\$VERCEL_CLI" deploy --prebuilt --prod --env TC_COMMIT="\$COMMIT"/);
});

test("the portal's functions run in Mumbai beside the database, as the API's do (every page makes several calls to it)", async () => {
  const admin = JSON.parse(await Bun.file(`${import.meta.dir}/../admin/vercel.json`).text()) as { regions?: string[] };
  const api = JSON.parse(await Bun.file(`${import.meta.dir}/../api/vercel.json`).text()) as { regions?: string[] };
  expect(admin.regions).toEqual(["bom1"]);
  expect(admin.regions).toEqual(api.regions);
});
