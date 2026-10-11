import Foundation
import Testing
@testable import AppShell

/// The review's R-app-1: the tutor's words from Make reach the note screen once; a later open of the same student's
/// note
/// makes no new note (and no paid call).
@MainActor struct NoteWordsTests {
    @Test func theTutorsWordsAreTakenOnce() {
        let shell = ShellState()
        let student = UUID()
        shell.noteWords[student] = "Please ask her to read the chapter aloud"
        #expect(shell.takeNoteWords(for: student) == "Please ask her to read the chapter aloud")
        #expect(shell.takeNoteWords(for: student) == nil)
    }
}
