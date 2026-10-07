import Foundation

/// A state the screenshot tool can launch the app into (`tools/shots.ts`): `--state <name>`. Every state a board
/// draws gets a case (information-architecture.md, "Launch states"); the Kit's cases open the Kit at each of its
/// sections, since a screenshot holds one screen.
public enum LaunchState: String, CaseIterable, Sendable {
    case placeholder
    case kit
    case kitFields = "kit-fields"
    case kitSurfaces = "kit-surfaces"
    case kitPatterns = "kit-patterns"
    case kitDialog = "kit-dialog"
    case signin
    case signinEmail = "signin-email"
    case signinCode = "signin-code"
    case signinCodeWrong = "signin-code-wrong"
    case signinPassword = "signin-password"
    case onboarding
    case todayEmpty = "today-empty"
    case laterStudents = "later-students"
    case laterFees = "later-fees"
    case laterAttendance = "later-attendance"
    case laterMore = "later-more"
    case settings

    public static func fromArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> LaunchState? {
        guard let i = arguments.firstIndex(of: "--state"), arguments.indices.contains(i + 1) else { return nil }
        return LaunchState(rawValue: arguments[i + 1])
    }
}
