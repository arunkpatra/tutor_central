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
  expect(STEPS.map((s) => s.name)).toEqual(["format", "lint", "ios", "tools", "api", "web", "db"]);
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
