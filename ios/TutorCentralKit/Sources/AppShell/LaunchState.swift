import Foundation

/// A state the screenshot tool can launch the app into (`tools/shots.ts`): `--state <name>`.
/// Phase 1 knows one. Later phases add cases as their boards are built.
public enum LaunchState: String, CaseIterable, Sendable {
    case placeholder

    public static func fromArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> LaunchState? {
        guard let i = arguments.firstIndex(of: "--state"), arguments.indices.contains(i + 1) else { return nil }
        return LaunchState(rawValue: arguments[i + 1])
    }
}
