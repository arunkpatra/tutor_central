import Foundation

/// What a school sent, as `school_items.kind` stores it (migration 0011).
public enum SchoolItemKind: String, CaseIterable, Hashable, Sendable, Codable {
    case exam, homework, notice, holiday

    /// The kind chip's words.
    public var title: String {
        switch self {
        case .exam: "Exam"
        case .homework: "Homework"
        case .notice: "Notice"
        case .holiday: "Holiday"
        }
    }
}

/// How an item reached the app (migration 0021): an extension sees no sender app, so a share is "Shared".
public enum SchoolItemSource: String, Hashable, Sendable, Codable {
    case sharedText = "shared_text", sharedPhoto = "shared_photo", photo, pasted, typed
}

/// Who an item is for (plan/phase-13-plan.md decision 2): one student, a school's class, or a school, every class.
public enum ItemAudience: Hashable, Sendable, Codable {
    case student(UUID)
    case schoolClass(school: UUID, level: ClassLevel)
    case school(UUID)
}

/// An item the tutor kept (`school_items`).
public struct SchoolItem: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var kind: SchoolItemKind
    public var audience: ItemAudience
    public var title: String
    public var subject: String?
    public var date: Day
    /// A holiday's last day.
    public var endDate: Day?
    public var portions: String?
    public var sourceText: String?
    public var photoPath: String?
    public var source: SchoolItemSource
    public var receivedAt: Date
    public var confirmedAt: Date?

    public init(
        id: UUID, kind: SchoolItemKind, audience: ItemAudience, title: String, subject: String?, date: Day,
        endDate: Day?, portions: String?, sourceText: String?, photoPath: String?, source: SchoolItemSource,
        receivedAt: Date, confirmedAt: Date?
    ) {
        self.id = id
        self.kind = kind
        self.audience = audience
        self.title = title
        self.subject = subject
        self.date = date
        self.endDate = endDate
        self.portions = portions
        self.sourceText = sourceText
        self.photoPath = photoPath
        self.source = source
        self.receivedAt = receivedAt
        self.confirmedAt = confirmedAt
    }

    /// The last day the item stands for: a holiday's end, else its day.
    public var lastDay: Day {
        max(endDate ?? date, date)
    }
}

/// An item before Add: what the parser read, or what the tutor typed (decision 1). It is complete with a kind, a title,
/// who it is for and a date (an exam a subject too), its title and portions within their limits.
public struct SchoolItemDraft: Hashable, Sendable, Identifiable {
    public enum Missing: Hashable, Sendable { case title, audience, date, subject, portions }

    public let id: UUID
    public var kind: SchoolItemKind
    public var audience: ItemAudience?
    public var title: String
    public var subject: String?
    public var date: Day?
    public var endDate: Day?
    public var portions: String?
    public var sourceText: String?
    public var source: SchoolItemSource
    public var ticked: Bool
    /// When a share reached the inbox (kept as the item's `received_at`); nil: when it is added.
    public var receivedAt: Date?

    public init(
        id: UUID = UUID(), kind: SchoolItemKind, audience: ItemAudience?, title: String, subject: String?, date: Day?,
        endDate: Day? = nil, portions: String? = nil, sourceText: String? = nil, source: SchoolItemSource,
        ticked: Bool? = nil
    ) {
        self.id = id
        self.kind = kind
        self.audience = audience
        self.title = title
        self.subject = subject
        self.date = date
        self.endDate = endDate
        self.portions = portions
        self.sourceText = sourceText
        self.source = source
        self.ticked = false
        self.ticked = ticked ?? isComplete
    }

    /// What it still needs, in the sheet's order.
    public var missing: [Missing] {
        var missing: [Missing] = []
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty || title.unicodeScalars.count > SchoolItemRules.titleLimit {
            missing.append(.title)
        }
        if audience == nil {
            missing.append(.audience)
        }
        if date == nil {
            missing.append(.date)
        }
        if kind == .exam, (subject ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append(.subject)
        }
        if (portions ?? "").unicodeScalars.count > SchoolItemRules.portionsLimit {
            missing.append(.portions)
        }
        return missing
    }

    public var isComplete: Bool {
        missing.isEmpty
    }
}
