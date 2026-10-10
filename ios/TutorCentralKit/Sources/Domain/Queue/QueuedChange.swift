import Foundation

/// A queued change's kind without its values: whether a new write of that kind must join the queue.
public enum QueuedChangeCase: Hashable, Sendable {
    case attendance, markPaid, absenceLog, close
}

/// A write made on this iPhone while offline (D39), waiting to reach the server: an attendance save, a Mark paid, the
/// absence alert's log, or a class's close (plan decision 18). It carries what the write needs and the names its row on
/// Pending changes reads.
public struct QueuedChange: Hashable, Sendable, Codable, Identifiable {
    public enum Kind: Hashable, Sendable, Codable {
        case attendance(
            classID: UUID?, className: String, date: Day, marks: [UUID: AttendanceStatus], present: Int, total: Int
        )
        case markPaid(
            invoiceID: UUID, studentName: String, month: Period, amount: Money, method: MonthFee.PaidMethod,
            paidAt: Date
        )
        case absenceLog(studentID: UUID, studentName: String, about: Day)
        case close(close: SessionClose, className: String, present: Int, total: Int)

        /// The kind without its values.
        public var `case`: QueuedChangeCase {
            switch self {
            case .attendance: .attendance
            case .markPaid: .markPaid
            case .absenceLog: .absenceLog
            case .close: .close
            }
        }
    }

    public enum State: Hashable, Sendable, Codable {
        case waiting
        case failed(reason: String)
    }

    public let id: UUID
    public let kind: Kind
    public let madeAt: Date
    public var state: State

    public init(id: UUID = UUID(), kind: Kind, madeAt: Date, state: State = .waiting) {
        self.id = id
        self.kind = kind
        self.madeAt = madeAt
        self.state = state
    }

    /// "Attendance · Class 10 Maths" / "Fee · Dev Kumar" / "Absence alert · Hemanth Reddy" / "Class closed · Evening
    /// batch".
    public var title: String {
        switch kind {
        case let .attendance(_, className, _, _, _, _): "Attendance · \(className)"
        case let .markPaid(_, studentName, _, _, _, _): "Fee · \(studentName)"
        case let .absenceLog(_, studentName, _): "Absence alert · \(studentName)"
        case let .close(_, className, _, _): "Class closed · \(className)"
        }
    }

    /// "Wed 7 Oct · 5 of 6 present · 17:05" / "₹1,000 by UPI on 7 Oct · 17:12" / "Wed 7 Oct · WhatsApp opened at
    /// 17:06": what was done and when it was made here.
    public func line(calendar: Calendar) -> String {
        let made = Self.clock(madeAt, calendar: calendar)
        switch kind {
        case let .attendance(_, _, date, _, present, total):
            return "\(date.shortWeekdayText) · \(present) of \(total) present · \(made)"
        case let .markPaid(_, _, _, amount, method, paidAt):
            return "\(amount.formatted) by \(method.label) on \(Day(paidAt, calendar: calendar).shortText) · \(made)"
        case let .absenceLog(_, _, about):
            return "\(about.shortWeekdayText) · WhatsApp opened at \(made)"
        case let .close(close, _, present, total):
            let checks: String? = switch close.checks.count {
            case 0: nil
            case 1: "1 check"
            default: "\(close.checks.count) checks"
            }
            return [close.date.shortWeekdayText, "\(present) of \(total) came", checks, made].compactMap(\.self)
                .joined(separator: " · ")
        }
    }

    /// For the sign-out dialog: "attendance for Class 10 Maths", "Dev's fee", "Hemanth's absence alert", "the close of
    /// Evening batch".
    public var shortName: String {
        switch kind {
        case let .attendance(_, className, _, _, _, _): "attendance for \(className)"
        case let .markPaid(_, studentName, _, _, _, _): "\(Self.firstName(studentName))'s fee"
        case let .absenceLog(_, studentName, _): "\(Self.firstName(studentName))'s absence alert"
        case let .close(_, className, _, _): "the close of \(className)"
        }
    }

    /// The text before the first space (`Student.firstName`'s rule).
    static func firstName(_ name: String) -> String {
        name.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? name
    }

    /// "17:05" in the calendar's zone; a formatter per call (D8).
    public static func clock(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
