import Foundation

/// One row read from a register photo, as the tutor checks it before anything is saved (P6-Scan-Review).
public struct ScanRow: Hashable, Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var phone: PhoneNumber?
    public var fee: Money?
    public var parentName: String
    public var included: Bool
    public var flag: ScanRowFlag?
    /// A class chosen for this row in Fix this row; nil follows the list's "Add to".
    public var classID: UUID?

    public init(
        id: UUID, name: String, phone: PhoneNumber?, fee: Money?, parentName: String, included: Bool,
        flag: ScanRowFlag?,
        classID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.fee = fee
        self.parentName = parentName
        self.included = included
        self.flag = flag
        self.classID = classID
    }

    /// "+91 98765 43210 · ₹1,200", "No number read · ₹1,200", "+91 98765 43210 · class fee".
    public var line: String {
        "\(phone?.display ?? "No number read") · \(fee?.formatted ?? "class fee")"
    }

    /// The student it becomes: a fee read from the page is their own; none means the class fee.
    public func draft(classID: UUID?) -> StudentDraft {
        var draft = StudentDraft()
        draft.name = name
        draft.classID = self.classID ?? classID
        draft.fee = fee
        draft.parentName = parentName
        draft.parentDigits = phone?.nationalDigits ?? ""
        return draft
    }
}

public enum ScanRowFlag: Hashable, Sendable {
    case alreadyHere(name: String, className: String?)
    case noNumber

    /// The compact chip beside the name.
    public var chip: String? {
        switch self {
        case .alreadyHere: "Already here"
        case .noNumber: nil
        }
    }

    /// The row's line in place of the number.
    public var line: String {
        switch self {
        case let .alreadyHere(name, className): className.map { "Matches \(name) in \($0)" } ?? "Matches \(name)"
        case .noNumber: "No number read"
        }
    }
}

/// The rules of the list to check: duplicates against the register and the words that count.
public enum ScanReview {
    /// A row that matches an active student by phone, or by name with case, spaces and accents folded, is flagged and
    /// unticked; a row without a number is flagged and stays ticked (it is saved without one).
    public static func flag(_ rows: [ScanRow], against students: [Student], classes: [Classroom]) -> [ScanRow] {
        let active = students.filter { !$0.isArchived }
        let byPhone = Dictionary(active.compactMap { student in
            student.parentPhone.map { ($0.e164, student) }
        }) { first, _ in first }
        let byName = Dictionary(active.map { (folded($0.name), $0) }) { first, _ in first }
        let classNames = Dictionary(classes.map { ($0.id, $0.name) }) { first, _ in first }
        return rows.map { row in
            var flagged = row
            let match = row.phone.flatMap { byPhone[$0.e164] } ?? byName[folded(row.name)]
            if let match {
                flagged.flag = .alreadyHere(name: match.name, className: match.classID.flatMap { classNames[$0] })
            } else {
                flagged.flag = row.phone == nil ? .noNumber : nil
            }
            flagged.included = flagged.flag == nil || flagged.flag == .noNumber
            return flagged
        }
    }

    /// Lower-cased, accents stripped, spaces collapsed.
    public static func folded(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_IN"))
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    public static func title(found: Int) -> String {
        "\(found) found"
    }

    public static func addLabel(ticked: Int) -> String {
        switch ticked {
        case 0: "Nothing to add"
        case 1: "Add 1 student"
        default: "Add \(ticked) students"
        }
    }

    public static func addedToast(count: Int) -> String {
        "\(count == 1 ? "1 student" : "\(count) students") added from the register."
    }
}
