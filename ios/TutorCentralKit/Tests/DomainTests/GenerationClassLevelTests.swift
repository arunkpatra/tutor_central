import Foundation
import Testing
@testable import Domain

/// The AI forms take the class by level, no batch (P12-Form-Paper-Class; the owner, 2026-10-11).
struct GenerationClassLevelTests {
    @Test func aPaperIsValidWithAClassLevelAndNoBatch() {
        #expect(GenerateRequest.paper(PaperForm(classLevel: .ten, subject: "Mathematics", topic: "Trigonometry"))
            .isValid)
        #expect(GenerateRequest.homework(HomeworkForm(classLevel: .five, subject: "English", topic: "Nouns")).isValid)
        #expect(GenerateRequest.worksheet(WorksheetForm(classLevel: .lkg, subject: "Numbers", topic: "Count")).isValid)
        #expect(!GenerateRequest.paper(PaperForm(subject: "Mathematics", topic: "Trigonometry")).isValid)
        // A paper made from a batch before can still be made again from History.
        #expect(GenerateRequest.paper(PaperForm(classID: UUID(), subject: "Mathematics", topic: "Sets")).isValid)
        #expect(GenerateRequest.paper(PaperForm(classLevel: .ten)).classLevel == .ten)
        #expect(GenerateRequest.progressNote(NoteForm()).classLevel == nil)
    }

    @Test func aFormKeptBeforeTheClassLevelStillReads() throws {
        let old = #"{"paper":{"_0":{"classID":"11111111-1111-1111-1111-111111111111","subject":"Maths","#
            + #""topic":"Sets","level":"medium","questions":10,"marks":20}}}"#
        let request = try JSONDecoder().decode(GenerateRequest.self, from: Data(old.utf8))
        guard case let .paper(form) = request else {
            Issue.record("not a paper")
            return
        }
        #expect(form.classLevel == nil && form.classID != nil && form.subject == "Maths")
    }

    @Test func historyNamesTheClassLevelElseTheBatch() {
        let at = Date(timeIntervalSince1970: 1_791_700_000)
        let result = GenerationResult.paper(PaperResult(title: "T", sections: []))
        let byLevel = Generation(
            id: UUID(), kind: .paper, createdAt: at,
            request: .paper(PaperForm(classLevel: .ten, subject: "Mathematics", topic: "T")), result: result
        )
        let today = Day(at, calendar: DayHeading.india)
        #expect(byLevel.line(className: { _ in "Class 10 Maths" }, today: today, calendar: DayHeading.india).hasPrefix(
            "Question paper · Class 10 · "
        ))
        let batch = UUID()
        let byBatch = Generation(
            id: UUID(), kind: .paper, createdAt: at,
            request: .paper(PaperForm(classID: batch, subject: "Mathematics", topic: "T")), result: result
        )
        #expect(byBatch.line(
            className: { $0 == batch ? "Class 10 Maths" : nil },
            today: today,
            calendar: DayHeading.india
        )
        .hasPrefix("Question paper · Class 10 Maths · "))
    }

    @Test func theResultsHeroNamesTheClassLevelAndTheTypedSubject() {
        let result = GenerationResult.paper(PaperResult(title: "T", sections: []))
        let byLevel = Generation(
            id: UUID(), kind: .paper, createdAt: .now,
            request: .paper(PaperForm(classLevel: .ten, subject: "Mathematics", topic: "T")), result: result
        )
        #expect(byLevel.className(batchName: { _ in nil }) == "Class 10")
        let batch = UUID()
        let byBatch = Generation(
            id: UUID(), kind: .paper, createdAt: .now,
            request: .paper(PaperForm(classID: batch, subject: "Maths", topic: "T")), result: result
        )
        #expect(byBatch.className(batchName: { $0 == batch ? "Class 10 Maths" : nil }) == "Class 10 Maths")
        #expect(byBatch.className(batchName: { _ in nil }) == "No class")
    }

    @Test func theTitleReadsBackAsItsLevel() {
        #expect(ClassLevel(title: "Class 10") == .ten)
        #expect(ClassLevel(title: "UKG") == .ukg)
        #expect(ClassLevel(title: "Class 10 Maths") == nil)
    }
}
