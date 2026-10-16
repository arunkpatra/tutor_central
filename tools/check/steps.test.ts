import { expect, test } from "bun:test";
import { dbSkipReason, iosTestCommand, localConfigHint, simulatorDestination, STEPS } from "./steps";

test("the db step runs locally when supabase is up", () => {
  expect(dbSkipReason({}, true)).toBeNull();
});

test("the db step is skipped with a reason when local supabase is down", () => {
  expect(dbSkipReason({}, false)).toBe("local supabase is not running (cd supabase && supabase start)");
});

test("in CI the db step runs only on the runner that asks for it", () => {
  expect(dbSkipReason({ CI: "true" }, true)).toBe("not on this runner (the api-web-db job runs it)");
  expect(dbSkipReason({ CI: "true", TC_DB_IN_CI: "1" }, true)).toBeNull();
  expect(dbSkipReason({ CI: "true", TC_DB_IN_CI: "1" }, false)).toContain("not running");
});

test("steps run in the documented order", () => {
  expect(STEPS.map((s) => s.name)).toEqual(["format", "lint", "ios", "tools", "api", "web", "admin", "db"]);
});

test("the simulator is the iPhone 17 unless TC_SIMULATOR names another", () => {
  expect(simulatorDestination({})).toBe("platform=iOS Simulator,name=iPhone 17");
  expect(simulatorDestination({ TC_SIMULATOR: "iPhone 17 Pro" })).toBe("platform=iOS Simulator,name=iPhone 17 Pro");
});

test("a missing Local.xcconfig gets a one-line hint instead of XcodeGen's error", () => {
  expect(localConfigHint(false)).toContain("cp ios/Config/Local.xcconfig.example ios/Config/Local.xcconfig");
  expect(localConfigHint(true)).toBeNull();
});

test("a failing test reports at once instead of stalling ten minutes collecting simulator diagnostics", () => {
  expect(iosTestCommand()).toContain(" test-without-building ");
  expect(iosTestCommand()).toContain(" -collect-test-diagnostics never");
});

test("the web step runs again when a file its tests read changes", () => {
  const web = STEPS.find((s) => s.name === "web");
  // pages.test.ts holds /support's answers to Help's in the app; tokens.test.ts reads the token document.
  expect(web?.inputs).toContain("ios/TutorCentralKit/Sources/Features/Settings/Help/HelpView.swift");
  expect(web?.inputs).toContain("docs/design/design-tokens.md");
});

test("the ios step runs again when a sample or resource its tests read changes", () => {
  // ContractTests decode the fake's samples (bun contract writes them); a changed sample left the step cached (Phase 21).
  const ios = STEPS.find((s) => s.name === "ios");
  expect(ios?.inputs).toContain("ios/TutorCentralKit/Tests/**");
  expect(ios?.inputs).toContain("ios/TutorCentralKit/Sources/**");
});

test("the admin step runs again when the token document changes", () => {
  expect(STEPS.find((s) => s.name === "admin")?.inputs).toContain("docs/design/design-tokens.md");
});

test("the brand kit's copies are inputs: the tools step holds them to the manifest, ios and the sites read them (D122)", async () => {
  const step = (name: string) => STEPS.find((s) => s.name === name)?.inputs ?? [];
  const covered = (inputs: string[], path: string) => inputs.some((g) => new Bun.Glob(g).match(path));
  const manifest = (await Bun.file("docs/design/brand-kit.json").json()) as { files: { path: string }[] };
  for (const { path } of manifest.files) expect(covered(step("tools"), path), path).toBe(true);
  expect(covered(step("tools"), "docs/design/brand-kit.json")).toBe(true);
  for (const path of ["ios/App/TutorCentral.icon/icon.json", "ios/App/Assets.xcassets/LaunchMark.imageset/LaunchMark.svg"])
    expect(covered(step("ios"), path), path).toBe(true);
  for (const name of ["web", "admin"]) expect(covered(step(name), "docs/design/brand/tc-mark-ink-small.svg"), name).toBe(true);
});
