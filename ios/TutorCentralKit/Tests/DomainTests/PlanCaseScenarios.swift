import Foundation
@testable import Domain

/// One case of the shared file before its draft is made.
struct Scenario {
    let name: String
    let input: InputJSON
    var named: NamedInput?
}

struct NamedInput {
    var topics: [String: TopicJSON]
    var briefChapters: [String]
}

/// What a scenario's input sets besides its students (the rest as the Evening batch on Wednesday 7 October).
struct ScenarioOptions {
    var books: [String: PlanCaseScenarios.Book] = [:]
    var sessions: [InputJSON.SessionJSON] = []
    var groupCount: Int?
    var subjects: [String: String] = [:]
    var patterns: [String: InputJSON.PatternJSON] = [:]
    var planGroups: Int?
    var hints: [InputJSON.HintJSON] = []
    var revisions: [String: InputJSON.RevisionJSON] = [:]
    var holidays: [String] = []
}

/// The scenarios of the shared case file, built with fixed ids so the file is the same each time it is written. They
/// follow PlanRulesTests, PlanRulesExamTests and PlanRulesGroupLinesTests, with the next steps, holidays, a school
/// item's
/// subject, the figure line, the 200-character cut and /ai/plan's naming added.
struct PlanCaseScenarios {
    typealias Book = (chapters: [InputJSON.ChapterJSON], skills: [InputJSON.SkillJSON])

    private var counter = 0
    let classID = "c0000000-0000-4000-8000-000000000001"

    mutating func next(_ prefix: String = "0") -> String {
        counter += 1
        return String(format: "%@0000000-0000-4000-8000-%012d", prefix, counter)
    }

    mutating func student(
        _ name: String, _ level: String?, status: String = "on_track", step: String? = nil, gender: String? = nil
    ) -> InputJSON.StudentJSON {
        .init(id: next("a"), name: name, classLevel: level, trackStatus: status, nextStep: step, gender: gender)
    }

    /// Chapters of two skills in a subject, the first `taught` chapters practising (taught on 6, 5, 4 Oct).
    mutating func book(_ subject: String, taught: Int, prefix: String = "Science", chapters count: Int = 3) -> Book {
        var chapters: [InputJSON.ChapterJSON] = []
        var skills: [InputJSON.SkillJSON] = []
        for position in 1 ... count {
            let chapter = InputJSON.ChapterJSON(
                id: next("b"), subject: subject, position: position, name: "Chapter \(position)"
            )
            chapters.append(chapter)
            for skill in 1 ... 2 {
                skills.append(InputJSON.SkillJSON(
                    id: next("d"), chapterID: chapter.id, position: skill, name: "\(prefix) \(position).\(skill)",
                    state: position <= taught ? "practising" : "not_started",
                    stateAt: String(format: "2026-10-%02dT11:30:00Z", 7 - position)
                ))
            }
        }
        return (chapters, skills)
    }

    func input(_ students: [InputJSON.StudentJSON], _ options: ScenarioOptions = .init()) -> InputJSON {
        InputJSON(
            classroom: .init(
                id: classID,
                subject: "Science",
                planGroups: options.planGroups,
                patterns: options.patterns
            ),
            date: "2026-10-07", students: students, chapters: options.books.mapValues(\.chapters),
            skills: options.books.mapValues(\.skills), sessions: options.sessions, hints: options.hints,
            groupCount: options.groupCount, subjects: options.subjects, revisions: options.revisions,
            holidays: options.holidays
        )
    }

    mutating func all() -> [Scenario] {
        groups() + steps() + lines() + subjects() + shapes() + exams()
    }
}

extension PlanCaseScenarios {
    mutating func groups() -> [Scenario] {
        let riya = student("Riya", "5"), sahil = student("Sahil", "2")
        let dev = student("Dev", "8"), meher = student("Meher", "8"), nikhil = student("Nikhil", "8")
        var books: [String: Book] = [:]
        for pupil in [dev, meher, nikhil] {
            books[pupil.id] = book("Science", taught: 2)
        }
        let four = [student("A", "8"), student("B", "7"), student("C", "3"), student("D", "2")]
        let ann = student("Ann", "8"), ben = student("Ben", "8", status: "not_on_track"), cai = student("Cai", "7")
        let levels = ["lkg", "ukg", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
        let twelve = (1 ... 12).map { student("S\(String(format: "%02d", $0))", levels[$0 % 12]) }
        let pattern = ["3": InputJSON.PatternJSON(groups: 2, subjects: ["English", "Mathematics"])]
        return [
            Scenario(
                name: "three levels make three groups, largest first",
                input: input([riya, sahil, dev, meher, nikhil], .init(books: books))
            ),
            Scenario(name: "a kept count of two cuts at the largest gap", input: input(four, .init(groupCount: 2))),
            Scenario(name: "a count of one keeps everyone together", input: input(four, .init(groupCount: 1))),
            Scenario(name: "the batch's kept count", input: input(four, .init(planGroups: 2))),
            Scenario(name: "the weekday's pattern", input: input(four, .init(patterns: pattern))),
            Scenario(
                name: "a student not on track sits one level down",
                input: input([ann, ben, cai], .init(groupCount: 2))
            ),
            Scenario(name: "every student is placed once", input: input(twelve)),
        ]
    }

    mutating func steps() -> [Scenario] {
        let dev = student("Dev", "8"), two = student("Dev", "8"), watch = student("Wes", "8", status: "watch")
        let ann = student("Ann", "8", status: "not_on_track")
        let ben = student("Ben", "8", status: "watch", step: "step_back")
        let cai = student("Cai", "8", status: "watch", step: "add_to_checks")
        let dia = student("Dia", "8", status: "not_on_track", step: "leave")
        let taught = [dev.id: 1, two.id: 2, watch.id: 1, ann.id: 2, ben.id: 2, cai.id: 2, dia.id: 2]
        let named = [
            ("a batch of one", dev),
            ("the teach line is the first skill not secure", two),
            ("watch teaches again with the worked example", watch),
            ("not on track tells the parent and teaches again", ann),
            ("a step back teaches the skill before first", ben),
            ("add it to the checks puts the skill first", cai),
            ("leave it teaches as usual", dia),
        ]
        var cases: [Scenario] = []
        for (name, pupil) in named {
            var own = book("Science", taught: taught[pupil.id] ?? 1)
            // The step back needs a skill before the current one: the first chapter is secure.
            if pupil.id == ben.id {
                own.skills = own.skills.map { skill in
                    var kept = skill
                    if own.chapters.first?.id == skill.chapterID {
                        kept.state = "secure"
                    }
                    return kept
                }
            }
            cases.append(Scenario(name: name, input: input([pupil], .init(books: [pupil.id: own]))))
        }
        return cases
    }

    mutating func lines() -> [Scenario] {
        let dev = student("Dev", "8"), meher = student("Meher", "8")
        let marks = [dev.id: "absent", meher.id: "present"]
        let sessions = [
            InputJSON.SessionJSON(classID: classID, date: "2026-10-05", marks: marks),
            InputJSON.SessionJSON(classID: classID, date: "2026-10-06", marks: marks),
            InputJSON.SessionJSON(classID: classID, date: "2026-10-07", marks: [dev.id: "present"]),
            InputJSON.SessionJSON(
                classID: "c0000000-0000-4000-8000-000000000099", date: "2026-10-06", marks: [meher.id: "absent"]
            ),
        ]
        let catchUp = [dev.id: book("Science", taught: 1), meher.id: book("Science", taught: 1)]
        let riya = student("Riya", "5", gender: "female"), raj = student("Raj", "5", gender: "male")
        let placement = [riya.id: book("Science", taught: 0), raj.id: book("Science", taught: 0)]
        let tall = student("Dev", "8"), short = student("Riya", "5")
        let fractions = book("Mathematics", taught: 0, prefix: "Adding fractions", chapters: 1)
        let figure = ScenarioOptions(
            books: [tall.id: book("Science", taught: 1), short.id: fractions], subjects: ["2": "Mathematics"]
        )
        let away = student("Dev", "8"), home = student("Meher", "8")
        let wordy = student("Dev", "8")
        var cut = book("Science", taught: 0, chapters: 1)
        cut.skills[0].name = String(repeating: "word ", count: 50) + "end"
        return [
            Scenario(
                name: "two absences running add a catch-up line",
                input: input([dev, meher], .init(books: catchUp, sessions: sessions))
            ),
            Scenario(
                name: "nothing taught yet makes a placement line with the pronoun",
                input: input([riya, raj], .init(books: placement))
            ),
            Scenario(
                name: "a brief above class seven; a figure for a fractions skill",
                input: input([tall, short], figure)
            ),
            Scenario(
                name: "a student on holiday is left out",
                input: input([away, home], .init(books: [away.id: book("Science", taught: 1)], holidays: [home.id]))
            ),
            Scenario(
                name: "a line past 200 characters is cut at a word",
                input: input([wordy], .init(books: [wordy.id: cut]))
            ),
        ]
    }

    mutating func subjects() -> [Scenario] {
        let dev = student("Dev", "8")
        var both = book("Science", taught: 2)
        let maths = InputJSON.ChapterJSON(id: next("b"), subject: "Mathematics", position: 1, name: "Numbers")
        both.chapters.append(maths)
        both.skills.append(.init(
            id: next("d"), chapterID: maths.id, position: 1, name: "Maths 1.1", state: "practising",
            stateAt: "2026-09-20T11:30:00Z"
        ))
        let ved = student("Ved", "8")
        var fresh = book("Science", taught: 1)
        let english = InputJSON.ChapterJSON(id: next("b"), subject: "English", position: 1, name: "Poems")
        fresh.chapters.append(english)
        fresh.skills.append(.init(
            id: next("d"), chapterID: english.id, position: 1, name: "English 1.1", state: "not_started",
            stateAt: "2026-10-07T11:05:00Z"
        ))
        let soon = [InputJSON.HintJSON(studentID: dev.id, subject: "Science", date: "2026-10-12")]
        let kept = ["3": InputJSON.PatternJSON(groups: 1, subjects: ["Science"])]
        return [
            Scenario(name: "the subject least recently taught", input: input([dev], .init(books: [dev.id: both]))),
            Scenario(
                name: "the weekday's pattern names the subject",
                input: input([dev], .init(books: [dev.id: both], patterns: kept))
            ),
            Scenario(
                name: "today's choice names the subject",
                input: input([dev], .init(books: [dev.id: both], subjects: ["1": "Science"]))
            ),
            Scenario(
                name: "a school item within 14 days names the subject",
                input: input([dev], .init(books: [dev.id: both], hints: soon))
            ),
            Scenario(name: "a subject never taught comes first", input: input([ved], .init(books: [ved.id: fresh]))),
        ]
    }

    mutating func shapes() -> [Scenario] {
        let ann = student("Ann", "8"), ben = student("Ben", "8"), cai = student("Cai", "8")
        let common: [String: Book] = [
            ann.id: book("Science", taught: 1), ben.id: book("Science", taught: 1),
            cai.id: book("Mathematics", taught: 1, prefix: "Maths", chapters: 1),
        ]
        let old = student("Ola", "8"), young = student("Yan", "5")
        let topics = [
            "1": TopicJSON(chapter: "Crop production", skill: "Adding fractions"),
            "2": TopicJSON(chapter: "Plants", skill: "Parts of a plant"),
        ]
        let dev = student("Dev", "8"), bir = student("Bir", nil)
        return [
            Scenario(
                name: "the group's subject is the most common and every line follows it",
                input: input([ann, ben, cai], .init(books: common))
            ),
            Scenario(
                name: "a batch with no record is planned by class, then named", input: input([old, young]),
                named: NamedInput(topics: topics, briefChapters: ["Plants"])
            ),
            Scenario(
                name: "a student with no class follows the group",
                input: input([dev, bir], .init(books: [dev.id: book("Science", taught: 1)]))
            ),
        ]
    }
}
