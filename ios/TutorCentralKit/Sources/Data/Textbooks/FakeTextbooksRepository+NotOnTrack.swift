import Domain
import Foundation

public extension FakeTextbooksRepository {
    /// Dev's Science for the not-on-track boards (P10-Student-NotOnTrack, P10-NextStep): counting atoms secure,
    /// balancing equations to revisit, then types of reactions taught; the Evening batch's others as `evening()`.
    static func notOnTrack() -> FakeTextbooksRepository {
        let repo = evening()
        let dev = FakeStudentsRepository.dev
        let chapter = Chapter(
            id: UUID(uuidString: "cccccccc-0004-0009-0000-000000000000")!, subject: "Science", position: 1,
            name: "Chemical reactions"
        )
        let at = { (day: Int) in
            DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: day, hour: 17)) ?? Date()
        }
        let names = ["Counting atoms in a formula", "Balancing equations", "Types of reactions"]
        let states: [(SkillState, Int)] = [(.secure, 1), (.revisit, 5), (.taught, 6)]
        repo.chaptersByStudent[dev] = [chapter]
        repo.skillsByStudent[dev] = zip(names, states).enumerated().map { index, row in
            Skill(
                id: UUID(uuidString: String(format: "cccccccc-0004-0009-%04d-000000000000", index + 1))!,
                chapterID: chapter.id, position: index + 1, name: row.0, state: row.1.0, stateAt: at(row.1.1),
                lastCheckedAt: nil
            )
        }
        return repo
    }
}
