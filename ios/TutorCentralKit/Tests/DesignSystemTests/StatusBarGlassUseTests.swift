import Foundation
import Testing

/// U24: the pushed AI and scan screens hide the navigation bar, so each draws the system's glass under the status bar
/// once it scrolls, as the tab roots (U1) and Help do (P8-Scan-List-Scrolled, P8-Check-Marks-Scrolled). Other pushed
/// screens drew none until U32 and U40 (Phase 15) put it on each, U24's pattern.
struct StatusBarGlassUseTests {
    static var features: URL {
        URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/Features")
    }

    static let pushedAIScreens = [
        "Students/ScanReviewView", "Students/ScanRegisterView", "Make/MakeHomeView", "Make/GenerateFormView",
        "Make/ResultView", "Make/NoteResultView", "Make/HistoryView", "Make/CheckIntroView",
        "Make/CheckPagesView", "Make/CheckSchemeView", "Make/CheckResultView",
    ]

    @Test(arguments: pushedAIScreens) func thePushedAIScreenDrawsTheGlass(_ name: String) throws {
        let text = try String(contentsOf: Self.features.appending(path: "\(name).swift"), encoding: .utf8)
        #expect(text.contains(".toolbar(.hidden, for: .navigationBar)"), "\(name) hides the navigation bar")
        #expect(text.contains(".statusBarGlass()"), "\(name)")
    }

    /// U32, U40: every other pushed screen that scrolls.
    static let pushedScreens = [
        "Attendance/HistoryView", "Attendance/StudentMonthView", "Schedule/ScheduleView", "Today/TasksView",
        "Students/ClassesView", "Students/ClassDetailView", "Students/StudentDetailView", "Fees/StudentFeesView",
        "Fees/PaymentsView", "Fees/ReportsView", "Settings/Account/AccountView", "Settings/Account/DeleteAccountView",
        "Settings/Pending/PendingChangesView",
    ]

    @Test(arguments: pushedScreens) func thePushedScreenDrawsTheGlass(_ name: String) throws {
        let text = try String(contentsOf: Self.features.appending(path: "\(name).swift"), encoding: .utf8)
        #expect(text.contains(".statusBarGlass()"), "\(name)")
    }
}
