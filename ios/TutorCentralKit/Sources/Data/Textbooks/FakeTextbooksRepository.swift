import Domain
import Foundation
import Supabase

/// The in-memory textbooks and per-student chapters for tests, previews and `bun shots`, with a scripted error. It
/// copies as migrations 0016 and 0017 do: a chapter matched by its position in the book and a skill by its position in
/// the chapter keep their states; a tutor's own chapter of the subject goes behind the book's; Keep reaches every
/// active
/// student of the school and class in `students`.
@MainActor public final class FakeTextbooksRepository: TextbooksRepository {
    public private(set) var textbooks: [Textbook]
    public private(set) var chaptersByStudent: [UUID: [Chapter]]
    public private(set) var skillsByStudent: [UUID: [Skill]]
    /// The register the class-wide copies read (the database reads `students`).
    public var students: [Student] = []
    public var nextError: (any Error)?
    public private(set) var copyToClassCalls: [UUID] = []
    public private(set) var copyAllCalls: [UUID] = []
    public private(set) var ladderCalls: [UUID] = []
    /// What `SupabaseTextbooksRepository.values` would write for the last save (the photo is never in it).
    public private(set) var lastWrittenValues: [String: AnyJSON]?
    /// Which book each copied chapter came from, as `chapters.textbook_id` keeps it.
    private var source: [UUID: UUID] = [:]
    private let now: () -> Date

    public init(
        textbooks: [Textbook] = [], chapters: [UUID: [Chapter]] = [:], skills: [UUID: [Skill]] = [:],
        now: @escaping () -> Date = { FakeCountsRepository.fixedNow }
    ) {
        self.textbooks = textbooks
        chaptersByStudent = chapters
        skillsByStudent = skills
        self.now = now
        for (student, list) in chapters where student == FakeStudentsRepository.hemanth {
            for chapter in list where chapter.subject == Self.mathsTen.subject {
                source[chapter.id] = Self.mathsTen.id
            }
        }
    }

    /// The fixtures: Hemanth's Mathematics from the class 10 book with the 10.2 boards' states, Sahil's ladder, and the
    /// book itself; the register's students for the copies.
    public static func seeded() -> FakeTextbooksRepository {
        let repo = FakeTextbooksRepository(textbooks: [mathsTen], chapters: seedChapters, skills: seedSkills)
        repo.students = FakeStudentsRepository.seed
        return repo
    }

    public func textbooks(centre _: UUID) async throws -> [Textbook] {
        try begin()
        return textbooks
    }

    /// One row per school, class and subject: a second capture keeps the first's id (the upsert's conflict target).
    public func save(_ textbook: Textbook, centre: UUID) async throws -> Textbook {
        try begin()
        lastWrittenValues = SupabaseTextbooksRepository.values(textbook, centre: centre)
        let existing = textbooks.firstIndex {
            $0.schoolID == textbook.schoolID && $0.classLevel == textbook.classLevel && $0.subject == textbook.subject
        }
        guard let existing else {
            textbooks.append(textbook)
            return textbook
        }
        let kept = Textbook(
            id: textbooks[existing].id, schoolID: textbook.schoolID, classLevel: textbook.classLevel,
            subject: textbook.subject, title: textbook.title, publisher: textbook.publisher, edition: textbook.edition,
            chapters: textbook.chapters
        )
        textbooks[existing] = kept
        return kept
    }

    public func copyChapters(of textbookID: UUID, to studentID: UUID, centre _: UUID) async throws {
        try begin()
        copy(textbookID, to: studentID)
    }

    public func copyToClass(textbookID: UUID, centre _: UUID) async throws -> Int {
        try begin()
        copyToClassCalls.append(textbookID)
        guard let book = textbooks.first(where: { $0.id == textbookID }) else { return 0 }
        let reached = students.filter {
            $0.schoolID == book.schoolID && $0.classLevel == book.classLevel && !$0.isArchived
        }
        for student in reached {
            copy(textbookID, to: student.id)
        }
        return reached.count
    }

    public func copyAll(to studentID: UUID, centre _: UUID) async throws -> Int {
        try begin()
        copyAllCalls.append(studentID)
        guard let student = students.first(where: { $0.id == studentID }) else { return 0 }
        let books = textbooks.filter { $0.schoolID == student.schoolID && $0.classLevel == student.classLevel }
        for book in books {
            copy(book.id, to: studentID)
        }
        return books.count
    }

    public func addChapter(student: UUID, subject: String, name: String, skills: [String], centre _: UUID)
        async throws -> Chapter {
        try begin()
        let last = chaptersByStudent[student, default: []].filter { $0.subject == subject }.map(\.position).max() ?? 0
        let chapter = Chapter(id: UUID(), subject: subject, position: last + 1, name: name)
        chaptersByStudent[student, default: []].append(chapter)
        skillsByStudent[student, default: []] += skills.enumerated().map { index, skill in
            Skill(
                id: UUID(),
                chapterID: chapter.id,
                position: index + 1,
                name: skill,
                state: .notStarted,
                stateAt: now(),
                lastCheckedAt: nil
            )
        }
        return chapter
    }

    public func ensureLadder(student: UUID, centre _: UUID) async throws {
        try begin()
        ladderCalls.append(student)
        let have = Set(chaptersByStudent[student, default: []].compactMap(\.ladder))
        for area in Ladder.Area.allCases where !have.contains(area) {
            let chapter = Chapter(id: UUID(), subject: area.title, position: 1, name: area.title, ladder: area)
            chaptersByStudent[student, default: []].append(chapter)
            skillsByStudent[student, default: []] += area.steps.enumerated().map { index, step in
                Skill(
                    id: UUID(),
                    chapterID: chapter.id,
                    position: index + 1,
                    name: step,
                    state: .notStarted,
                    stateAt: now(),
                    lastCheckedAt: nil
                )
            }
        }
    }

    public func chapters(student: UUID) async throws -> [Chapter] {
        try begin()
        return chaptersByStudent[student, default: []].sorted { ($0.subject, $0.position) < ($1.subject, $1.position) }
    }

    public func skills(student: UUID) async throws -> [Skill] {
        try begin()
        return skillsByStudent[student, default: []].sorted { $0.position < $1.position }
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

    /// The book's chapters to the student by position, states kept by position, the tutor's own behind (0016, 0017).
    private func copy(_ textbookID: UUID, to studentID: UUID) {
        guard let book = textbooks.first(where: { $0.id == textbookID }) else { return }
        var chapters = chaptersByStudent[studentID, default: []]
        var skills = skillsByStudent[studentID, default: []]
        let fromBook = chapters.filter { source[$0.id] == textbookID }
        let dropped = Set(fromBook.filter { old in !book.chapters.contains { $0.position == old.position } }.map(\.id))
        chapters.removeAll { dropped.contains($0.id) }
        skills.removeAll { dropped.contains($0.chapterID) }
        let last = book.chapters.map(\.position).max() ?? 0
        let own = chapters.filter { source[$0.id] == nil && $0.ladder == nil && $0.subject == book.subject }
            .sorted { $0.position < $1.position }
        for (rank, chapter) in own.enumerated() {
            if let index = chapters.firstIndex(where: { $0.id == chapter.id }) {
                chapters[index].position = last + rank + 1
            }
        }
        for read in book.chapters {
            let id: UUID
            if let index = chapters.firstIndex(where: { source[$0.id] == textbookID && $0.position == read.position }) {
                chapters[index].name = read.name
                id = chapters[index].id
            } else {
                id = UUID()
                source[id] = textbookID
                chapters.append(Chapter(id: id, subject: book.subject, position: read.position, name: read.name))
            }
            skills.removeAll { $0.chapterID == id && $0.position > read.skills.count }
            for (index, name) in read.skills.enumerated() {
                if let at = skills.firstIndex(where: { $0.chapterID == id && $0.position == index + 1 }) {
                    skills[at].name = name
                } else {
                    skills.append(Skill(
                        id: UUID(),
                        chapterID: id,
                        position: index + 1,
                        name: name,
                        state: .notStarted,
                        stateAt: now(),
                        lastCheckedAt: nil
                    ))
                }
            }
        }
        chaptersByStudent[studentID] = chapters
        skillsByStudent[studentID] = skills
    }

    private func begin() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
