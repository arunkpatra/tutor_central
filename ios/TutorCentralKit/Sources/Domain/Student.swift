import Foundation

/// A student of the centre (`students`), with this month's invoice when there is one.
public struct Student: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var classID: UUID?
    /// nil means "the class fee" (`fee(in:)`).
    public var monthlyFee: Money?
    public var parentName: String?
    public var parentPhone: PhoneNumber?
    public var dateOfBirth: Day?
    public var gender: Gender?
    public var notes: String?
    public var archivedAt: Date?
    public var thisMonth: MonthFee?

    public init(
        id: UUID, name: String, classID: UUID?, monthlyFee: Money?, parentName: String?, parentPhone: PhoneNumber?,
        dateOfBirth: Day?, gender: Gender?, notes: String?, archivedAt: Date?, thisMonth: MonthFee?
    ) {
        self.id = id
        self.name = name
        self.classID = classID
        self.monthlyFee = monthlyFee
        self.parentName = parentName
        self.parentPhone = parentPhone
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.notes = notes
        self.archivedAt = archivedAt
        self.thisMonth = thisMonth
    }

    public var isArchived: Bool {
        archivedAt != nil
    }

    public var initials: String {
        NameInitials.of(name)
    }

    public var firstName: String {
        name.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? name
    }

    /// Their own fee, else the class's (the fee prefill rule), else nothing.
    public func fee(in classroom: Classroom?) -> Money? {
        monthlyFee ?? classroom?.monthlyFee
    }

    public var feeMark: FeeMark? {
        guard let thisMonth else { return nil }
        switch thisMonth.status {
        case .paid: return thisMonth.paidOn.map { .paid(on: $0) } ?? .due
        case .due: return .due
        case .waived: return .waived
        }
    }
}
