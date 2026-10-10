import Data
import Domain
import Foundation
import Observation

/// Add a textbook (D58; P10-Textbook-Intro, -Reading, -Chapters, -Chapter-Edit): one photo of a contents page, read
/// into
/// a list the tutor checks; Keep writes the book once for the school, class and subject and copies it to every
/// student of that school and class. Nothing is written before Keep; the photo lives in the request only ("We keep no
/// copy").
@MainActor @Observable public final class TextbookStore {
    public enum Phase: Hashable, Sendable {
        case intro, reading, chapters, keeping
    }

    public let student: Student
    public let school: School
    public internal(set) var phase: Phase = .intro
    public var subject: String?
    /// The chapters as read, then as the tutor changed them; positions in order.
    public internal(set) var chapters: [TextbookChapter] = []
    public internal(set) var title: String?
    /// A failure's words for the system alert (U33): the API's, or offline's.
    public var failure: String?
    /// The student's own subjects, read on open; they lead the subject list.
    public internal(set) var ownSubjects: [String] = []

    let register: RegisterStore
    let ai: any AIRepository
    let textbooks: any TextbooksRepository
    let online: @Sendable () async -> Bool
    @ObservationIgnored var task: Task<Void, Never>?

    public init(
        student: Student, school: School, register: RegisterStore, ai: any AIRepository,
        textbooks: any TextbooksRepository, subject: String? = nil, online: @escaping @Sendable () async -> Bool
    ) {
        self.student = student
        self.school = school
        self.register = register
        self.ai = ai
        self.textbooks = textbooks
        self.subject = subject
        self.online = online
    }

    private var classLevel: ClassLevel {
        student.classLevel ?? .five
    }

    /// The student's subjects, the batch's, then the common ones; no repeats.
    public var subjects: [String] {
        var seen = Set<String>()
        let batch = register.classroom(student.classID)?.subject
        return (ownSubjects + [batch].compactMap(\.self) + Subject.common)
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    public var canRead: Bool {
        subject != nil && phase == .intro
    }

    /// "Vidya Niketan, class 5. Riya's classmates there get the same chapters."
    public var subjectHelper: String {
        "\(school.name), \(classLevel.title.lowercased()). \(student.firstName)'s classmates there get the same "
            + "chapters."
    }

    public var introLine: String {
        let book = subject.map { "\($0.lowercased()) book" } ?? "book"
        return "Open \(student.firstName)'s \(book) at its contents page and take a photo. We read the chapter names "
            + "into a list you check."
    }

    /// "Usually under a minute. Mathematics · Vidya Niketan · class 5"
    public var readingLine: String {
        "Usually under a minute. \(subject ?? "") · \(school.name) · \(classLevel.title.lowercased())"
    }

    /// "Vidya Niketan, class 5 · from the photo"
    public var sourceLine: String {
        "\(school.name), \(classLevel.title.lowercased()) · from the photo"
    }

    public var chaptersTitle: String {
        chapters.count == 1 ? "1 chapter read" : "\(chapters.count) chapters read"
    }

    public var keepTitle: String {
        chapters.count == 1 ? "Keep 1 chapter" : "Keep \(chapters.count) chapters"
    }

    public nonisolated static func skillsLine(_ chapter: TextbookChapter) -> String {
        chapter.skills.count == 1 ? "1 skill read" : "\(chapter.skills.count) skills read"
    }

    /// The student's own subjects, from the chapters they already have.
    public func load() async {
        if let chapters = try? await textbooks.chapters(student: student.id) {
            ownSubjects = Array(Set(chapters.filter { $0.ladder == nil }.map(\.subject))).sorted()
        }
    }

    /// Reading in a task the store owns: Back cancels it and a late answer is dropped.
    public func begin(_ photo: ImageUpload) {
        task?.cancel()
        task = Task { [weak self] in
            await self?.read(photo, thumbnail: nil)
        }
    }

    /// One read of the contents page; offline is refused before the call. A failure goes back to the intro.
    public func read(_ photo: ImageUpload, thumbnail _: Data?) async {
        guard let subject else { return }
        guard await online() else {
            failure = OfflineRefusal.words(for: .textbook)
            return
        }
        phase = .reading
        do {
            let reading = try await ai.parseTextbook(
                photo, classLevel: classLevel, subject: subject, centre: register.workspace.centre.id
            )
            guard !Task.isCancelled, phase == .reading else { return }
            title = reading.title
            chapters = reading.chapters
            phase = .chapters
        } catch {
            guard !Task.isCancelled, phase == .reading else { return }
            phase = .intro
            failure = error.message
        }
    }

    public func cancel() {
        task?.cancel()
        task = nil
        if phase == .reading {
            phase = .intro
        }
    }

    public func rename(at index: Int, to name: String) {
        guard chapters.indices.contains(index) else { return }
        chapters[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func setSkills(at index: Int, _ skills: [String]) {
        guard chapters.indices.contains(index) else { return }
        chapters[index].skills = skills.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    public func remove(at index: Int) {
        guard chapters.indices.contains(index) else { return }
        chapters.remove(at: index)
        renumber()
    }

    public func add(name: String, skills: [String]) {
        chapters.append(TextbookChapter(position: chapters.count + 1, name: name, skills: skills))
        renumber()
    }

    /// Keep: the book written once for the school, class and subject, then copied to the class; true when kept.
    public func keep() async -> Bool {
        guard let subject, !chapters.isEmpty, phase == .chapters else { return false }
        guard await online() else {
            failure = OfflineRefusal.words(for: .textbook)
            return false
        }
        phase = .keeping
        let book = Textbook(
            id: UUID(), schoolID: school.id, classLevel: classLevel, subject: subject,
            title: title ?? "\(subject), \(classLevel.title.lowercased())", publisher: nil, edition: nil,
            chapters: chapters
        )
        do {
            let saved = try await textbooks.save(book, centre: register.workspace.centre.id)
            _ = try await textbooks.copyToClass(textbookID: saved.id, centre: register.workspace.centre.id)
            return true
        } catch {
            phase = .chapters
            failure = TransportError.isOffline(error) ? OfflineRefusal.words(for: .textbook)
                : "Couldn't keep the chapters. Check your connection and try again."
            return false
        }
    }

    private func renumber() {
        for index in chapters.indices {
            chapters[index].position = index + 1
        }
    }
}
