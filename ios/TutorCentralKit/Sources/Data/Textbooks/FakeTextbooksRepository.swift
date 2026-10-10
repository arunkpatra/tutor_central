import Domain
import Foundation

/// The in-memory textbooks and per-student chapters for tests and previews, with a scripted error.
@MainActor public final class FakeTextbooksRepository: TextbooksRepository {
    public private(set) var textbooks: [Textbook] = []
    public private(set) var chaptersByStudent: [UUID: [Chapter]] = [:]
    public private(set) var skillsByStudent: [UUID: [Skill]] = [:]
    /// Which book each copied chapter came from, as `chapters.textbook_id` keeps it.
    private var source: [UUID: UUID] = [:]
    public var nextError: (any Error)?
    private let now: () -> Date

    public init(now: @escaping () -> Date = { FakeCountsRepository.fixedNow }) {
        self.now = now
    }

    public func textbooks(centre _: UUID) async throws -> [Textbook] {
        try begin()
        return textbooks
    }

    public func save(_ textbook: Textbook, centre _: UUID) async throws -> Textbook {
        try begin()
        textbooks.removeAll {
            $0.schoolID == textbook.schoolID && $0.classLevel == textbook.classLevel && $0.subject == textbook.subject
        }
        textbooks.append(textbook)
        return textbook
    }

    public func copyChapters(of textbookID: UUID, to studentID: UUID, centre _: UUID) async throws {
        try begin()
        guard let book = textbooks.first(where: { $0.id == textbookID }) else { return }
        let kept = chaptersByStudent[studentID, default: []].filter { source[$0.id] != textbookID }
        var chapters = kept
        var skills = skillsByStudent[studentID, default: []]
            .filter { skill in kept.contains { $0.id == skill.chapterID } }
        for chapter in book.chapters {
            let id = UUID()
            source[id] = textbookID
            chapters.append(Chapter(id: id, subject: book.subject, position: chapter.position, name: chapter.name))
            for (index, name) in chapter.skills.enumerated() {
                skills.append(Skill(
                    id: UUID(), chapterID: id, position: index + 1, name: name, state: .notStarted, stateAt: now(),
                    lastCheckedAt: nil
                ))
            }
        }
        chaptersByStudent[studentID] = chapters
        skillsByStudent[studentID] = skills
    }

    public func chapters(student: UUID) async throws -> [Chapter] {
        try begin()
        return chaptersByStudent[student, default: []]
    }

    public func skills(student: UUID) async throws -> [Skill] {
        try begin()
        return skillsByStudent[student, default: []]
    }

    public func setState(skillID: UUID, _ state: SkillState) async throws {
        try begin()
        for (student, skills) in skillsByStudent {
            skillsByStudent[student] = skills.map { skill in
                guard skill.id == skillID else { return skill }
                var changed = skill
                changed.state = state
                changed.stateAt = now()
                return changed
            }
        }
    }

    private func begin() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
