import Data
import DesignSystem
import Domain
import Foundation

/// The page's V2 lines (P10-Student, -Record, -End, -NotKnown, -Ladder): the header's chips, the tracking card, this
/// week, the record by subject, the checks' trend, homework, school and messages.
public extension StudentDetailStore {
    struct TrackingLines: Hashable, Sendable {
        public let status: TrackStatus
        public let since: String?
        public let reasons: String
        public let next: String
        /// Place <name> on the card: not known yet and something to place on.
        public let placeAction: Bool
    }

    struct WeekRow: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let day: String
        public let date: String
        public let title: String
        public let line: String
    }

    struct SkillLine: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let name: String
        public let line: String?
        public let mark: SkillMark
    }

    struct ChapterLine: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let position: Int
        public let name: String
        public let line: String
        public let open: Bool
        public let skills: [SkillLine]
    }

    struct LadderLines: Hashable, Sendable {
        public let line: String
        public let steps: [LadderStep]
    }

    struct LadderStep: Hashable, Sendable {
        public let name: String
        public let step: LadderRow.Step
    }

    struct SubjectCard: Identifiable, Hashable, Sendable {
        public var id: String {
            title
        }

        public let title: String
        public let line: String
        public let chapters: [ChapterLine]
        public let ladder: LadderLines?
        /// The waiting subject's line under "No chapters yet".
        public let emptyLine: String?
    }

    struct ChecksLines: Hashable, Sendable {
        public let right: [Int]
        public let percent: String
        public let line: String
    }

    struct HomeworkLine: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let title: String
        public let line: String
        public let status: HomeworkStatus
        /// The sheet given, opened by the row.
        public let artefactID: UUID?
    }

    struct MessageLine: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let title: String
        public let line: String
        public let symbol: String
    }

    var classChip: String? {
        student?.classTitle
    }

    var batchChip: String? {
        classroom?.name
    }

    var school: School? {
        student?.schoolID.flatMap { id in register.schools.first { $0.id == id } }
    }

    /// "Vidya Niketan · CBSE": the board from class 8.
    var schoolLine: String? {
        guard let student, let school else { return nil }
        let board = student.showsBoard ? (student.board ?? school.board)?.title : nil
        return [school.name, board].compactMap(\.self).joined(separator: " · ")
    }

    var tracking: TrackingLines? {
        guard let student else { return nil }
        let current = TrackingRules.currentSkill(skills: skills, chapters: chapters)
        let since = student.trackSince.map { "since \(Day($0, calendar: DayHeading.india).shortWeekdayText)" }
        return TrackingLines(
            status: student.trackStatus,
            since: student.trackStatus == .notKnown ? nil : since,
            reasons: reasons(student),
            next: TrackingRules.nextStep(student.trackStatus, current: current),
            placeAction: student.trackStatus == .notKnown && !chapters.isEmpty
        )
    }

    /// The student's batch when it meets today: This week's quiet Today opens its plan (U35).
    var todaysBatch: UUID? {
        guard let classroom else { return nil }
        let today = Day(now(), calendar: DayHeading.india)
        return NextClass.classesToday(in: [classroom], on: today, calendar: DayHeading.india).first?.id
    }

    /// The sessions of this week (Monday on) the student was marked in, oldest first.
    var thisWeek: [WeekRow] {
        let calendar = DayHeading.india
        let today = Day(now(), calendar: calendar)
        let weekday = today.weekday(in: calendar)
        let monday = today.adding(days: -Self.daysSinceMonday(weekday), calendar: calendar)
        return sessions.filter { $0.date >= monday && $0.date <= today && $0.marks[id] != nil }
            .sorted { $0.date < $1.date }
            .map { session in
                let came = session.marks[id] == .present
                let checks = checkRecords.filter { $0.sessionID == session.id }
                let title = !came ? "Absent"
                    : checks.isEmpty ? "Came" : "Came · \(checks.count { $0.correct }) of \(checks.count) right"
                let given = homeworkRecords.contains { $0.sessionID == session.id }
                let batch = register.classroom(session.classID)?.name ?? "All students"
                return WeekRow(
                    id: session.id, day: session.date.weekday(in: calendar).short, date: session.date.shortText,
                    title: title, line: given ? "\(batch) · homework given" : batch
                )
            }
    }

    /// Per subject: the book's chapters, or the ladder; the batch's subject waiting for its book.
    var subjects: [SubjectCard] {
        guard let student else { return [] }
        let bySubject = Dictionary(grouping: chapters, by: \.subject)
        // The ladder first, in its order (Reading, Writing, Numbers), then the subjects by name.
        let rank = { (subject: String) -> Int in
            bySubject[subject]?.first?.ladder.flatMap { Ladder.Area.allCases.firstIndex(of: $0) } ?? Int.max
        }
        var cards = bySubject.keys.sorted { lhs, rhs in
            rank(lhs) != rank(rhs) ? rank(lhs) < rank(rhs) : lhs < rhs
        }
        .map { subject in card(subject, chapters: bySubject[subject] ?? []) }
        if missingBookLine == nil, let subject = classroom?.subject, !subject.isEmpty, bySubject[subject] == nil {
            cards.append(waiting(subject, student: student))
        }
        return cards
    }

    /// A student without a class or a school cannot have a book yet (plan decision 11).
    var missingBookLine: String? {
        guard let student, student.classLevel == nil || student.schoolID == nil else { return nil }
        return "Set \(student.firstName)'s class and school from Edit to add a book."
    }

    /// The last three weeks' checks, one bar per session; nil without any.
    var checks: ChecksLines? {
        let calendar = DayHeading.india
        let from = calendar.date(byAdding: .day, value: -TrackingRules.checkWindowDays, to: now()) ?? now()
        let window = checkRecords.filter { !$0.isPlacement && $0.at >= from }
        guard !window.isEmpty else { return nil }
        let bySession = Dictionary(grouping: window) { $0.sessionID ?? $0.id }
        let sessions = bySession.values.sorted { ($0.first?.at ?? .distantPast) < ($1.first?.at ?? .distantPast) }
        let right = sessions.suffix(12).map { $0.count { $0.correct } }
        let total = window.count, rightTotal = window.count { $0.correct }
        let monday = Day(now(), calendar: calendar).adding(
            days: -Self.daysSinceMonday(Day(now(), calendar: calendar).weekday(in: calendar)), calendar: calendar
        )
        let week = window.filter { Day($0.at, calendar: calendar) >= monday }
        return ChecksLines(
            right: right,
            percent: "\(Int((Double(rightTotal) / Double(total) * 100).rounded()))%",
            line: "\(rightTotal) of \(total) right · 3 questions a class · this week \(week.count { $0.correct }) of "
                + "\(week.count)"
        )
    }

    var homework: [HomeworkLine] {
        homeworkRecords.sorted { $0.givenAt > $1.givenAt }.map { item in
            let session = sessions.first { $0.id == item.sessionID }
            let batch = session.flatMap { register.classroom($0.classID)?.name } ?? classroom?.name ?? "Homework"
            return HomeworkLine(
                id: item.id, title: batch,
                line: "Given \(Day(item.givenAt, calendar: DayHeading.india).shortWeekdayText)", status: item.status,
                artefactID: item.artefactID
            )
        }
    }

    var messages: [MessageLine] {
        entries.map { entry in
            let day = Day(entry.openedAt, calendar: DayHeading.india).shortWeekdayText
            return MessageLine(
                id: entry.id, title: entry.kind.title,
                line: [day, entry.language.map(\.title)].compactMap(\.self).joined(separator: " · "),
                symbol: Self.symbol(entry.kind)
            )
        }
    }

    var schoolEmptyLine: String {
        "Nothing from \(student?.firstName ?? "the student")'s school yet"
    }

    /// The chapter of the current skill opened (the record's board).
    func openCurrentChapter() {
        openChapterID = TrackingRules.currentSkill(skills: skills, chapters: chapters)?.chapterID
    }

    func openChapter(_ chapterID: UUID) {
        openChapterID = openChapterID == chapterID ? nil : chapterID
    }

    /// The next position in a subject: a chapter of the tutor's own goes after the last.
    func nextPosition(_ subject: String) -> Int {
        (chapters.filter { $0.subject == subject }.map(\.position).max() ?? 0) + 1
    }

    /// A chapter of the tutor's own, after the subject's last; read again once written.
    func addChapter(subject: String, name: String, skills: [String]) async {
        guard let textbooks else { return }
        guard await online() else {
            message = OfflineRefusal.words(for: .addChapter)
            return
        }
        do {
            _ = try await textbooks.addChapter(
                student: id, subject: subject, name: name, skills: skills, centre: register.workspace.centre.id
            )
            await loadRecord()
        } catch {
            message = TransportError.isOffline(error) ? OfflineRefusal.words(for: .addChapter)
                : "Couldn't add the chapter. Check your connection and try again."
        }
    }

    /// Done, Partial or Not done on a homework row, written at once (plan decision 15); put back when refused.
    func setHomework(_ homeworkID: UUID, _ status: HomeworkStatus) async {
        guard let record, let index = homeworkRecords.firstIndex(where: { $0.id == homeworkID }) else { return }
        let before = homeworkRecords[index].status
        homeworkRecords[index].status = status
        do {
            try await record.setHomeworkStatus(id: homeworkID, status)
        } catch {
            homeworkRecords[index].status = before
            message = TransportError.isOffline(error)
                ? OfflineRefusal.words(for: .homeworkStatus)
                : "Couldn't mark the homework. Check your connection and try again."
        }
    }
}

extension StudentDetailStore {
    /// The record's reads, together; a failed one leaves its section as it was.
    func loadRecord() async {
        let centre = register.workspace.centre.id
        let since = DayHeading.india.date(byAdding: .day, value: -28, to: now()) ?? now()
        async let chaptersRead = try? textbooks?.chapters(student: id)
        async let skillsRead = try? textbooks?.skills(student: id)
        async let checksRead = try? record?.checks(centre: centre, students: [id], since: since)
        async let homeworkRead = try? record?.homework(centre: centre, students: [id], since: since)
        async let messagesRead = try? messageLog.messages(centre: centre, student: id)
        if let read = await chaptersRead {
            chapters = read
        }
        if let read = await skillsRead {
            skills = read
        }
        if let read = await checksRead {
            checkRecords = read
        }
        if let read = await homeworkRead {
            homeworkRecords = read
        }
        if let read = await messagesRead {
            entries = read
        }
        recordLoaded = true
    }

    private func reasons(_ student: Student) -> String {
        if student.trackStatus == .notKnown {
            let pronoun = Self.pronouns(student.gender)
            let joined = student.joinedAt.map {
                "\(student.firstName) joined on \(Day($0, calendar: DayHeading.india).shortWeekdayText). "
            } ?? ""
            return "\(joined)\(pronoun.possessive.capitalized) first week's checks show where \(pronoun.subject) "
                + "\(pronoun.verb); a placement shows it sooner."
        }
        guard !student.trackReasons.isEmpty else {
            return checks.map { "\($0.line.components(separatedBy: " · ").first ?? "") over three weeks." }
                ?? "No checks in the last three weeks."
        }
        return student.trackReasons.map { "\($0)." }.joined(separator: " ")
    }

    private func card(_ subject: String, chapters list: [Chapter]) -> SubjectCard {
        let sorted = list.sorted { $0.position < $1.position }
        if let area = sorted.first?.ladder {
            return SubjectCard(
                title: area.title, line: "", chapters: [], ladder: ladder(area, chapter: sorted[0]), emptyLine: nil
            )
        }
        let lines = sorted.map { chapter in chapterLine(chapter) }
        let taught = sorted
            .count { chapter in skills.contains { $0.chapterID == chapter.id && $0.state != .notStarted } }
        let count = sorted.count == 1 ? "1 chapter" : "\(sorted.count) chapters"
        return SubjectCard(
            title: subject, line: "\(count) from the book · \(taught) taught", chapters: lines, ladder: nil,
            emptyLine: nil
        )
    }

    private func waiting(_ subject: String, student: Student) -> SubjectCard {
        let school = school?.name ?? "the school"
        let level = student.classLevel.map { $0.title.lowercased() } ?? "the class"
        return SubjectCard(
            title: subject, line: "Nothing from a book yet", chapters: [], ladder: nil,
            emptyLine: "Photograph the contents page of \(student.firstName)'s \(subject.lowercased()) book. "
                + "Everyone at \(school) in \(level) gets the same chapters."
        )
    }

    private func chapterLine(_ chapter: Chapter) -> ChapterLine {
        let own = skills.filter { $0.chapterID == chapter.id }.sorted { $0.position < $1.position }
        let open = openChapterID == chapter.id
        return ChapterLine(
            id: chapter.id, position: chapter.position, name: chapter.name, line: Self.statesLine(own.map(\.state)),
            open: open,
            skills: open ? own.map { skill in
                SkillLine(
                    id: skill.id, name: skill.name,
                    line: skill.lastCheckedAt.map {
                        "checked \(Day($0, calendar: DayHeading.india).shortWeekdayText)"
                    },
                    mark: Self.mark(skill.state)
                )
            } : []
        )
    }

    private func ladder(_ area: Ladder.Area, chapter: Chapter) -> LadderLines {
        let steps = skills.filter { $0.chapterID == chapter.id }.sorted { $0.position < $1.position }
        let secure = steps.prefix { $0.state == .secure }.count
        let kinds = LadderRow.stepKinds(secure: secure, of: area.steps.count)
        let current = steps.indices.contains(secure) ? steps[secure] : steps.last
        let moved = current.map { " · moved up \(Day($0.stateAt, calendar: DayHeading.india).shortWeekdayText)" } ?? ""
        let name = area.steps.indices.contains(secure) ? area.steps[secure] : area.steps.last ?? ""
        return LadderLines(
            line: "\(name)\(moved)",
            steps: zip(area.steps, kinds).map { LadderStep(name: $0, step: $1) }
        )
    }
}
