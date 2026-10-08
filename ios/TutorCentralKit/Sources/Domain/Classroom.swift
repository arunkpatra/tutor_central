import Foundation

/// A class the tutor teaches (`classes`): its name, subject, fee, and when it meets. "Class" is the word on screen;
/// the type is `Classroom` so it never reads as the keyword.
public struct Classroom: Hashable, Sendable, Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var subject: String?
    public var monthlyFee: Money?
    public var meetingDays: Set<Weekday>
    public var startTime: TimeOfDay?
    public var endTime: TimeOfDay?
    public var archivedAt: Date?

    public init(
        id: UUID, name: String, subject: String?, monthlyFee: Money?, meetingDays: Set<Weekday>,
        startTime: TimeOfDay?, endTime: TimeOfDay?, archivedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.subject = subject
        self.monthlyFee = monthlyFee
        self.meetingDays = meetingDays
        self.startTime = startTime
        self.endTime = endTime
        self.archivedAt = archivedAt
    }

    public var isArchived: Bool {
        archivedAt != nil
    }

    /// "Mon, Wed, Fri"; "Every day"; "No days set".
    public var daysSummary: String {
        if meetingDays.count == Weekday.allCases.count {
            return "Every day"
        }
        if meetingDays.isEmpty {
            return "No days set"
        }
        return meetingDays.sorted().map(\.short).joined(separator: ", ")
    }

    /// "17:00–18:00"; the one time that is set; nil when neither is.
    public var timeRange: String? {
        switch (startTime, endTime) {
        case let (start?, end?): TimeOfDay.range(start, end)
        case let (start?, nil): start.text
        case let (nil, end?): end.text
        case (nil, nil): nil
        }
    }

    /// "Mon, Wed, Fri · 17:00–18:00" (the class row, the class detail header).
    public var meetingSummary: String {
        [daysSummary, timeRange].compactMap(\.self).joined(separator: " · ")
    }

    /// The days this class meets in the Monday-to-Sunday week that holds `day`, in order.
    public func meetings(inWeekOf day: Day, calendar: Calendar) -> [Day] {
        let monday = day.adding(days: -(day.weekday(in: calendar).rawValue - 1), calendar: calendar)
        return (0 ..< 7).map { monday.adding(days: $0, calendar: calendar) }
            .filter { meetingDays.contains($0.weekday(in: calendar)) }
    }
}
