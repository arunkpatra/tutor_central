import Domain
import Foundation

/// The 10.3 boards' plan (P10-Today-Plan and its states): the Evening batch on Wednesday 7 October in three groups,
/// Group 1 · Chemical reactions for Dev, Meher and Nikhil, Group 2 · Parts and wholes for Riya, Group 3 · Reading for
/// Sahil, the material made (the figures are illustrative). The launch states and the tests share it.
public extension FakePlansRepository {
    /// The boards' plan with its material; `changed` moves Riya to Group 1 and skips Nikhil's homework, `done` ticks
    /// the
    /// students' lines at 18:32.
    static func evening(changed: Bool = false, done: Bool = false) -> FakePlansRepository {
        FakePlansRepository(plans: [boardPlan(changed: changed, done: done)], artefacts: boardArtefacts, now: madeAt)
    }

    /// The boards' plan with the tutor's own sheet (a photo) in place of Group 1's homework sheet (P10-Sheet-Own).
    static func evening(ownSheet: UUID, photoPath: String) -> FakePlansRepository {
        let made = artefactID(12)
        let own = Artefact(
            id: ownSheet, kind: .sheet, source: .own, title: "Your sheet · balancing equations",
            content: .own(OwnContent(text: nil, inPlaceOf: "sheet 1")), photoPath: photoPath, studentID: nil,
            planID: planID, regeneratedFrom: made, madeAt: india(7, 16, minute: 52)
        )
        var plan = boardPlan(changed: false, done: false)
        for index in plan.items.indices where plan.items[index].artefactID == made {
            plan.items[index].artefactID = ownSheet
        }
        return FakePlansRepository(plans: [plan], artefacts: boardArtefacts + [own], now: madeAt)
    }

    nonisolated static let planID = UUID(uuidString: "abababab-0000-0000-0000-000000000001")!
    private nonisolated static let madeAt = india(7, 16, minute: 40)
    private nonisolated static func artefactID(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "abababab-0000-0000-0001-%012d", number))!
    }

    /// The material: per group the set, the sheet, the checks and the worked example; the brief for Chemical
    /// reactions; Dev's and Nikhil's own checks; Riya's placement.
    nonisolated static let boardArtefacts: [Artefact] = {
        func made(
            _ number: Int,
            _ kind: ArtefactKind,
            _ title: String,
            _ content: ArtefactContent,
            for student: UUID? = nil
        )
            -> Artefact {
            Artefact(
                id: artefactID(number), kind: kind, source: .made, title: title, content: content, photoPath: nil,
                studentID: student, planID: planID, regeneratedFrom: nil, madeAt: madeAt
            )
        }
        let sheet = { (homework: Bool, light: Bool) in
            ArtefactContent.sheet(AISamples.sheet(questions: 8, forHomework: homework, light: light))
        }
        let checks = { (skills: [String]) in
            ArtefactContent.check(CheckContent(questions: AISamples.checks(for: skills).map {
                CheckContent.Question(skillID: UUID(), skill: $0.skill, question: $0.question, answer: $0.answer)
            }, placement: false))
        }
        let example = ArtefactContent.workedExample(AISamples.workedExample)
        var all: [Artefact] = []
        for (group, skill) in [(1, "Balancing equations"), (2, "Equivalent fractions"), (3, "Short sentences")] {
            let base = group * 10
            all += [
                made(base + 1, .sheet, "\(skill) · set 1", sheet(false, false)),
                made(base + 2, .sheet, "\(skill) · sheet 1", sheet(true, group > 1)),
                made(base + 3, .check, "Checks · \(skill)", checks([
                    "Balancing equations",
                    "Types of reactions",
                    "Chemical change",
                ])),
                made(base + 4, .workedExample, skill, example),
            ]
        }
        all.append(made(5, .brief, "Your brief · Chemical reactions", .brief(AISamples.brief)))
        let three = ["Balancing equations", "Types of reactions", "Chemical change"]
        all.append(made(6, .check, "Checks · Balancing equations", checks(three), for: FakeStudentsRepository.dev))
        all.append(made(7, .check, "Checks · Balancing equations", checks(three), for: FakeStudentsRepository.nikhil))
        all.append(made(8, .placement, "Placement", riyasPlacement, for: FakeStudentsRepository.riya))
        return all
    }()

    /// Riya's placement: a question on the first skill of each of her book's chapters, as the plan makes it.
    private nonisolated static var riyasPlacement: ArtefactContent {
        let groups = Placement.groups(
            chapters: FakeTextbooksRepository.riyaChapters, skills: FakeTextbooksRepository.riyaSkills
        )
        let questions = groups.flatMap { group in
            zip(group.items, AISamples.placement(for: group.items.map(\.name))).map { item, made in
                CheckContent.Question(
                    skillID: item.skillID,
                    skill: item.skill,
                    question: made.question,
                    answer: made.answer
                )
            }
        }
        return .check(CheckContent(questions: questions, placement: true))
    }

    /// One student's lines on the boards: the teach, check and homework words, their own checks.
    private struct BoardLine {
        let student: UUID
        let group: Int
        let teach: String
        let check: String
        let homework: String
        let own: Int?
    }

    private nonisolated static let boardLines = [
        BoardLine(
            student: FakeStudentsRepository.dev, group: 1,
            teach: "Teach again: Balancing equations, with the worked example", check: "Check 3",
            homework: "Homework sheet 1", own: 6
        ),
        BoardLine(
            student: FakeStudentsRepository.meher, group: 1, teach: "Teach: Types of reactions", check: "Check 3",
            homework: "Homework sheet 1", own: nil
        ),
        BoardLine(
            student: FakeStudentsRepository.nikhil, group: 1, teach: "Teach: Balancing equations", check: "Check 3",
            homework: "Homework sheet 1", own: 7
        ),
        BoardLine(
            student: FakeStudentsRepository.riya, group: 2, teach: "Teach: Equivalent fractions",
            check: "Placement, her first checks", homework: "Homework sheet 1, light", own: 8
        ),
        BoardLine(
            student: FakeStudentsRepository.sahil, group: 3, teach: "Teach: Short sentences", check: "Check 3",
            homework: "Homework sheet 1, light", own: nil
        ),
    ]

    private nonisolated static let boardGroups = [
        PlanGroup(
            number: 1, subject: "Science", chapter: "Chemical reactions", skill: "Balancing equations",
            classLevels: [.eight],
            memberIDs: [FakeStudentsRepository.dev, FakeStudentsRepository.meher, FakeStudentsRepository.nikhil],
            skillID: nil
        ),
        PlanGroup(
            number: 2, subject: "Mathematics", chapter: "Parts and wholes", skill: "Equivalent fractions",
            classLevels: [.five], memberIDs: [FakeStudentsRepository.riya], skillID: nil
        ),
        PlanGroup(
            number: 3, subject: "Reading", chapter: "Reading", skill: "Short sentences", classLevels: [.two],
            memberIDs: [FakeStudentsRepository.sahil], skillID: nil
        ),
    ]

    /// The plan's record: each student's lines as the boards word them, linked to the material.
    nonisolated static func boardPlan(changed: Bool, done: Bool) -> PlanRecord {
        var items = boardItems(done: done)
        if changed {
            // P10-Today-Plan-Changed: Riya moved here from Group 2; Nikhil's homework skipped today.
            for index in items.indices where items[index].studentID == FakeStudentsRepository.riya {
                items[index].groupNo = 1
                items[index].movedFrom = 2
            }
            if let homework = items.firstIndex(where: {
                $0.studentID == FakeStudentsRepository.nikhil && $0.kind == .homework
            }) {
                items[homework].skippedAt = india(7, 16, minute: 30)
            }
        }
        return PlanRecord(
            id: planID, classID: FakeClassesRepository.evening.id, date: Day(year: 2026, month: 10, day: 7)!,
            madeAt: madeAt, groups: boardGroups, items: items, artefacts: [], sessionID: nil
        )
    }

    private nonisolated static func boardItems(done: Bool) -> [PlanItem] {
        var items: [PlanItem] = []
        func add(_ student: UUID?, _ group: Int, _ kind: PlanLineKind, _ words: String, _ artefact: Int?) {
            items.append(PlanItem(
                id: UUID(uuidString: String(format: "abababab-0000-0000-0002-%012d", items.count + 1))!,
                studentID: student, groupNo: group, kind: kind, skillID: nil, words: words,
                artefactID: artefact.map(artefactID),
                doneAt: done && student != nil ? india(7, 18, minute: 32) : nil, skippedAt: nil,
                movedFrom: nil
            ))
        }
        for line in boardLines {
            if line.student == FakeStudentsRepository.nikhil {
                add(line.student, line.group, .catchUp, "Catch up: missed Mon and Fri · then Balancing equations", nil)
            }
            add(line.student, line.group, .teach, line.teach, nil)
            add(line.student, line.group, .practise, "Practise set 1", line.group * 10 + 1)
            add(line.student, line.group, .check, line.check, line.own ?? line.group * 10 + 3)
            add(line.student, line.group, .homework, line.homework, line.group * 10 + 2)
        }
        for group in boardGroups {
            add(nil, group.number, .workedExample, "Worked example · \(group.skill)", group.number * 10 + 4)
        }
        add(nil, 1, .brief, "Your brief · Chemical reactions", 5)
        return items
    }

    private nonisolated static func india(_ day: Int, _ hour: Int, minute: Int) -> Date {
        DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }
}
