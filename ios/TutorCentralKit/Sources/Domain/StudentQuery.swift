import Foundation

public enum StudentSort: String, CaseIterable, Hashable, Sendable {
    case status, name, fee

    public var label: String {
        switch self {
        case .status: "Status"
        case .name: "Name"
        case .fee: "Fee"
        }
    }
}

public enum StudentFilter: Hashable, Sendable {
    case all
    case classroom(UUID)
    case unassigned
    case archived
}

/// The register as the Students list shows it: a search over names and numbers across everyone, then the filter (All
/// hides the archived), then the sort.
public enum StudentQuery {
    public static func apply(
        _ students: [Student], classes: [Classroom], search: String, filter: StudentFilter, sort: StudentSort
    ) -> [Student] {
        let byID = Dictionary(uniqueKeysWithValues: classes.map { ($0.id, $0) })
        let searching = !normalised(search).isEmpty
        let kept = students.filter { student in
            if searching {
                return matches(student, search: search)
            }
            switch filter {
            case .all: return !student.isArchived
            case let .classroom(id): return !student.isArchived && student.classID == id
            case .unassigned: return !student.isArchived && student.classID == nil
            case .archived: return student.isArchived
            }
        }
        return kept.sorted { lhs, rhs in
            switch sort {
            case .status:
                return lhs.trackStatus != rhs.trackStatus ? lhs.trackStatus < rhs.trackStatus : lhs.name
                    .localizedStandardCompare(rhs.name) == .orderedAscending
            case .name: return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .fee:
                let lhsFee = lhs.fee(in: lhs.classID.flatMap { byID[$0] }) ?? .zero
                let rhsFee = rhs.fee(in: rhs.classID.flatMap { byID[$0] }) ?? .zero
                return lhsFee != rhsFee ? lhsFee > rhsFee : lhs.name
                    .localizedStandardCompare(rhs.name) == .orderedAscending
            }
        }
    }

    public static func matches(_ student: Student, search: String) -> Bool {
        matchRange(in: student.name, search: search) != nil || matchesPhone(student, search: search)
    }

    /// The typed digits (any +91, 0, spaces dropped) as a substring of the parent's national number.
    public static func matchesPhone(_ student: Student, search: String) -> Bool {
        var typed = Substring(normalised(search))
        if typed.hasPrefix("+91") {
            typed = typed.dropFirst(3)
        }
        let digits = typed.filter { $0.isASCII && $0.isNumber }
        guard digits.count >= 3, let phone = student.parentPhone else { return false }
        var wanted = Substring(digits)
        if wanted.hasPrefix("91"), wanted.count > 10 {
            wanted = wanted.dropFirst(2)
        }
        if wanted.hasPrefix("0"), wanted.count > 10 {
            wanted = wanted.dropFirst()
        }
        return phone.nationalDigits.contains(wanted)
    }

    /// Where the search sits in the text, case and accents ignored, so the row can colour the letters that matched.
    public static func matchRange(in text: String, search: String) -> Range<String.Index>? {
        let query = normalised(search)
        guard !query.isEmpty else { return nil }
        return text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive])
    }

    private static func normalised(_ search: String) -> String {
        search.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
