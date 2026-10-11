import Testing
@testable import Domain

/// Make's kinds (plan/phase-15-plan.md decision 2; components.md 10.7).
struct MakeKindTests {
    @Test func theKindsAreTheBoardsInTwoGroups() {
        #expect(MakeKind.forSomeone.map(\.title) == [
            "Sheet",
            "Worked example",
            "Figure",
            "Note to a parent",
            "Mock test",
        ])
        #expect(MakeKind.forYou.map(\.title) == ["Brief", "Question paper", "Homework", "Worksheet"])
    }

    @Test func eachKindHasTheBoardsSymbolAndLine() {
        #expect(MakeKind.sheet.symbol == "doc.text" && MakeKind.sheet
            .line == "Practice or homework at a level, with a key")
        #expect(MakeKind.figure.symbol == "square.grid.2x2")
        #expect(MakeKind.noteToParent.line == "The week, or anything you want to say, in their language")
        #expect(MakeKind.mock.symbol == "doc.text.magnifyingglass")
        #expect(MakeKind.worksheet.symbol == "pencil.line" && MakeKind.homework.symbol == "checklist")
    }

    @Test func theV1KindsOpenV1sForms() {
        #expect(MakeKind.paper.v1Kind == .paper && MakeKind.homework.v1Kind == .homework)
        #expect(MakeKind.worksheet.v1Kind == .worksheet && MakeKind.sheet.v1Kind == nil)
        #expect(MakeKind.brief.v1Kind == nil)
    }

    @Test func eachKindsButtonSaysWhatItMakes() {
        #expect(MakeKind.sheet.makeLabel == "Make the sheet")
        #expect(MakeKind.noteToParent.makeLabel == "Write the note")
        #expect(MakeKind.mock.makeLabel == "Make the mock")
        #expect(MakeKind.workedExample.makeLabel == "Make the example")
        #expect(MakeKind.sheet.making == "Making the sheet")
    }
}
