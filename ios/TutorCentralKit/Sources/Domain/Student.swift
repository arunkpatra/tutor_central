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
    // V2 (migration 0009): the record. A V1 student has none of these set.
    public var classLevel: ClassLevel?
    public var schoolID: UUID?
    /// Kept from class 8 (`ClassLevel.expectsBoard`).
    public var board: Board?
    public var messageLanguage: MessageLanguage
    public var consent: ConsentRecord?
    public var trackStatus: TrackStatus
    /// The fired rules' sentences, stored at the close (`TrackingRules`).
    public var trackReasons: [String]
    public var trackSince: Date?

    public init(
        id: UUID, name: String, classID: UUID?, monthlyFee: Money?, parentName: String?, parentPhone: PhoneNumber?,
        dateOfBirth: Day?, gender: Gender?, notes: String?, archivedAt: Date?, thisMonth: MonthFee?,
        classLevel: ClassLevel? = nil, schoolID: UUID? = nil, board: Board? = nil,
        messageLanguage: MessageLanguage = .default, consent: ConsentRecord? = nil,
        trackStatus: TrackStatus = .notKnown, trackReasons: [String] = [], trackSince: Date? = nil
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
        self.classLevel = classLevel
        self.schoolID = schoolID
        self.board = board
        self.messageLanguage = messageLanguage
        self.consent = consent
        self.trackStatus = trackStatus
        self.trackReasons = trackReasons
        self.trackSince = trackSince
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, classID, monthlyFee, parentName, parentPhone, dateOfBirth, gender, notes, archivedAt, thisMonth
        case classLevel, schoolID, board, messageLanguage, consent, trackStatus, trackReasons, trackSince
    }

    /// A register cached by a build before V2 has none of the V2 keys: they read as a V1 student's.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: c.decode(UUID.self, forKey: .id),
            name: c.decode(String.self, forKey: .name),
            classID: c.decodeIfPresent(UUID.self, forKey: .classID),
            monthlyFee: c.decodeIfPresent(Money.self, forKey: .monthlyFee),
            parentName: c.decodeIfPresent(String.self, forKey: .parentName),
            parentPhone: c.decodeIfPresent(PhoneNumber.self, forKey: .parentPhone),
            dateOfBirth: c.decodeIfPresent(Day.self, forKey: .dateOfBirth),
            gender: c.decodeIfPresent(Gender.self, forKey: .gender),
            notes: c.decodeIfPresent(String.self, forKey: .notes),
            archivedAt: c.decodeIfPresent(Date.self, forKey: .archivedAt),
            thisMonth: c.decodeIfPresent(MonthFee.self, forKey: .thisMonth),
            classLevel: c.decodeIfPresent(ClassLevel.self, forKey: .classLevel),
            schoolID: c.decodeIfPresent(UUID.self, forKey: .schoolID),
            board: c.decodeIfPresent(Board.self, forKey: .board),
            messageLanguage: c.decodeIfPresent(MessageLanguage.self, forKey: .messageLanguage) ?? .default,
            consent: c.decodeIfPresent(ConsentRecord.self, forKey: .consent),
            trackStatus: c.decodeIfPresent(TrackStatus.self, forKey: .trackStatus) ?? .notKnown,
            trackReasons: c.decodeIfPresent([String].self, forKey: .trackReasons) ?? [],
            trackSince: c.decodeIfPresent(Date.self, forKey: .trackSince)
        )
    }

    /// "Class 10", "LKG"; nil for a student without a class level.
    public var classTitle: String? {
        classLevel?.title
    }

    /// The Board row and chip show from class 8.
    public var showsBoard: Bool {
        classLevel?.expectsBoard == true
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
