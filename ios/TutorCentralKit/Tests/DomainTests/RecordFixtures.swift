import Foundation
@testable import Domain

/// A Mathematics chapter at a position, and a skill in it, for the record's rules.
func chapter(_ position: Int, subject: String = "Mathematics") -> Chapter {
    Chapter(id: UUID(), subject: subject, position: position, name: "Chapter \(position)")
}

func skill(
    _ chapter: Chapter, _ position: Int, state: SkillState = .notStarted, stateAt: Date = FakeClock.oct7at1635,
    checked: Date? = nil, name: String? = nil
) -> Skill {
    Skill(
        id: UUID(),
        chapterID: chapter.id,
        position: position,
        name: name ?? "Skill \(chapter.position).\(position)",
        state: state,
        stateAt: stateAt,
        lastCheckedAt: checked
    )
}
