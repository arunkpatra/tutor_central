import Foundation

/// One question of the placement: the chapter (or ladder step) it places, its skill as the eyebrow, the tap.
public struct PlacementRow: Identifiable, Hashable, Sendable {
    public var id: UUID {
        skillID
    }

    public let chapterID: UUID
    public let skillID: UUID
    public let chapter: String
    public let skill: String
    public let question: String
    public let answer: String
    public var tap: Bool?

    public init(
        chapterID: UUID, skillID: UUID, chapter: String, skill: String, question: String, answer: String,
        tap: Bool? = nil
    ) {
        self.chapterID = chapterID
        self.skillID = skillID
        self.chapter = chapter
        self.skill = skill
        self.question = question
        self.answer = answer
        self.tap = tap
    }
}

/// One subject's placement questions, or the words when they could not be made.
public struct PlacementSubject: Identifiable, Hashable, Sendable {
    public var id: String {
        title
    }

    public let title: String
    public var rows: [PlacementRow]
    public var failure: String?

    public init(title: String, rows: [PlacementRow], failure: String?) {
        self.title = title
        self.rows = rows
        self.failure = failure
    }

    public var countLine: String {
        "\(rows.count { $0.tap == true }) of \(rows.count) right"
    }
}

/// The placement's rules (plan decision 7), shared by the student's page and the close.
public enum Placement {
    /// What one subject asks about: a book's chapters (the chapter's first skill as the eyebrow), or a ladder's steps.
    public struct Group: Sendable {
        public let title: String
        public let items: [GroupItem]
    }

    public struct GroupItem: Sendable {
        public let chapterID: UUID
        public let skillID: UUID
        public let name: String
        public let skill: String
    }

    /// The subjects in order (the ladder's areas first, then by name), each with its questions' chapters.
    public static func groups(chapters: [Chapter], skills: [Skill]) -> [Group] {
        let bySubject = Dictionary(grouping: chapters, by: \.subject)
        let rank = { (subject: String) -> Int in
            bySubject[subject]?.first?.ladder.flatMap { Ladder.Area.allCases.firstIndex(of: $0) } ?? Int.max
        }
        return bySubject.keys.sorted { rank($0) != rank($1) ? rank($0) < rank($1) : $0 < $1 }.compactMap { subject in
            let list = (bySubject[subject] ?? []).sorted { $0.position < $1.position }
            let items: [GroupItem] = if let ladder = list.first, ladder.ladder != nil {
                skills.filter { $0.chapterID == ladder.id }.sorted { $0.position < $1.position }.map {
                    GroupItem(chapterID: ladder.id, skillID: $0.id, name: $0.name, skill: $0.name)
                }
            } else {
                list.compactMap { chapter in
                    skills.filter { $0.chapterID == chapter.id }.min { $0.position < $1.position }.map {
                        GroupItem(chapterID: chapter.id, skillID: $0.id, name: chapter.name, skill: $0.name)
                    }
                }
            }
            return items.isEmpty ? nil : Group(title: list.first?.ladder?.title ?? subject, items: items)
        }
    }

    /// A group's rows from the questions made for it, in order.
    public static func rows(_ group: Group, questions: [(question: String, answer: String)]) -> [PlacementRow] {
        zip(group.items, questions).map { item, made in
            PlacementRow(
                chapterID: item.chapterID, skillID: item.skillID, chapter: item.name, skill: item.skill,
                question: made.question, answer: made.answer
            )
        }
    }

    /// The states a subject's taps make: a book's chapter carries all its skills, a ladder step is its own chapter.
    public static func changes(_ subject: PlacementSubject, chapters: [Chapter], skills: [Skill])
        -> [SkillStateChange] {
        SkillProgress.placementChanges(subject.rows.enumerated().compactMap { index, row in
            guard let chapter = chapters.first(where: { $0.id == row.chapterID }) else { return nil }
            if chapter.ladder != nil {
                let step = Chapter(id: row.skillID, subject: chapter.subject, position: index + 1, name: row.skill)
                return SkillProgress.Answer(step, skills.filter { $0.id == row.skillID }, row.tap)
            }
            return SkillProgress.Answer(chapter, skills.filter { $0.chapterID == chapter.id }, row.tap)
        })
    }
}
