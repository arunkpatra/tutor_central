import Foundation
import Testing
@testable import Domain

struct GenerationTests {
    static let maths = UUID(uuidString: "33333333-3333-3333-3333-333333333331") ?? UUID()

    @Test func kindsHaveTheirWords() {
        #expect(GenerationKind.allCases.map(\.title) == ["Question paper", "Homework", "Worksheet", "Progress note"])
        #expect(GenerationKind.paper.createLabel == "Create the paper")
        #expect(GenerationKind.progressNote.createLabel == "Write the note")
        #expect(GenerationKind.progressNote.needsConsent && !GenerationKind.paper.needsConsent)
        #expect(GenerationKind(rawValue: "progress_note") == .progressNote, "the API's and the enum's spelling")
    }

    @Test func aRequestIsValidWithAClassAndATopicOrAStudentAndObservations() {
        #expect(!GenerateRequest.paper(PaperForm()).isValid)
        #expect(!GenerateRequest.paper(PaperForm(classID: Self.maths, subject: "Mathematics", topic: "   ")).isValid)
        #expect(GenerateRequest.paper(PaperForm(
            classID: Self.maths,
            subject: "Mathematics",
            topic: "Quadratic equations"
        ))
        .isValid)
        let long = String(repeating: "x", count: 201)
        #expect(!GenerateRequest.paper(PaperForm(classID: Self.maths, subject: "M", topic: long)).isValid)
        #expect(!GenerateRequest.progressNote(NoteForm(studentID: nil, observations: "Improving", tone: .warm)).isValid)
        #expect(GenerateRequest.progressNote(NoteForm(studentID: UUID(), observations: "Improving", tone: .warm))
            .isValid)
        #expect(GenerateRequest.paper(PaperForm()).kind == .paper)
        #expect(GenerateRequest.worksheet(WorksheetForm()).kind == .worksheet)
    }

    @Test func theCreatingLineNamesTheWork() {
        let paper = GenerateRequest.paper(PaperForm(
            classID: Self.maths,
            subject: "Mathematics",
            topic: "Quadratic equations"
        ))
        #expect(paper.creatingLine(studentFirstName: nil) == "Writing 10 questions on Quadratic equations")
        let homework = GenerateRequest.homework(HomeworkForm(
            classID: Self.maths,
            subject: "Science",
            topic: "Cell structure"
        ))
        #expect(homework.creatingLine(studentFirstName: nil) == "Writing 5 questions on Cell structure")
        let note = GenerateRequest.progressNote(NoteForm(studentID: UUID(), observations: "x", tone: .plain))
        #expect(note.creatingLine(studentFirstName: "Hemanth") == "Writing a note about Hemanth")
    }

    @Test func formsCarryTheirDefaultsAndRanges() {
        #expect(PaperForm().questions == 10 && PaperForm().marks == 20 && PaperForm().level == .medium)
        #expect(HomeworkForm().questions == 5 && WorksheetForm().questions == 12 && WorksheetForm().withAnswers)
        #expect(PaperForm.questionsRange == 1 ... 50 && PaperForm.marksRange == 5 ... 100)
        #expect(NoteForm.observationsLimit == 2000)
        #expect(Level.allCases.map(\.title) == ["Easy", "Medium", "Hard"] && Tone.allCases.map(\.title) == [
            "Warm",
            "Plain",
        ])
    }
}
