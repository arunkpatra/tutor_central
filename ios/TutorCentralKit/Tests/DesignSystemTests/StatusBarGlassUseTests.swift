import Foundation
import Testing

/// U24: the pushed AI and scan screens hide the navigation bar, so each draws the system's glass under the status bar
/// once
/// it scrolls, as the tab roots (U1) and Help do (P8-Scan-List-Scrolled, P8-Check-Marks-Scrolled). Other pushed screens
/// without it are the polish list's (U32), each to its board first.
struct StatusBarGlassUseTests {
    static var features: URL {
        URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/Features")
    }

    static let pushedAIScreens = [
        "Students/ScanReviewView", "Students/ScanRegisterView", "AITools/AssistantView", "AITools/GenerateFormView",
        "AITools/ResultView", "AITools/NoteResultView", "AITools/HistoryView", "AITools/CheckIntroView",
        "AITools/CheckPagesView", "AITools/CheckSchemeView", "AITools/CheckResultView",
    ]

    @Test(arguments: pushedAIScreens) func thePushedAIScreenDrawsTheGlass(_ name: String) throws {
        let text = try String(contentsOf: Self.features.appending(path: "\(name).swift"), encoding: .utf8)
        #expect(text.contains(".toolbar(.hidden, for: .navigationBar)"), "\(name) hides the navigation bar")
        #expect(text.contains(".statusBarGlass()"), "\(name)")
    }
}
