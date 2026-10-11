import Data
import Domain
import Foundation
import Observation

/// One row of the For sheet: a school's class with its students, a school's every class, or one student.
public struct ForOption: Identifiable, Hashable, Sendable {
    public var id: String {
        switch audience {
        case let .student(id): "s-\(id)"
        case let .schoolClass(school, level): "c-\(school)-\(level.rawValue)"
        case let .school(school): "a-\(school)"
        }
    }

    /// The school's name above its rows ("" for a student).
    public let group: String
    public let title: String
    public let line: String?
    public let audience: ItemAudience
}

/// The item's sheet (P10-School-Confirm-Edit; plan/phase-13-plan.md decision 6): Kind, Title, For, Subject, Date (and
/// To
/// for a holiday), Portions held to 500. Save needs a kind, a title, who it is for and a date; an exam a subject too.
@MainActor @Observable public final class ItemFormStore: Identifiable {
    public nonisolated let id = UUID()
    public var kind: SchoolItemKind
    public var title: String
    public var audience: ItemAudience?
    public var subject: String?
    public var date: Day?
    public var endDate: Day?
    public var portions: String
    private let draftID: UUID
    private let sourceText: String?
    private let source: SchoolItemSource
    private let receivedAt: Date?
    let students: [Student]
    let schools: [School]
    let today: Day

    /// The day picker opened: it chooses the day it shows (today) when none is chosen, so tapping today needs no
    /// other day first (hand run 7).
    public func openDay() {
        date = date ?? today
    }

    /// The To picker opened: it starts on the From day.
    public func openEndDay() {
        endDate = endDate ?? date ?? today
    }

    public init(draft: SchoolItemDraft?, students: [Student], schools: [School], today: Day) {
        kind = draft?.kind ?? .exam
        title = draft?.title ?? ""
        audience = draft?.audience
        subject = draft?.subject
        date = draft?.date
        endDate = draft?.endDate
        portions = draft?.portions ?? ""
        draftID = draft?.id ?? UUID()
        sourceText = draft?.sourceText
        source = draft?.source ?? .typed
        receivedAt = draft?.receivedAt
        self.students = students
        self.schools = schools
        self.today = today
    }

    /// The form of a kept item (Edit on its page).
    public convenience init(item: SchoolItem, students: [Student], schools: [School], today: Day) {
        let draft = SchoolItemDraft(
            id: item.id, kind: item.kind, audience: item.audience, title: item.title, subject: item.subject,
            date: item.date, endDate: item.endDate, portions: item.portions, sourceText: item.sourceText,
            source: item.source
        )
        self.init(draft: draft, students: students, schools: schools, today: today)
    }

    /// "54 of 500".
    public var counter: String {
        "\(portions.unicodeScalars.count) of \(SchoolItemRules.portionsLimit)"
    }

    private var endProblem: Bool {
        guard kind == .holiday, let endDate, let date else { return false }
        return endDate < date
    }

    public var canSave: Bool {
        draft().isComplete && !endProblem
    }

    /// The form as a draft, ticked when complete.
    public func draft() -> SchoolItemDraft {
        let trimmed = portions.trimmingCharacters(in: .whitespacesAndNewlines)
        let subjectWords = subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        var draft = SchoolItemDraft(
            id: draftID, kind: kind, audience: audience, title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            subject: subjectWords?.isEmpty == false ? subjectWords : nil, date: date,
            endDate: kind == .holiday ? endDate : nil, portions: trimmed.isEmpty ? nil : trimmed,
            sourceText: sourceText, source: source
        )
        draft.ticked = draft.isComplete && !endProblem
        draft.receivedAt = receivedAt
        return draft
    }

    /// A kept item with the form's changes.
    public func item(from existing: SchoolItem) -> SchoolItem {
        let draft = draft()
        var item = existing
        item.kind = draft.kind
        item.title = draft.title
        if let audience = draft.audience {
            item.audience = audience
        }
        item.subject = draft.subject
        if let date = draft.date {
            item.date = date
        }
        item.endDate = draft.endDate
        item.portions = draft.portions
        return item
    }

    // MARK: - For

    /// Each school's classes with their students, then every class at it; then the students.
    public var forOptions: [ForOption] {
        let active = students.filter { $0.archivedAt == nil }
        var options: [ForOption] = []
        for school in schools.sorted(by: { $0.name < $1.name }) {
            let theirs = active.filter { $0.schoolID == school.id }
            for level in Set(theirs.compactMap(\.classLevel)).sorted() {
                let names = theirs.filter { $0.classLevel == level }.map(\.firstName).sorted()
                options.append(ForOption(
                    group: school.name, title: level.title, line: ListWordsBridge.and(names),
                    audience: .schoolClass(school: school.id, level: level)
                ))
            }
            options.append(ForOption(group: school.name, title: "Every class", line: nil, audience: .school(school.id)))
        }
        options += active.sorted { $0.name < $1.name }.map {
            ForOption(group: "", title: $0.name, line: $0.classTitle, audience: .student($0.id))
        }
        return options
    }

    /// The For tile's value: "Class 8 at Vidya Niketan", "Vidya Niketan, every class", a student's name; "Choose".
    public var forValue: String {
        switch audience {
        case nil: "Choose"
        case let .schoolClass(school, level): "\(level.title) at \(schoolName(school))"
        case let .school(school): "\(schoolName(school)), every class"
        case let .student(id): students.first { $0.id == id }?.name ?? "Choose"
        }
    }

    /// "Dev, Meher and Nikhil are in class 8 there. Or one student."
    public var forNote: String? {
        guard case let .schoolClass(school, level) = audience else { return nil }
        let names = students.filter { $0.archivedAt == nil && $0.schoolID == school && $0.classLevel == level }
            .map(\.firstName).sorted()
        guard !names.isEmpty else { return "No one in \(level.title.lowercased()) there yet. Or one student." }
        let verb = names.count == 1 ? "is" : "are"
        return "\(ListWordsBridge.and(names)) \(verb) in \(level.title.lowercased()) there. Or one student."
    }

    private func schoolName(_ id: UUID) -> String {
        schools.first { $0.id == id }?.name ?? "A school"
    }
}

/// "a", "a and b", "a, b and c" (Domain's list words are internal to it).
enum ListWordsBridge {
    static func and(_ words: [String]) -> String {
        guard let last = words.last, words.count > 1 else { return words.first ?? "" }
        return "\(words.dropLast().joined(separator: ", ")) and \(last)"
    }
}
