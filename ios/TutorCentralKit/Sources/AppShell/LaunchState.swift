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
    case studentsEmpty = "students-empty"
    case studentsFew = "students-few"
    case students
    case studentsSearching = "students-searching"
    case studentsFiltered = "students-filtered"
    case studentsAddMenu = "students-add-menu"
    case studentNew = "student-new"
    case studentNewFilled = "student-new-filled"
    case studentNewInvalid = "student-new-invalid"
    case student
    case studentArchived = "student-archived"
    case studentArchiveConfirm = "student-archive-confirm"
    case studentDeleteConfirm = "student-delete-confirm"
    case studentEdit = "student-edit"
    case classesEmpty = "classes-empty"
    case classes
    case classNew = "class-new"
    case classEdit = "class-edit"
    case classArchiveConfirm = "class-archive-confirm"

    public static func fromArguments(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> LaunchState? {
        guard let i = arguments.firstIndex(of: "--state"), arguments.indices.contains(i + 1) else { return nil }
        return LaunchState(rawValue: arguments[i + 1])
    }
}
