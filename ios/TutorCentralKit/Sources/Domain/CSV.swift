import Foundation

/// A spreadsheet file (RFC 4180): quoted where a field needs it, CRLF line ends, a UTF-8 BOM so Numbers and Excel
/// read ₹ and names right (P5-Reports-Export).
public enum CSV {
    public static func make(header: [String], rows: [[String]]) -> String {
        let lines = ([header] + rows).map { $0.map(field).joined(separator: ",") }
        return "\u{FEFF}" + lines.map { $0 + "\r\n" }.joined()
    }

    static func field(_ text: String) -> String {
        guard text.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return text }
        return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// One line of the fees file: student, class, amount, status, paid on, paid by, reminded on.
public struct FeesCSVRow: Hashable, Sendable {
    public let student: String
    public let className: String
    public let amount: Money
    public let state: FeeState
    public let paidOn: Day?
    public let paidBy: MonthFee.PaidMethod?
    public let remindedOn: Day?

    public init(
        student: String,
        className: String,
        amount: Money,
        state: FeeState,
        paidOn: Day?,
        paidBy: MonthFee.PaidMethod?,
        remindedOn: Day?
    ) {
        self.student = student
        self.className = className
        self.amount = amount
        self.state = state
        self.paidOn = paidOn
        self.paidBy = paidBy
        self.remindedOn = remindedOn
    }
}

public enum FeesCSV {
    public static let header = ["Student", "Class", "Amount", "Status", "Paid on", "Paid by", "Reminded on"]

    public static func fileName(_ month: Period) -> String {
        "fees-\(month.isoDay.prefix(7)).csv"
    }

    public static func make(_ rows: [FeesCSVRow]) -> String {
        CSV.make(header: header, rows: rows.map { row in
            [
                row.student,
                row.className,
                "\(row.amount.rupees)",
                row.state.word,
                row.paidOn?.iso ?? "",
                row.paidBy.map(method) ?? "",
                row.remindedOn?.iso ?? "",
            ]
        })
    }

    private static func method(_ method: MonthFee.PaidMethod) -> String {
        switch method {
        case .upi: "UPI"
        case .cash: "Cash"
        case .other: "Other"
        }
    }
}

/// One line of the attendance file: student, class, present, absent, percentage.
public struct AttendanceCSVRow: Hashable, Sendable {
    public let student: String
    public let className: String
    public let present: Int
    public let absent: Int

    public init(student: String, className: String, present: Int, absent: Int) {
        self.student = student
        self.className = className
        self.present = present
        self.absent = absent
    }

    /// Nil when nothing was marked: never 0% for an unmarked month.
    public var percentage: Int? {
        let total = present + absent
        return total == 0 ? nil : Int((Double(present) * 100 / Double(total)).rounded())
    }
}

public enum AttendanceCSV {
    public static let header = ["Student", "Class", "Present", "Absent", "Percentage"]

    public static func fileName(_ month: Period) -> String {
        "attendance-\(month.isoDay.prefix(7)).csv"
    }

    public static func make(_ rows: [AttendanceCSVRow]) -> String {
        CSV.make(header: header, rows: rows.map { row in
            [row.student, row.className, "\(row.present)", "\(row.absent)", row.percentage.map { "\($0)" } ?? ""]
        })
    }
}
