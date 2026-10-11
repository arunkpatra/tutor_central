import Data
import Domain
import Foundation
import Testing
@testable import Make

/// The AI forms by class level, no batch (P12-Form-Paper-Class, -NoClass): where a new form starts, and what it keeps.
@MainActor struct AIFormClassTests {
    func student(_ level: ClassLevel?) -> Student {
        var student = FakeStudentsRepository.seed[0]
        student.classLevel = level
        return student
    }

    @Test func theFormStartsOnTheLastChosenClassElseTheMostCommon() {
        let students = [student(.ten), student(.eight), student(.ten), student(nil)]
        #expect(AIStore.startingLevel(students: students, remembered: .five) == .five)
        #expect(AIStore.startingLevel(students: students, remembered: nil) == .ten)
        #expect(AIStore.startingLevel(students: [student(nil)], remembered: nil) == nil)
        #expect(AIStore.startingLevel(students: [], remembered: nil) == nil)
        // A tie goes to the higher class.
        #expect(AIStore.startingLevel(students: [student(.eight), student(.ten)], remembered: nil) == .ten)
    }

    @Test func aNewPaperNeedsNoBatch() async {
        let store = await AIStoreTests.make()
        guard case let .paper(form) = store.form(for: .paper) else {
            Issue.record("not a paper")
            return
        }
        #expect(form.classID == nil)
        let levels = store.register.activeStudents.compactMap(\.classLevel)
        #expect(form.classLevel == AIStore.startingLevel(students: store.register.activeStudents, remembered: nil))
        #expect(levels.isEmpty || form.classLevel != nil)
    }

    @Test func theLastClassAndSubjectAreKeptForTheNextForm() async throws {
        let suite = "ai-form-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = await AIStoreTests.make()
        first.formDefaults = defaults
        _ = first.create(.homework(HomeworkForm(classLevel: .three, subject: "English", topic: "Nouns")))
        let next = await AIStoreTests.make()
        next.formDefaults = defaults
        guard case let .homework(form) = next.form(for: .homework) else {
            Issue.record("not homework")
            return
        }
        #expect(form.subject == "English")
        #expect(AIStore.remembered(kind: .homework, in: defaults)?.classLevel == .three)
        #expect(Wipe.defaultsKeys.contains(AIStore.defaultsKey(.homework)))
    }
}
