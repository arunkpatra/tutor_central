import Foundation
@testable import Domain

/// The exam scenarios: exam groups first, at most two while others remain; a student whose exam has no group keeps the
/// group's material with their own revision words.
extension PlanCaseScenarios {
    struct Exam {
        let item: String
        let title: String
        let subject: String
        let date: String
    }

    func revision(
        _ exam: Exam,
        kind: String,
        title: String,
        index: Int? = nil,
        gap: String? = nil,
        set: Int = 1,
        skill: String
    )
        -> InputJSON.RevisionJSON {
        InputJSON.RevisionJSON(
            itemID: exam.item, title: exam.title, subject: exam.subject, examDate: exam.date,
            day: RevisionDayJSON(
                day: "2026-10-07", kind: kind, index: index, title: title, skillIDs: kind == "revise" ? [skill] : []
            ),
            gapLine: gap, pattern: kind == "mock" ? .init(marks: 40, durationMinutes: 60) : nil, setNumber: set
        )
    }

    mutating func exams() -> [Scenario] {
        let riya = student("Riya", "8"), meher = student("Meher", "8"), nikhil = student("Nikhil", "8")
        let sahil = student("Sahil", "8"), dev = student("Dev", "8")
        let skill = next("d")
        let maths = Exam(
            item: "e0000000-0000-4000-8000-000000000012",
            title: "Maths test",
            subject: "Mathematics",
            date: "2026-10-12"
        )
        let unit = Exam(
            item: "e0000000-0000-4000-8000-000000000013",
            title: "Maths unit test",
            subject: "Mathematics",
            date: "2026-10-13"
        )
        let english = Exam(
            item: "e0000000-0000-4000-8000-000000000015",
            title: "English test",
            subject: "English",
            date: "2026-10-15"
        )
        let later = Exam(
            item: "e0000000-0000-4000-8000-000000000019",
            title: "English unit test",
            subject: "English",
            date: "2026-10-19"
        )
        let revisions = [
            riya.id: revision(maths, kind: "revise", title: "Fractions · first half", index: 2, set: 2, skill: skill),
            meher.id: revision(unit, kind: "mock", title: "The mock", skill: skill),
            nikhil.id: revision(
                english,
                kind: "afterMock",
                title: "What the mock showed",
                gap: "Revise tenses with two short passages",
                set: 4,
                skill: skill
            ),
            sahil.id: revision(later, kind: "revise", title: "Poems", index: 1, skill: skill),
        ]
        let books = [dev.id: book("Science", taught: 1), sahil.id: book("Science", taught: 1)]
        let mixed = input([riya, meher, nikhil, sahil, dev], .init(books: books, revisions: revisions))
        let only = input([riya, meher], .init(revisions: revisions.filter { [riya.id, meher.id].contains($0.key) }))
        return [
            Scenario(
                name: "exam groups come first, two while others remain; a later exam keeps the group's material",
                input: mixed
            ),
            Scenario(name: "when every member revises, the exams make every group", input: only),
        ]
    }
}
