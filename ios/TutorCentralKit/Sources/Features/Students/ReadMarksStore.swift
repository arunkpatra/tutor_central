import Data
import Domain
import Foundation
import Observation

/// Marks from a photo (P14-Marks-Reading, -Confirm, -Edit; plan/phase-14-plan.md Task 17): one or two pages of a report
/// card or a marked test read by `/ai/read-marks` with the student's consent, each row checked, dated and ticked by the
/// tutor; Save writes a mark per ticked row, Undo takes them back. Nothing is kept until Save.
@MainActor @Observable public final class ReadMarksStore {
    public enum Stage: Hashable, Sendable {
        case choosing, reading, read, saving, failed(String)
    }

    public struct Row: Identifiable, Hashable, Sendable {
        public let id: UUID
        public var mark: ReadMark
        public var ticked: Bool

        /// "Mathematics · Unit test 2".
        public var title: String {
            "\(mark.subject) · \(mark.test)"
        }

        /// "28 Sep"; "Date · not given".
        public var line: String {
            mark.date?.shortText ?? "Date · not given"
        }

        public var lineIsMissing: Bool {
            mark.date == nil
        }

        /// "14 of 25".
        public var score: String {
            "\(mark.score) of \(mark.max)"
        }
    }

    public static let maxPages = 2
    public static let tooManyPages = "Two pages at most. A report card is one; a marked test front and back is two."
    public static let undoFailed = "The marks weren't taken back. Check your connection and try again."
    public static let nothingRead = "Couldn't read any marks from this photo. Try a flatter, brighter one."
    public let aiLine = "AI can make mistakes. Check each mark against the paper."
    public let footnote = "Each mark read appears here for you to check. Nothing is kept until you tap Save."
    public let readFootnote = "Open a mark to change its subject, test, date or score. A mark without a date waits "
        + "until you set one. Nothing is kept until you tap Save."

    public internal(set) var stage: Stage = .choosing
    public internal(set) var pages: [ImageUpload] = []
    public var rows: [Row] = []
    /// A refused page or save in words (the alert).
    public var message: String?
    /// "2 marks saved to Hemanth's page", for the toast with Undo.
    public internal(set) var toast: String?
    @ObservationIgnored var saved: [UUID] = []
    @ObservationIgnored var run: Task<Void, Never>?
    /// The read in hand: one started over leaves the new one's handle alone when it ends.
    @ObservationIgnored var generation = 0
    /// The student's subjects as read for the call, offered first on the mark's sheet.
    @ObservationIgnored var known: [String] = []
    let studentID: UUID
    let register: RegisterStore
    let textbooks: any TextbooksRepository
    let ai: any AIRepository
    let record: any RecordRepository
    let online: () async -> Bool
    let now: () -> Date

    public init(
        student: UUID, register: RegisterStore, textbooks: any TextbooksRepository, ai: any AIRepository,
        record: any RecordRepository, online: @escaping () async -> Bool, now: @escaping () -> Date,
        page: ImageUpload? = nil
    ) {
        studentID = student
        pages = page.map { [$0] } ?? []
        self.register = register
        self.textbooks = textbooks
        self.ai = ai
        self.record = record
        self.online = online
        self.now = now
    }

    var student: Student? {
        register.student(studentID)
    }

    var today: Day {
        Day(now(), calendar: DayHeading.india)
    }

    /// A link or a launch state can open the screen before the register is read.
    public func prepare() async {
        await register.loadIfNeeded()
    }

    /// The board's reading state (P14-Marks-Reading) without a call.
    public func showReading() {
        stage = .reading
    }

    var centre: UUID {
        register.workspace.centre.id
    }

    public var heroName: String {
        student?.name ?? ""
    }

    public let heroLine = "From a photo · a report card or a marked test"

    /// "1 page · a report card is one page, a marked test front and back is two"; "1 page read".
    public var pagesLine: String {
        let count = pages.count == 1 ? "1 page" : "\(pages.count) pages"
        return stage == .read ? "\(count) read"
            : "\(count) · a report card is one page, a marked test front and back is two"
    }

    public var canAddPage: Bool {
        pages.count < Self.maxPages && stage != .saving
    }

    /// "3 marks read".
    public var title: String {
        rows.count == 1 ? "1 mark read" : "\(rows.count) marks read"
    }

    /// Why the photo cannot be read: the parent has not agreed (D62).
    public var consentLine: String? {
        guard let student, student.consent == nil else { return nil }
        let parent = student.parentName.flatMap { $0.split(separator: " ").first.map(String.init) }
        return "Marks from a photo wait for \(parent.map { "\($0)'s" } ?? "the parent's") consent."
    }

    var ticked: [Row] {
        rows.filter(\.ticked)
    }

    public var canSave: Bool {
        stage == .read && !ticked.isEmpty && ticked.allSatisfy { $0.mark.date != nil }
    }

    /// "Save 2 marks", "Save 1 mark"; "Save" while there is nothing to save.
    public var saveLabel: String {
        switch ticked.count {
        case 0: "Save"
        case 1: "Save 1 mark"
        default: "Save \(ticked.count) marks"
        }
    }

    /// A page from the camera or Photos; a third is refused in words.
    public func add(_ page: ImageUpload) {
        guard pages.count < Self.maxPages else {
            message = Self.tooManyPages
            return
        }
        pages.append(page)
    }

    /// Add a page: added and read again with every page, a reading under way started over.
    public func addAndRead(_ page: ImageUpload) {
        let before = pages.count
        add(page)
        guard pages.count > before else { return }
        run?.cancel()
        run = nil
        begin()
    }

    /// Reading in a task the store owns: Cancel stops it and a late answer is dropped.
    public func begin() {
        guard run == nil else { return }
        generation += 1
        let mine = generation
        run = Task { [weak self] in
            await self?.read()
            if self?.generation == mine {
                self?.run = nil
            }
        }
    }

    public func cancel() {
        run?.cancel()
        run = nil
        stage = .choosing
    }

    /// `/ai/read-marks` with the pages and the student's subjects; refused without consent or a connection.
    public func read() async {
        guard let student, !pages.isEmpty else { return }
        if let consentLine {
            stage = .failed(consentLine)
            return
        }
        guard await online() else {
            stage = .failed(OfflineRefusal.words(for: .readMarks))
            return
        }
        stage = .reading
        let subjects = await subjects(of: student)
        known = subjects
        do {
            let answer = try await ai.readMarks(
                ReadMarksRequest(studentID: student.id, studentName: student.name, pages: pages, subjects: subjects),
                centre: centre
            )
            guard !Task.isCancelled else { return }
            guard !answer.marks.isEmpty else {
                stage = .failed(Self.nothingRead)
                return
            }
            rows = answer.marks.map { Row(id: UUID(), mark: $0, ticked: $0.date != nil) }
            stage = .read
        } catch {
            guard !Task.isCancelled else { return }
            stage = .failed(error.message)
        }
    }

    /// The mark's sheet's subjects: the one read, the student's, then the common ones; no repeats.
    public func subjectChoices(_ current: String) -> [String] {
        var seen = Set<String>()
        return ([current] + known + Subject.common).filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    /// The student's subjects (their books', then their batch's), for the reading to match the card's names.
    private func subjects(of student: Student) async -> [String] {
        let chapters = await (try? textbooks.chapters(student: student.id)) ?? []
        var seen = Set<String>()
        let batch = register.classroom(student.classID)?.subject
        return (chapters.map(\.subject) + [batch].compactMap(\.self)).filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
