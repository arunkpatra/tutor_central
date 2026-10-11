import Data
import Domain
import Foundation

/// What the parser read, resolved to the centre (plan/phase-13-plan.md decision 2): a named student to that student
/// (the whole name, else a first name only one student has), a named school to that school (by its name, ignoring
/// case),
/// the class at it; with no school named, the one school the class's students go to. Else nil: the For tile reads
/// "Choose".
enum DraftResolver {
    static func resolve(
        _ parsed: ParsedItem,
        source: ReadSource,
        schools: [School],
        students: [Student]
    ) -> SchoolItemDraft {
        var draft = SchoolItemDraft(
            kind: parsed.kind, audience: audience(parsed, schools: schools, students: students),
            title: String(parsed.title.unicodeScalars.prefix(SchoolItemRules.titleLimit)), subject: parsed.subject,
            date: parsed.date, endDate: parsed.kind == .holiday ? parsed.endDate : nil, portions: parsed.portions,
            sourceText: sourceText(source), source: itemSource(source)
        )
        if case let .shared(read) = source {
            draft.receivedAt = read.receivedAt
        }
        return draft
    }

    static func audience(_ parsed: ParsedItem, schools: [School], students: [Student]) -> ItemAudience? {
        if let name = parsed.studentName {
            return student(named: name, in: students).map { .student($0.id) }
        }
        let school = parsed.school.flatMap { named in
            schools.first { $0.name.caseInsensitiveCompare(named) == .orderedSame }
                ?? schools
                .first {
                    named.localizedCaseInsensitiveContains($0.name) || $0.name.localizedCaseInsensitiveContains(named)
                }
        }
        if let school {
            return parsed.classLevel.map { .schoolClass(school: school.id, level: $0) } ?? .school(school.id)
        }
        guard let level = parsed.classLevel else { return nil }
        let theirs = Set(students.filter { $0.classLevel == level }.compactMap(\.schoolID))
        guard theirs.count == 1, let only = theirs.first else { return nil }
        return .schoolClass(school: only, level: level)
    }

    private static func student(named name: String, in students: [Student]) -> Student? {
        let wanted = name.trimmingCharacters(in: .whitespaces)
        if let whole = students.first(where: { $0.name.caseInsensitiveCompare(wanted) == .orderedSame }) {
            return whole
        }
        let first = wanted.split(separator: " ").first.map(String.init) ?? wanted
        let matching = students.filter { $0.firstName.caseInsensitiveCompare(first) == .orderedSame }
        return wanted.split(separator: " ").count == 1 && matching.count == 1 ? matching.first : nil
    }

    private static func itemSource(_ source: ReadSource) -> SchoolItemSource {
        switch source {
        case .photo: .photo
        case .pasted: .pasted
        case .typed: .typed
        case let .shared(read): read.image == nil ? .sharedText : .sharedPhoto
        }
    }

    private static func sourceText(_ source: ReadSource) -> String? {
        switch source {
        case let .pasted(text): String(text.prefix(4000))
        case let .shared(read): read.text.map { String($0.prefix(4000)) }
        case .photo, .typed: nil
        }
    }
}
