import Domain
import Foundation
import Testing

/// D107: feedback kept on the generation it is about; the reasons of the brief's, the mock's and the note's menus.
struct FeedbackTests {
    @Test func feedbackCarriesWhatEachKindNeeds() {
        let id = UUID()
        #expect(Feedback.edit(id, sent: "नमस्ते रमेश जी") == Feedback(
            generation: id,
            kind: .edit,
            reason: nil,
            revised: .text("नमस्ते रमेश जी")
        ))
        #expect(Feedback.again(id, reason: String(repeating: "x", count: 250)).reason?.count == 200)
        #expect(Feedback.replace(id, with: .photo).revised == .photo && Feedback.replace(id, with: .photo).revised?
            .text == nil)
    }

    @Test func eachMenuHasItsFourReasonsAndTheirLines() {
        #expect(BriefReason.menu.map(\.label) == [
            "Shorter",
            "Simpler words",
            "A different example",
            "More on the mistakes",
        ])
        #expect(MockReason.menu.map(\.label) == [
            "Easier",
            "Harder",
            "Different questions",
            "Closer to the school's papers",
        ])
        #expect(NoteReason.menu.map(\.label) == ["Shorter", "Warmer", "Plainer words", "Less about marks"])
        #expect(BriefReason.shorter.line == "A shorter brief is on its way. This one stays until it arrives.")
        #expect(MockReason.easier.line == "An easier mock is on its way. This one stays until it arrives.")
        #expect(NoteReason.lessAboutMarks
            .line == "A note with less about marks is on its way. This one stays until it arrives.")
        #expect(NoteReason.own("  Mention the PTM  ").words == "Mention the PTM")
        #expect(BriefReason.own("x").line == "A new brief is on its way. This one stays until it arrives.")
    }
}
