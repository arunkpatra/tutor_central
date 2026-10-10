import Domain
import Foundation

/// The Evening batch's record (P10-Close, -Scrolled, -Placement): Dev and Meher in class 8 Science with Chemical
/// reactions under way, Riya's class 5 Mathematics kept and not started (her placement), Sahil on the ladder, Nikhil
/// with no book yet.
public extension FakeTextbooksRepository {
    nonisolated static let scienceEightChapters: [TextbookChapter] = [
        TextbookChapter(position: 1, name: "Chemical reactions", skills: [
            "Balancing equations", "Types of reactions", "Chemical change",
        ]),
        TextbookChapter(position: 2, name: "Metals and non-metals", skills: [
            "Physical properties of metals", "Reactions of metals with oxygen",
        ]),
    ]

    /// The seed with Riya's Mathematics and Dev's and Meher's Science, the register the Evening batch's.
    static func evening() -> FakeTextbooksRepository {
        let repo = seeded(riyasMaths: true)
        for (number, student) in [(4, FakeStudentsRepository.dev), (7, FakeStudentsRepository.meher)] {
            repo.chaptersByStudent[student] = scienceEightChapters.map { chapter in
                Chapter(
                    id: eveningID(number, chapter.position, 0), subject: "Science", position: chapter.position,
                    name: chapter.name
                )
            }
            repo.skillsByStudent[student] = scienceEightChapters.flatMap { chapter in
                chapter.skills.enumerated().map { index, name in
                    let seeded = chapter.position == 1 ? scienceStates(student)[index]
                        : EveningSkill(state: .notStarted, at: FakeCountsRepository.fixedNow, checked: nil)
                    return Skill(
                        id: eveningID(number, chapter.position, index + 1),
                        chapterID: eveningID(number, chapter.position, 0), position: index + 1, name: name,
                        state: seeded.state, stateAt: seeded.at, lastCheckedAt: seeded.checked
                    )
                }
            }
        }
        repo.students = FakeStudentsRepository.eveningSeed
        return repo
    }

    /// Dev: balancing to revisit (Mon 5 Oct), types of reactions taught today, chemical change practising since Wed 30
    /// Sep. Meher: types of reactions taught, the rest secure.
    private static func scienceStates(_ student: UUID) -> [EveningSkill] {
        let at = { (month: Int, day: Int) in
            DayHeading.india.date(from: DateComponents(year: 2026, month: month, day: day, hour: 17)) ?? Date()
        }
        if student == FakeStudentsRepository.dev {
            return [
                EveningSkill(state: .revisit, at: at(10, 5), checked: at(10, 5)),
                EveningSkill(state: .taught, at: at(10, 6), checked: nil),
                EveningSkill(state: .practising, at: at(9, 30), checked: at(9, 30)),
            ]
        }
        return [
            EveningSkill(state: .secure, at: at(9, 21), checked: at(9, 28)),
            EveningSkill(state: .taught, at: at(10, 6), checked: nil),
            EveningSkill(state: .secure, at: at(9, 23), checked: at(9, 30)),
        ]
    }

    private static func eveningID(_ student: Int, _ chapter: Int, _ skill: Int) -> UUID {
        UUID(uuidString: String(format: "cccccccc-%04d-%04d-%04d-000000000000", student, chapter, skill))!
    }
}

/// A seeded skill of the Evening batch: its state, when it moved, when it was last checked.
private struct EveningSkill {
    let state: SkillState
    let at: Date
    let checked: Date?
}
