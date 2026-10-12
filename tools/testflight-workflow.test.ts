import { expect, test } from "bun:test";

// Phase 18: the build carries push. The archive's signed app must hold aps-environment (the export re-signs it for the
// App Store's production environment); the run prints it and stops without it, before anything is uploaded.
const workflow = await Bun.file(`${import.meta.dir}/../.github/workflows/testflight.yml`).text();

test("the run prints the archive's push entitlement and stops without it, before the upload", () => {
  const check = workflow.indexOf("- name: Push entitlement");
  expect(check).toBeGreaterThan(workflow.indexOf("- name: Archive (cloud signing)"));
  expect(check).toBeLessThan(workflow.indexOf("- name: Upload to TestFlight"));
  const step = workflow.slice(check, workflow.indexOf("- name: Upload to TestFlight"));
  expect(step).toContain("codesign -d --entitlements");
  expect(step).toContain("plutil -extract aps-environment raw entitlements.plist");
});
