import Foundation
@testable import Domain

/// The budget's scenarios (plan/phase-18-plan.md Task 7): the batch on Wednesday 7 October as the plan cases have it,
/// with fixed ids. They follow ArtefactBudgetTests and ArtefactBudgetExamTests and add the cut, the caps, the spaced
/// pair's clock and each exam day.
struct BudgetCaseScenarios {
    struct Scenario {
        let name: String
        let input: BudgetCase.Input
    }

    var plan = PlanCaseScenarios()
    static let now = "2026-10-07T00:00:00Z"

    func make(
        _ name: String, _ input: InputJSON, briefs: [String] = [], mocks: [String] = [], now: String = Self.now
    ) -> Scenario {
        Scenario(name: name, input: .init(plan: input, now: now, briefsMade: briefs, mocksMade: mocks))
    }

    mutating func all() -> [Scenario] {
        groups() + shapes() + personal() + spaced() + exams() + examDays()
    }

    mutating func groups() -> [Scenario] {
        let dev = plan.student("Dev", "8"), meher = plan.student("Meher", "8"), nikhil = plan.student("Nikhil", "8")
        var trio: [String: PlanCaseScenarios.Book] = [:]
        for pupil in [dev, meher, nikhil] {
            trio[pupil.id] = plan.book("Science", taught: 2)
        }
        let riya = plan.student("Riya", "5"), sahil = plan.student("Sahil", "4")
        var two = trio
        two[riya.id] = plan.book("Science", taught: 1)
        two[sahil.id] = plan.book("Science", taught: 1)
        let light = [riya.id: plan.book("Science", taught: 1), sahil.id: plan.book("Science", taught: 1)]
        let asha = plan.student("Asha", "5")
        let fractions = [asha.id: plan.book("Mathematics", taught: 1, prefix: "Fraction parts")]
        let tara = plan.student("Tara", "3")
        let triangles = [tara.id: plan.book("Mathematics", taught: 1, prefix: "Triangle")]
        return [
            make(
                "a group of three at class 8: checks, set, sheet, worked example, brief",
                plan.input([dev, meher, nikhil], .init(books: trio))
            ),
            make(
                "two groups each get their material, the older first",
                plan.input([dev, meher, nikhil, riya, sahil], .init(books: two))
            ),
            make("class 5 and below take the light homework", plan.input([riya, sahil], .init(books: light))),
            make("a fractions skill gets its figure", plan.input([asha], .init(books: fractions))),
            make(
                "a triangle at class 3: the figure and the light homework",
                plan.input([tara], .init(books: triangles))
            ),
        ]
    }

    mutating func shapes() -> [Scenario] {
        let seven = plan.student("Sana", "7")
        let sevenBook = [seven.id: plan.book("Science", taught: 1)]
        let old = plan.student("Ola", "8"), young = plan.student("Yan", "5")
        let ten = plan.student("Tia", "10"), eight = plan.student("Eli", "8"), six = plan.student("Sid", "6")
        let many = [
            ten.id: plan.book("Mathematics", taught: 1, prefix: "Triangle"),
            eight.id: plan.book("Mathematics", taught: 1, prefix: "Number line"),
            six.id: plan.book("Science", taught: 1, prefix: "Food chain"),
        ]
        let fresh = (1 ... 4).map { plan.student("New \($0)", "8") }
        var crowd = many
        for pupil in fresh {
            crowd[pupil.id] = plan.book("Science", taught: 0)
        }
        let bir = plan.student("Bir", nil), lone = plan.student("Lea", "8")
        return [
            make("class 7 gets no brief unless one was asked for", plan.input([seven], .init(books: sevenBook))),
            make(
                "class 7 gets the brief asked for before", plan.input([seven], .init(books: sevenBook)),
                briefs: ["Chapter 1", "Chapter 2"]
            ),
            make("a batch with no record asks for nothing until its groups are named", plan.input([old, young])),
            make(
                "three groups with figures and briefs are cut at twenty calls",
                plan.input([ten, eight, six] + fresh, .init(books: crowd, groupCount: 3)), briefs: ["Chapter 1"]
            ),
            make(
                "a student with no class follows the group's level",
                plan.input(
                    [bir, lone],
                    .init(books: [bir.id: plan.book("Science", taught: 1), lone.id: plan.book("Science", taught: 1)])
                )
            ),
        ]
    }

    mutating func personal() -> [Scenario] {
        let dev = plan.student("Dev", "8")
        let fresh = ["Ari", "Bea", "Cy", "Di", "Ed"].map { plan.student($0, "8") }
        var books = [dev.id: plan.book("Science", taught: 2)]
        for pupil in fresh {
            books[pupil.id] = plan.book("Science", taught: 0)
        }
        let wes = plan.student("Wes", "8", status: "watch"), ann = plan.student("Ann", "8", status: "not_on_track")
        let cai = plan.student("Cai", "8", status: "watch", step: "add_to_checks")
        let steps = [
            wes.id: plan.book("Science", taught: 2), ann.id: plan.book("Science", taught: 3), cai.id: plan.book(
                "Science",
                taught: 2
            ),
        ]
        let away = plan.student("Ali", "8"), back = plan.student("Bo", "8")
        let marks = [away.id: "absent", back.id: "present"]
        let sessions = [
            InputJSON.SessionJSON(classID: plan.classID, date: "2026-10-05", marks: marks),
            InputJSON.SessionJSON(classID: plan.classID, date: "2026-10-06", marks: marks),
        ]
        let catchUp = [away.id: plan.book("Science", taught: 2), back.id: plan.book("Science", taught: 2)]
        return [
            make("five placements are cut to four, by name", plan.input([dev] + fresh, .init(books: books))),
            make(
                "teach again and not on track check their own skills",
                plan.input([wes, ann, cai], .init(books: steps))
            ),
            make(
                "a catch-up checks the student's own skills",
                plan.input([away, back], .init(books: catchUp, sessions: sessions))
            ),
        ]
    }

    mutating func spaced() -> [Scenario] {
        let dev = plan.student("Dev", "8"), meher = plan.student("Meher", "8")
        var older = plan.book("Science", taught: 3)
        older.skills[0].lastCheckedAt = "2026-09-20T11:30:00Z"
        older.skills[3].lastCheckedAt = "2026-10-06T11:30:00Z"
        var other = plan.book("Science", taught: 3)
        other.skills[1].lastCheckedAt = "2026-09-25T11:30:00Z"
        let solo = plan.student("Sam", "8")
        return [
            make(
                "the spaced pair is the two most overdue other skills across the members",
                plan.input([dev, meher], .init(books: [dev.id: older, meher.id: other]))
            ),
            make(
                "a later clock changes nothing but the order of the overdue",
                plan.input([dev, meher], .init(books: [dev.id: older, meher.id: other])), now: "2026-10-20T00:00:00Z"
            ),
            make(
                "one skill taught: the day's skill fills the checks",
                plan.input([solo], .init(books: [solo.id: plan.book("Science", taught: 1, chapters: 1)]))
            ),
        ]
    }
}
