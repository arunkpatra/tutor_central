import Domain
import Foundation

/// A `school_items` row. Who it is for is three columns: a student; a school and a class; a school alone.
struct SchoolItemRow: Decodable {
    let id: UUID
    let kind: String
    let schoolId: UUID?
    let studentId: UUID?
    let classLevel: String?
    let title: String
    let subject: String?
    let date: String
    let endDate: String?
    let portions: String?
    let sourceText: String?
    let photoPath: String?
    let source: String
    let receivedAt: Date
    let confirmedAt: Date?

    static let columns = "id, kind, school_id, student_id, class_level, title, subject, date, end_date, portions, "
        + "source_text, photo_path, source, received_at, confirmed_at"

    /// Nil for a kind this build does not know, or an item whose school has gone (no one to reach).
    var item: SchoolItem? {
        guard let kind = SchoolItemKind(rawValue: kind), let day = Day(iso: date), let audience else { return nil }
        return SchoolItem(
            id: id, kind: kind, audience: audience, title: title, subject: subject, date: day,
            endDate: endDate.flatMap(Day.init(iso:)), portions: portions, sourceText: sourceText, photoPath: photoPath,
            source: SchoolItemSource(rawValue: source) ?? .typed, receivedAt: receivedAt, confirmedAt: confirmedAt
        )
    }

    private var audience: ItemAudience? {
        if let studentId {
            return .student(studentId)
        }
        guard let schoolId else { return nil }
        return classLevel.flatMap(ClassLevel.init(rawValue:)).map { .schoolClass(school: schoolId, level: $0) }
            ?? .school(schoolId)
    }
}

/// The columns an item writes; who it is for as its three columns, each written so an edit clears the others.
struct SchoolItemWrite: Encodable {
    let centreId: UUID?
    let kind: String
    let schoolId: UUID?
    let studentId: UUID?
    let classLevel: String?
    let title: String
    let subject: String?
    let date: String
    let endDate: String?
    let portions: String?
    let sourceText: String?
    let photoPath: String?
    let source: String
    let confirmedAt: Date?
    var receivedAt: Date?

    init(draft: SchoolItemDraft, photoPath: String?, centre: UUID, confirmedAt: Date) {
        let columns = Self.columns(draft.audience)
        centreId = centre
        kind = draft.kind.rawValue
        schoolId = columns.school
        studentId = columns.student
        classLevel = columns.level
        title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        subject = draft.subject
        date = draft.date?.iso ?? ""
        endDate = draft.kind == .holiday ? draft.endDate?.iso : nil
        portions = draft.portions
        sourceText = draft.sourceText
        self.photoPath = photoPath
        source = draft.source.rawValue
        self.confirmedAt = confirmedAt
        receivedAt = draft.receivedAt
    }

    /// An edit: the item's own columns, its centre and confirmation left as they are.
    init(item: SchoolItem) {
        let columns = Self.columns(item.audience)
        centreId = nil
        kind = item.kind.rawValue
        schoolId = columns.school
        studentId = columns.student
        classLevel = columns.level
        title = item.title
        subject = item.subject
        date = item.date.iso
        endDate = item.kind == .holiday ? item.endDate?.iso : nil
        portions = item.portions
        sourceText = item.sourceText
        photoPath = item.photoPath
        source = item.source.rawValue
        confirmedAt = nil
    }

    private struct Columns {
        var school: UUID?
        var student: UUID?
        var level: String?
    }

    private static func columns(_ audience: ItemAudience?) -> Columns {
        switch audience {
        case let .student(id): Columns(student: id)
        case let .schoolClass(school, level): Columns(school: school, level: level.rawValue)
        case let .school(school): Columns(school: school)
        case nil: Columns()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case centreId = "centre_id", kind, schoolId = "school_id", studentId = "student_id", classLevel = "class_level"
        case title, subject, date, endDate = "end_date", portions, sourceText = "source_text", photoPath = "photo_path"
        case source, confirmedAt = "confirmed_at", receivedAt = "received_at"
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let centreId {
            try c.encode(centreId.uuidString.lowercased(), forKey: .centreId)
        }
        try c.encode(kind, forKey: .kind)
        try c.encode(schoolId?.uuidString.lowercased(), forKey: .schoolId)
        try c.encode(studentId?.uuidString.lowercased(), forKey: .studentId)
        try c.encode(classLevel, forKey: .classLevel)
        try c.encode(title, forKey: .title)
        try c.encode(subject, forKey: .subject)
        try c.encode(date, forKey: .date)
        try c.encode(endDate, forKey: .endDate)
        try c.encode(portions, forKey: .portions)
        try c.encode(sourceText, forKey: .sourceText)
        try c.encode(photoPath, forKey: .photoPath)
        try c.encode(source, forKey: .source)
        if let confirmedAt {
            try c.encode(ISO8601DateFormatter().string(from: confirmedAt), forKey: .confirmedAt)
        }
        if let receivedAt {
            try c.encode(ISO8601DateFormatter().string(from: receivedAt), forKey: .receivedAt)
        }
    }
}
