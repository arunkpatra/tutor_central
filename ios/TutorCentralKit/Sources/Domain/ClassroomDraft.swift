/// What the class form holds and checks before it saves (the New class and Edit class boards).
public struct ClassroomDraft: Hashable, Sendable {
    public var name = ""
    public var subject = ""
    public var fee: Money?
    public var meetingDays: Set<Weekday> = []
    public var startTime: TimeOfDay?
    public var endTime: TimeOfDay?

    public static let nameLimit = 80
    public static let feeCeiling = Money(rupees: 100_000)

    public enum Problem: Hashable, Sendable {
        case nameMissing, nameTooLong, feeTooHigh, endNotAfterStart

        public var message: String {
            switch self {
            case .nameMissing: "A class needs a name."
            case .nameTooLong: "Keep the name under 80 characters."
            case .feeTooHigh: "That's more than ₹1,00,000. Check the amount."
            case .endNotAfterStart: "The class has to end after it starts."
            }
        }
    }

    public init() {}

    public init(_ classroom: Classroom) {
        name = classroom.name
        subject = classroom.subject ?? ""
        fee = classroom.monthlyFee
        meetingDays = classroom.meetingDays
        startTime = classroom.startTime
        endTime = classroom.endTime
    }

    public var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var trimmedSubject: String? {
        let trimmed = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public var problems: Set<Problem> {
        var found = Set<Problem>()
        if trimmedName.isEmpty {
            found.insert(.nameMissing)
        }
        if trimmedName.count > Self.nameLimit {
            found.insert(.nameTooLong)
        }
        if let fee, fee > Self.feeCeiling {
            found.insert(.feeTooHigh)
        }
        if let startTime, let endTime, endTime <= startTime {
            found.insert(.endNotAfterStart)
        }
        return found
    }

    public var isValid: Bool {
        problems.isEmpty
    }
}
