import Foundation
@testable import Domain

/// The exam groups' material and the exam split's scenarios.
extension BudgetCaseScenarios {
    private func exam(_ item: String, _ title: String, date: String = "2026-10-12") -> PlanCaseScenarios.Exam {
        .init(item: item, title: title, subject: "Science", date: date)
    }

    private func line(
        _ exam: PlanCaseScenarios.Exam, _ kind: String, title: String, index: Int? = nil, skills: [String] = [],
        skillIDs: [String] = [], gap: [String] = [], portions: [String] = ["Chemical reactions", "Acids"], set: Int = 1
    ) -> InputJSON.RevisionJSON {
        var line = plan.revision(exam, kind: kind, title: title, index: index, set: set, skill: skillIDs.first ?? "")
        line.day.skillIDs = skillIDs
        line.skills = skills
        line.portions = portions
        line.gapSkills = gap
        if kind != "mock" {
            line.pattern = nil
        }
        return line
    }

    /// Three class 8 members revising for one exam.
    private struct Batch {
        let unit: PlanCaseScenarios.Exam
        let members: [InputJSON.StudentJSON]

        func all(_ line: InputJSON.RevisionJSON) -> [String: InputJSON.RevisionJSON] {
            Dictionary(uniqueKeysWithValues: members.map { ($0.id, line) })
        }
    }

    private mutating func batch() -> Batch {
        let unit = exam("e0000000-0000-4000-8000-000000000101", "Science unit test")
        return Batch(unit: unit, members: ["Dev", "Meher", "Nikhil"].map { plan.student($0, "8") })
    }

    mutating func exams() -> [Scenario] {
        let batch = batch()
        let (unit, members) = (batch.unit, batch.members)
        let ids = [plan.next("d"), plan.next("d"), plan.next("d"), plan.next("d")]
        let skills = ["Balancing equations", "Types of reactions"]
        let revise = line(
            unit,
            "revise",
            title: "Chemical reactions",
            index: 1,
            skills: skills,
            skillIDs: Array(ids.prefix(2))
        )
        let wide = line(
            unit, "revise", title: "Chemical reactions · Acids", index: 2,
            skills: skills + ["Naming acids", "Indicators"], skillIDs: ids, set: 2
        )
        let bare = line(unit, "revise", title: "Light", index: 3, portions: ["Light"], set: 3)
        let sam = plan.student("Sam", "8"), riya = plan.student("Riya", "5")
        let mixed = [sam.id: plan.book("Science", taught: 1), riya.id: plan.book("Science", taught: 1)]
        var both = batch.all(revise)
        both.removeValue(forKey: members[2].id)
        return [
            make(
                "an exam group on a revision day: checks on its skills, the set and the sheet",
                plan.input(members, .init(revisions: batch.all(revise)))
            ),
            make(
                "more than three revision skills: the checks take three",
                plan.input(members, .init(revisions: batch.all(wide)))
            ),
            make(
                "a revision day that names no skill takes its title",
                plan.input(members, .init(revisions: batch.all(bare)))
            ),
            make(
                "an exam group beside a level group, each with its own material",
                plan.input(members + [sam, riya], .init(books: mixed, revisions: batch.all(revise)))
            ),
            make(
                "a member on holiday is left out of the exam group",
                plan.input(members, .init(revisions: both, holidays: [members[2].id]))
            ),
        ]
    }

    mutating func examDays() -> [Scenario] {
        let batch = batch()
        let (unit, members) = (batch.unit, batch.members)
        let mock = line(unit, "mock", title: "The mock")
        var gaps = batch.all(line(unit, "afterMock", title: "What the mock showed", set: 4))
        gaps[members[0].id]?.gapSkills = ["Naming acids", "Indicators"]
        gaps[members[1].id]?.gapSkills = [
            "Indicators",
            "Balancing equations",
            "Neutralisation",
            "Salts",
            "pH",
            "Litmus",
        ]
        let after = line(unit, "afterMock", title: "What the mock showed", set: 4)
        let testDay = line(unit, "exam", title: "The test")
        return [
            make("the mock day: checks and the mock, no sheet", plan.input(members, .init(revisions: batch.all(mock)))),
            make(
                "the mock day with the mock made: checks only", plan.input(members, .init(revisions: batch.all(mock))),
                mocks: [unit.item]
            ),
            make(
                "after the mock: the members' weakest skills, six at most",
                plan.input(members, .init(revisions: gaps))
            ),
            make(
                "after the mock with no marking: the portions",
                plan.input(members, .init(revisions: batch.all(after)))
            ),
            make(
                "the test day's line: checks and sets from the portions",
                plan.input(members, .init(revisions: batch.all(testDay)))
            ),
        ]
    }
}

/// The exam split's scenarios: Monday 2 November, the exam on Thursday 12 November unless a case says otherwise.
struct SplitCaseScenarios {
    var counter = 0
    let school = "f0000000-0000-4000-8000-000000000001"

    mutating func next(_ prefix: String) -> String {
        counter += 1
        return String(format: "%@0000000-0000-4000-8000-%012d", prefix, counter)
    }

    mutating func book(_ names: [String], skills: Int = 2) -> ([InputJSON.ChapterJSON], [InputJSON.SkillJSON]) {
        var chapters: [InputJSON.ChapterJSON] = []
        var all: [InputJSON.SkillJSON] = []
        for (index, name) in names.enumerated() {
            let chapter = InputJSON.ChapterJSON(id: next("b"), subject: "Science", position: index + 1, name: name)
            chapters.append(chapter)
            for skill in 1 ... skills {
                all.append(.init(
                    id: next("d"), chapterID: chapter.id, position: skill, name: "\(name) \(skill)",
                    state: "practising", stateAt: "2026-10-20T11:30:00Z"
                ))
            }
        }
        return (chapters, all)
    }

    mutating func exam(
        _ title: String, date: String = "2026-11-12", portions: String? = nil, window: Int? = nil,
        received: String = "2026-10-20T10:00:00+05:30", audience: SplitCase.Audience? = nil
    ) -> SplitCase.ItemJSON {
        .init(
            id: next("e"), kind: "exam", audience: audience ?? .init(school: school, classLevel: "8"), title: title,
            subject: "Science", date: date, portions: portions, receivedAt: received, windowDays: window
        )
    }

    mutating func holiday(_ from: String, to: String? = nil) -> SplitCase.ItemJSON {
        .init(
            id: next("9"), kind: "holiday", audience: .init(school: school), title: "Holiday", date: from, endDate: to,
            receivedAt: "2026-10-20T10:00:00+05:30"
        )
    }

    func input(
        _ items: [SplitCase.ItemJSON], days: [Int] = [1, 3, 5], today: String = "2026-11-02",
        book: ([InputJSON.ChapterJSON], [InputJSON.SkillJSON]) = ([], [])
    ) -> SplitCase.Input {
        .init(
            items: items,
            student: .init(id: "a0000000-0000-4000-8000-000000000001", name: "Dev", classLevel: "8", schoolID: school),
            chapters: book.0, skills: book.1, meetingDays: days, today: today
        )
    }

    mutating func all() -> [(name: String, input: SplitCase.Input)] {
        spread() + reach()
    }

    mutating func spread() -> [(name: String, input: SplitCase.Input)] {
        let chemistry = book(["Chemical reactions", "Acids, bases and salts", "Metals"])
        let numbered = book(["Light", "Electricity", "Magnets"])
        let three = [exam("Unit test", portions: "Ch 1 Chemical reactions Ch 2 Acids, bases and salts · Metals")]
        let nine = [exam("Unit test", portions: "Chemical reactions; Acids, bases and salts")]
        let short = [exam("Unit test", date: "2026-11-09", portions: "Chemical reactions")]
        let pair = [exam("Unit test", date: "2026-11-06", portions: "Chemical reactions · Metals")]
        let all = "Chemical reactions · Acids, bases and salts · Metals"
        let crowded = [exam("Unit test", date: "2026-11-04", portions: all)]
        let ranged = [exam("Physics test", portions: "Chapters 1 to 2 · Ch 3")]
        let loose = [exam("Unit test", portions: "Revision worksheet")]
        let came = [exam("Unit test", portions: "Metals · Chemical reactions", received: "2026-10-30T10:00:00+05:30")]
        let away = [exam("Unit test", portions: "Metals"), holiday("2026-11-04", to: "2026-11-06")]
        return [
            ("three parts over five meeting days, the mock and the day after", input(three, book: chemistry)),
            (
                "every day a meeting day: nine days, the mock two days before",
                input(nine, days: [1, 2, 3, 4, 5, 6, 7], book: chemistry)
            ),
            ("the mock on the last meeting day two before the exam, none after", input(short, book: chemistry)),
            ("two meeting days a week", input(pair, days: [1, 3], book: chemistry)),
            ("fewer days than parts: a day takes several", input(crowded, days: [1], book: chemistry)),
            ("chapters by number and a range", input(ranged, days: [1, 2, 3, 4, 5], book: numbered)),
            ("a part that names no chapter is its own skill", input(loose, book: chemistry)),
            ("no portions: the title is the part", input([exam("Unit test")])),
            ("the split starts the day the item came, not today", input(came, today: "2026-11-04", book: chemistry)),
            ("a holiday takes its meeting days out", input(away, book: chemistry)),
        ]
    }

    mutating func reach() -> [(name: String, input: SplitCase.Input)] {
        let chemistry = book(["Chemical reactions", "Acids, bases and salts", "Metals"])
        let early = exam("Unit test", date: "2026-11-09"), later = exam("Science test", date: "2026-11-11")
        let tieA = exam("B test", date: "2026-11-10"), tieB = exam("A test", date: "2026-11-10")
        let far = [exam("Unit test", portions: "Metals", window: 7)]
        let other = [exam("Unit test", audience: .init(school: school, classLevel: "9"))]
        let dev = SplitCase.Audience(student: "a0000000-0000-4000-8000-000000000001")
        let own = [exam("Unit test", portions: "Metals", audience: dev)]
        let away = [exam("Unit test"), holiday("2026-11-02")]
        return [
            ("a shorter window: an exam too far is not yet the student's", input(far, book: chemistry)),
            ("a student on holiday today has no exam day", input(away)),
            ("the nearest exam drives the revision", input([later, early], days: [1, 2, 3, 4, 5])),
            ("two exams on one day: by title", input([tieA, tieB], days: [1, 2, 3, 4, 5])),
            ("another class's exam does not reach the student", input(other)),
            ("the student's own exam reaches them", input(own, book: chemistry)),
            ("the test day: the split from the day the item came", input([exam("Unit test", date: "2026-11-02")])),
        ]
    }
}
