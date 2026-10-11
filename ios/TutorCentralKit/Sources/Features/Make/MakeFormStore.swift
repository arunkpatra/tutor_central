import Data
import Domain
import Foundation
import Observation

/// One kind's form (P10-Make-Form; decisions 7 to 13): whom it is for, the subject, the skill or topic, and the kind's
/// own fields. The target is turned into a level and skill names (`MakeRules`): nothing about a student goes to the API
/// for the group kinds (D62). Kept in `@State` by the form.
@MainActor @Observable public final class MakeFormStore {
    public let kind: MakeKind
    public private(set) var target: MakeTarget?
    public var subject = ""
    public var skill = ""
    /// Short 6, Medium 10, Long 15.
    public var length = 10
    /// Easier, nil (as the record says), Harder.
    public var levelReason: String?
    public var keyAtEnd = true
    /// The template the tutor chose; else the one the skill matches.
    public var chosenTemplate: FigureSpec.Kind?
    /// The brief's class (the wheel).
    public var classLevel: ClassLevel?
    public var chapter = ""
    /// The mock's and the note's student.
    public var studentID: UUID? {
        didSet {
            if studentID != oldValue {
                exam = nil
            }
        }
    }

    public var exam: ExamChoice?
    public var tutorSays = ""
    /// A refusal's words for the system alert (U33).
    public var alert: String?
    public private(set) var groups: [TodayGroup] = []
    public private(set) var books: [UUID: RecordBook] = [:]
    public private(set) var items: [SchoolItem] = []

    let context: MakeContext
    let make: MakeStore

    public init(kind: MakeKind, context: MakeContext, make: MakeStore) {
        self.kind = kind
        self.context = context
        self.make = make
    }

    /// The register, today's groups, every student's book and the school's items, read together; the last target of
    /// the kind put back when it still stands.
    public func prepare() async {
        await context.register.loadIfNeeded()
        let ids = context.register.activeStudents.map(\.id)
        let centre = context.workspace.centre.id
        let (textbooks, schoolItems) = (context.textbooks, context.schoolItems)
        async let booksRead = try? textbooks.books(centre: centre, students: ids)
        async let itemsRead = try? schoolItems?.items(centre: centre)
        groups = await TodayGroups.read(context)
        books = await booksRead ?? [:]
        items = await itemsRead ?? []
        if let remembered, stands(remembered) {
            if usesStudent, studentID == nil, case let .student(id) = remembered {
                studentID = id
            } else if !usesStudent, target == nil {
                choose(remembered)
            }
        }
        if kind == .brief, classLevel == nil, let last = rememberedBrief {
            (classLevel, subject) = (last.level, last.subject)
        }
    }

    var roster: MakeRoster {
        MakeRoster(students: context.register.activeStudents, classes: context.register.activeClasses, groups: groups)
    }

    /// Whom it is for: the subject and the skill follow the target's record.
    public func choose(_ target: MakeTarget) {
        self.target = target
        let subjects = subjectChoices
        if let first = subjects.first, !subjects.contains(subject) {
            subject = first
        }
        skill = skillChoices.first ?? ""
        make.clearFailure(kind)
    }

    /// The level it is made at: the target's; the brief's chosen class; the mock's student's.
    public var level: ClassLevel? {
        switch kind {
        case .brief: classLevel
        case .mock: studentID.flatMap { context.register.student($0)?.classLevel }
        default: target.flatMap { MakeRules.level(for: $0, roster: roster) }
        }
    }

    public var subjectChoices: [String] {
        if kind == .brief {
            return distinct(levelBooks.flatMap { $0.chapters.sorted { $0.position < $1.position }.map(\.subject) })
        }
        return target.map { MakeRules.subjects(for: $0, books: books, roster: roster) } ?? []
    }

    public var skillChoices: [String] {
        target.map { MakeRules.skills(for: $0, subject: subject, books: books, roster: roster) } ?? []
    }

    /// The brief's chapters: those of the students at the class in the subject, in order.
    public var chapterChoices: [String] {
        distinct(levelBooks.flatMap { book in
            book.chapters.filter { $0.subject == subject && $0.ladder == nil }.sorted { $0.position < $1.position }
                .map(\.name)
        })
    }

    public var template: FigureSpec.Kind? {
        chosenTemplate ?? FigureSpec.Kind.matching(skill: skill)
    }

    /// The student's exams to come, nearest first.
    public var exams: [SchoolItem] {
        guard let student = studentID.flatMap(context.register.student) else { return [] }
        let today = context.today
        return items.filter { $0.kind == .exam && $0.date >= today && SchoolItemRules.reaches($0, student) }
            .sorted { $0.date < $1.date }
    }

    public var canMake: Bool {
        let filled = { (text: String) in !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        switch kind {
        case .sheet, .workedExample: return target != nil && level != nil && filled(subject) && filled(skill)
        case .figure: return target != nil && level != nil && filled(subject) && filled(skill) && template != nil
        case .brief: return level != nil && filled(subject) && filled(chapter)
        case .mock:
            guard level != nil, let exam else { return false }
            if case let .typed(subject, title, portions) = exam {
                return filled(subject) && filled(title) && filled(portions)
            }
            return true
        case .noteToParent: return studentID != nil
        case .paper, .homework, .worksheet: return false
        }
    }

    /// "Made against Group 1's record. A sheet made for a class alone follows the class's chapters."
    public var helper: String? {
        guard let target else { return nil }
        let alone = "A sheet made for a class alone follows the class's chapters."
        let whose: String? = switch target {
        case let .student(id): context.register.student(id)?.firstName
        case let .group(_, number): "Group \(number)"
        case let .batch(id): context.register.classroom(id)?.name
        case .classLevel: nil
        }
        guard let whose else { return kind == .sheet ? alone : nil }
        if level == nil {
            // No class known: the way out, in the helper's place (P10-Make-Form draws no Class tile).
            if case .student = target {
                return "\(whose) has no class yet. Set it on their page, or choose a class in For."
            }
            return "No class is set for \(whose)'s students. Choose a class in For."
        }
        let against = "Made against \(whose)'s record."
        return kind == .sheet ? "\(against) \(alone)" : against
    }

    /// The For tile's words: "Group 1 · Dev, Meher, Nikhil", "Dev Kumar", "Evening batch", "Class 8".
    public var targetTitle: String? {
        guard let target else { return nil }
        switch target {
        case let .student(id):
            return context.register.student(id)?.name
        case let .group(plan, number):
            let members = groups.first { $0.planID == plan && $0.group.number == number }?.group.memberIDs ?? []
            let names = members.compactMap { context.register.student($0)?.firstName }
            return (["Group \(number)"] + (names.isEmpty ? [] : [names.joined(separator: ", ")]))
                .joined(separator: " · ")
        case let .batch(id):
            return context.register.classroom(id)?.name
        case let .classLevel(level):
            return level.title
        }
    }

    /// The For sheet's store over the same reads.
    /// The For sheet opens on the chosen target's segment.
    public var forSegment: ForStore.Segment {
        ForStore.Segment(for: target)
    }

    public func forStore() -> ForStore {
        ForStore(context: context, chosen: target)
    }

    private var levelBooks: [RecordBook] {
        guard let classLevel else { return [] }
        return context.register.activeStudents.filter { $0.classLevel == classLevel }.compactMap { books[$0.id] }
    }

    private func distinct(_ names: [String]) -> [String] {
        names.reduce(into: []) { seen, name in
            if !seen.contains(name) {
                seen.append(name)
            }
        }
    }

    // MARK: - The last target of each kind

    private var defaultsKey: String {
        Self.defaultsKey(kind)
    }

    /// The key of a kind's last target; sign-out wipes it (`Wipe.defaultsKeys`).
    nonisolated static func defaultsKey(_ kind: MakeKind) -> String {
        Wipe.makeKey(kind)
    }

    private var remembered: MakeTarget? {
        context.defaults?.data(forKey: defaultsKey).flatMap { try? JSONDecoder().decode(MakeTarget.self, from: $0) }
    }

    func remember() {
        if kind == .brief, let classLevel,
           let data = try? JSONEncoder().encode(BriefDefaults(level: classLevel, subject: subject)) {
            context.defaults?.set(data, forKey: briefKey)
        }
        let kept = usesStudent ? studentID.map(MakeTarget.student) : target
        guard let kept, let data = try? JSONEncoder().encode(kept) else { return }
        context.defaults?.set(data, forKey: defaultsKey)
    }

    /// The mock and the note are for one student, chosen on their own tile rather than For.
    private var usesStudent: Bool {
        kind == .mock || kind == .noteToParent
    }

    /// The brief has no target: its last class and subject, as V1's forms keep theirs.
    private struct BriefDefaults: Codable {
        let level: ClassLevel
        let subject: String
    }

    nonisolated static let briefKey = Wipe.makeBriefKey

    private var briefKey: String {
        Self.briefKey
    }

    private var rememberedBrief: BriefDefaults? {
        context.defaults?.data(forKey: briefKey).flatMap { try? JSONDecoder().decode(BriefDefaults.self, from: $0) }
    }

    private func stands(_ target: MakeTarget) -> Bool {
        switch target {
        case let .student(id): context.register.student(id) != nil
        case let .group(plan, number): groups.contains { $0.planID == plan && $0.group.number == number }
        case let .batch(id): context.register.classroom(id) != nil
        case .classLevel: true
        }
    }
}
