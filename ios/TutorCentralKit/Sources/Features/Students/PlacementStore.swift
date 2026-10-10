import Data
import Domain
import Foundation
import Observation

/// The placement (P10-Placement, and inside the close for a student with no checks yet): a few questions per subject,
/// one per chapter in the book's order (the chapter's first skill as the eyebrow) or one per ladder step; tapped right
/// or wrong, untapped skipped. Done keeps the taps as placement checks, makes the chapters before the first wrong
/// secure (`SkillProgress.placementChanges`) and stores the status worked out with them, in one write.
@MainActor @Observable public final class PlacementStore {
    public struct Row: Identifiable, Hashable, Sendable {
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
    }

    public struct SubjectRows: Identifiable, Hashable, Sendable {
        public var id: String {
            title
        }

        public let title: String
        public var rows: [Row]
        /// The in-place words when this subject's questions could not be made.
        public var failure: String?

        public var countLine: String {
            "\(rows.count { $0.tap == true }) of \(rows.count) right"
        }
    }

    public let studentID: UUID
    public var subjects: [SubjectRows] = []
    public internal(set) var loading = false
    public internal(set) var finishing = false
    /// A refused write's words for the system alert (U33).
    public var failure: String?

    let register: RegisterStore
    let ai: any AIRepository
    let textbooks: any TextbooksRepository
    let record: any RecordRepository
    let attendance: any AttendanceRepository
    let now: @Sendable () -> Date
    let online: @Sendable () async -> Bool
    private var chapters: [Chapter] = []
    private var skills: [Skill] = []

    public init(
        studentID: UUID, register: RegisterStore, ai: any AIRepository, textbooks: any TextbooksRepository,
        record: any RecordRepository, attendance: any AttendanceRepository, now: @escaping @Sendable () -> Date,
        online: @escaping @Sendable () async -> Bool
    ) {
        self.studentID = studentID
        self.register = register
        self.ai = ai
        self.textbooks = textbooks
        self.record = record
        self.attendance = attendance
        self.now = now
        self.online = online
    }

    var student: Student? {
        register.student(studentID)
    }

    public var title: String {
        "Placement · \(student?.firstName ?? "")"
    }

    public var footnote: String {
        "A few questions per subject, so the plan starts at the right place. Ask them in your words and tap what "
            + "\(student?.firstName ?? "the student") answers. Skip any you don't ask."
    }

    public var doneFootnote: String {
        let child = student?.firstName ?? "The student"
        let pronoun = StudentDetailStore.pronouns(student?.gender)
        return "Done keeps what you tapped. \(child)'s chapters start from the first skill \(pronoun.subject) got "
            + "wrong in each subject."
    }

    public var canFinish: Bool {
        subjects.contains { $0.rows.contains { $0.tap != nil } } && !finishing
    }

    /// The student's chapters and skills, then each subject's questions, all at once.
    public func load() async {
        loading = true
        defer { loading = false }
        await register.loadIfNeeded()
        chapters = await (try? textbooks.chapters(student: studentID)) ?? []
        skills = await (try? textbooks.skills(student: studentID)) ?? []
        let groups = Self.groups(chapters: chapters, skills: skills)
        subjects = groups.map { SubjectRows(title: $0.title, rows: [], failure: nil) }
        await withTaskGroup(of: (Int, Result<[Row], APIFailure>).self) { group in
            for (index, item) in groups.enumerated() {
                group.addTask { await (index, self.ask(item)) }
            }
            for await (index, result) in group {
                apply(result, at: index)
            }
        }
    }

    /// Try again for one subject.
    public func retry(_ subjectID: String) async {
        guard let index = subjects.firstIndex(where: { $0.id == subjectID }),
              let item = Self.groups(chapters: chapters, skills: skills).first(where: { $0.title == subjectID })
        else { return }
        subjects[index].failure = nil
        await apply(ask(item), at: index)
    }

    /// Done: the taps, the states and the status in one write; the register's student takes the status.
    public func finish() async -> Bool {
        guard canFinish, let student else { return false }
        guard await online() else {
            failure = OfflineRefusal.words(for: .placement)
            return false
        }
        finishing = true
        defer { finishing = false }
        let placement = await placementRecord(for: student, absences: absences())
        do {
            try await record.recordPlacement(placement, centre: register.workspace.centre.id)
        } catch {
            failure = TransportError.isOffline(error) ? OfflineRefusal.words(for: .placement)
                : "Couldn't keep the placement. Check your connection and try again."
            return false
        }
        if let track = placement.track {
            var updated = student
            if updated.trackStatus != track.status {
                updated.trackSince = now()
            }
            updated.trackStatus = track.status
            updated.trackReasons = track.reasons
            register.replace(studentID, with: updated)
        }
        return true
    }

    /// The tapped rows as checks, the chapters made secure, and the status with them.
    func placementRecord(for student: Student, absences: Int) -> PlacementRecord {
        let tapped = subjects.flatMap(\.rows).filter { $0.tap != nil }
        let checks = tapped.map { row in
            SessionClose.Check(
                studentID: studentID, skillID: row.skillID, question: row.question, correct: row.tap == true,
                isPlacement: true
            )
        }
        let states = subjects.flatMap { subject in
            SkillProgress.placementChanges(subject.rows.enumerated().compactMap { index, row in
                answer(for: row, index: index)
            })
        }
        let records = checks.map {
            CheckRecord(
                id: UUID(), studentID: studentID, skillID: $0.skillID, sessionID: nil, question: $0.question,
                correct: $0.correct, at: now(), isPlacement: true
            )
        }
        let secured = Set(states.map(\.skillID))
        let after = skills.map { skill in
            var changed = skill
            if secured.contains(skill.id) {
                changed.state = .secure
            }
            return changed
        }
        let tracking = TrackingRules.evaluate(TrackingInput(
            checks: records, absences: absences, homework: [], skills: after, chapters: chapters,
            classLevel: student.classLevel, now: now(), calendar: DayHeading.india
        ))
        return PlacementRecord(
            studentID: studentID, checks: checks, states: states,
            track: SessionClose.Track(status: tracking.status, reasons: tracking.reasons)
        )
    }

    /// A row as one chapter of the placement: a book's chapter with all its skills, or a ladder step as its own.
    private func answer(for row: Row, index: Int) -> SkillProgress.Answer? {
        guard let chapter = chapters.first(where: { $0.id == row.chapterID }) else { return nil }
        if chapter.ladder != nil {
            let step = Chapter(id: row.skillID, subject: chapter.subject, position: index + 1, name: row.skill)
            return SkillProgress.Answer(step, skills.filter { $0.id == row.skillID }, row.tap)
        }
        return SkillProgress.Answer(chapter, skills.filter { $0.chapterID == chapter.id }, row.tap)
    }

    private func absences() async -> Int {
        let calendar = DayHeading.india
        let from = calendar.date(byAdding: .day, value: -TrackingRules.absenceWindowDays, to: now()) ?? now()
        let months = Set([
            Period.containing(from, in: calendar.timeZone),
            Period.containing(now(), in: calendar.timeZone),
        ])
        var sessions: [AttendanceSession] = []
        for month in months {
            sessions += await (try? attendance.sessions(centre: register.workspace.centre.id, month: month)) ?? []
        }
        let since = Day(from, calendar: calendar)
        return sessions.count { $0.date >= since && $0.marks[studentID] == .absent }
    }

    private func ask(_ group: Group) async -> Result<[Row], APIFailure> {
        guard let level = student?.classLevel else { return .success([]) }
        do {
            let questions = try await ai.makePlacement(
                classLevel: level, subject: group.title, chapters: group.items.map(\.name),
                centre: register.workspace.centre.id
            )
            let rows = zip(group.items, questions).map { item, question in
                Row(
                    chapterID: item.chapterID, skillID: item.skillID, chapter: item.name, skill: item.skill,
                    question: question.question, answer: question.answer, tap: nil
                )
            }
            return .success(rows)
        } catch {
            return .failure(error)
        }
    }

    private func apply(_ result: Result<[Row], APIFailure>, at index: Int) {
        guard subjects.indices.contains(index) else { return }
        switch result {
        case let .success(rows): subjects[index].rows = rows
        case let .failure(error): subjects[index].failure = error.message
        }
    }

    /// What one subject asks about: a book's chapters (the chapter's first skill as the eyebrow), or a ladder's steps.
    struct Group: Sendable {
        let title: String
        let items: [GroupItem]
    }

    struct GroupItem: Sendable {
        let chapterID: UUID
        let skillID: UUID
        let name: String
        let skill: String
    }

    nonisolated static func groups(chapters: [Chapter], skills: [Skill]) -> [Group] {
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
}
