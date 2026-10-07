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

/** Versions of every tool a step depends on. A tool missing on this machine reads as empty (sh answers 127). */
export async function toolchainSalt(): Promise<string> {
  const version = async (cmd: string[]) => (await sh(cmd)).stdout.replace(/\s+/g, " ").trim();
  const xcode = await version(["xcodebuild", "-version"]);
  const swiftformat = await version(["swiftformat", "--version"]);
  const swiftlint = await version(["swiftlint", "version"]);
  return `${xcode}|${swiftformat}|${swiftlint}|bun ${Bun.version}`;
}

const SIM = "platform=iOS Simulator,name=iPhone 17 Pro";
const XCODEBUILD = `xcodebuild -project TutorCentral.xcodeproj -scheme TutorCentral -destination '${SIM}'`;
const IOS_INPUTS = [
  "ios/**/*.swift",
  "ios/project.yml",
  "ios/App/Info.plist",
  "ios/Config/*.xcconfig",
  "ios/TutorCentralKit/Package.resolved",
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
];
