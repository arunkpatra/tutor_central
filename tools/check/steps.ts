import { sh } from "../lib/sh";
import { run } from "./run";

export type Step = {
  name: string;
  /** Globs relative to the repo root that decide whether the step runs again. */
  inputs: string[];
  run: () => Promise<void>;
  /** Return a reason to skip (printed), or null to run. */
  skipIf?: () => Promise<string | null>;
};

/** Versions of every tool a step depends on, and the simulator. A tool missing on this machine reads as empty (sh answers 127). */
export async function toolchainSalt(): Promise<string> {
  const version = async (cmd: string[]) => (await sh(cmd)).stdout.replace(/\s+/g, " ").trim();
  const xcode = await version(["xcodebuild", "-version"]);
  const swiftformat = await version(["swiftformat", "--version"]);
  const swiftlint = await version(["swiftlint", "version"]);
  return `${xcode}|${swiftformat}|${swiftlint}|bun ${Bun.version}|${simulatorDestination(process.env)}`;
}

/** Why the db step should not run here, or null. CI runs it only on the job that sets TC_DB_IN_CI. */
export function dbSkipReason(env: Record<string, string | undefined>, supabaseRunning: boolean): string | null {
  if (env.CI && !env.TC_DB_IN_CI) return "not on this runner (the api-db job runs it)";
  return supabaseRunning ? null : "local supabase is not running (cd supabase && supabase start)";
}

/** The simulator the iOS step builds and tests on. The iPhone 17 is on both this Mac and CI's Xcode 27 image. */
export function simulatorDestination(env: Record<string, string | undefined>): string {
  return `platform=iOS Simulator,name=${env.TC_SIMULATOR || "iPhone 17"}`;
}

/** A fresh clone has no ios/Config/Local.xcconfig; XcodeGen's own error does not say what to do. */
export function localConfigHint(exists: boolean): string | null {
  return exists
    ? null
    : "ios/Config/Local.xcconfig is missing: cp ios/Config/Local.xcconfig.example ios/Config/Local.xcconfig and fill it from `cd supabase && supabase status -o env`";
}

/** The simulator build never signs: the Sign in with Apple entitlement must not make it look for a team. */
const XCODEBUILD = `xcodebuild -project TutorCentral.xcodeproj -scheme TutorCentral -destination '${simulatorDestination(process.env)}' CODE_SIGNING_ALLOWED=NO`;
const IOS_INPUTS = [
  "ios/**/*.swift",
  "ios/project.yml",
  "ios/App/Info.plist",
  "ios/Config/*.xcconfig",
  "ios/TutorCentralKit/Package.resolved",
  // The token test reads the document (D25).
  "docs/design/design-tokens.md",
];

export const STEPS: Step[] = [
  {
    name: "format",
    inputs: ["ios/**/*.swift", "ios/.swiftformat"],
    run: () => run("swiftformat --lint .", "ios"),
  },
  {
    name: "lint",
    inputs: ["ios/**/*.swift", "ios/.swiftlint.yml"],
    run: () => run("swiftlint --strict --quiet", "ios"),
  },
  {
    name: "ios",
    inputs: IOS_INPUTS,
    run: async () => {
      const hint = localConfigHint(await Bun.file("ios/Config/Local.xcconfig").exists());
      if (hint) throw new Error(hint);
      await run("xcodegen generate --quiet", "ios");
      await run(`${XCODEBUILD} build-for-testing 2>&1 | xcbeautify --quiet`, "ios");
      await run(`${XCODEBUILD} test-without-building 2>&1 | xcbeautify --quiet`, "ios");
    },
  },
  {
    name: "tools",
    inputs: ["tools/**/*.ts", "package.json", "tsconfig.json", "bun.lock"],
    run: async () => {
      await run("bun run tsc -p tsconfig.json");
      await run("bun test tools");
    },
  },
  {
    name: "api",
    inputs: ["api/src/**", "api/test/**", "api/package.json", "api/tsconfig.json", "api/vercel.json", "bun.lock"],
    run: () => run("bun run check", "api"),
  },
  {
    name: "db",
    inputs: ["supabase/migrations/**", "supabase/seed.sql", "supabase/tests/**", "supabase/package.json", "supabase/tsconfig.json"],
    skipIf: async () => dbSkipReason(process.env, (await sh(["supabase", "status"], { cwd: "supabase" })).code === 0),
    run: async () => {
      // A clean schema for the tests, then the seed back for the app.
      await run("bun run --cwd .. tsc -p supabase/tsconfig.json", "supabase");
      await run("supabase db reset --no-seed > /dev/null", "supabase");
      await run("bun test tests", "supabase");
      // types.ts is what the migrations produce, or the step says how to regenerate it.
      await run(
        "supabase gen types typescript --local > .types.generated.ts && diff -q .types.generated.ts types.ts > /dev/null && rm .types.generated.ts || (rm -f .types.generated.ts; echo 'supabase/types.ts is stale: run supabase gen types typescript --local > types.ts'; exit 1)",
        "supabase",
      );
      await run("supabase db reset > /dev/null", "supabase");
    },
  },
];
