import Foundation
import Testing
@testable import Domain

struct CSVTests {
    @Test func namesWithCommasAndQuotesAreEscaped() {
        let text = CSV.make(header: ["A", "B"], rows: [["Singh, Bir", "He said \"hi\""], ["plain", "two\nlines"]])
        #expect(text == "\u{FEFF}A,B\r\n\"Singh, Bir\",\"He said \"\"hi\"\"\"\r\nplain,\"two\nlines\"\r\n")
    }

    @Test func theFeesFileHasTheColumnsOfTheBoard() throws {
        let day = try #require(Day(year: 2026, month: 10, day: 4))
        let rows = [
            FeesCSVRow(
                student: "Akshita Rao", className: "Class 10 Maths", amount: Money(rupees: 1200), state: .paid,
                paidOn: day, paidBy: .upi, remindedOn: nil
            ),
            FeesCSVRow(
                student: "Dev Kumar", className: "Class 8 Science", amount: Money(rupees: 1000), state: .due,
                paidOn: nil, paidBy: nil, remindedOn: Day(year: 2026, month: 10, day: 6)
            ),
            FeesCSVRow(
                student: "Sahil Verma", className: "", amount: Money(rupees: 800), state: .waived, paidOn: nil,
                paidBy: nil, remindedOn: nil
            ),
        ]
        #expect(FeesCSV.make(rows) == "\u{FEFF}Student,Class,Amount,Status,Paid on,Paid by,Reminded on\r\n"
            + "Akshita Rao,Class 10 Maths,1200,Paid,2026-10-04,UPI,\r\n"
            + "Dev Kumar,Class 8 Science,1000,Due,,,2026-10-06\r\n"
            + "Sahil Verma,,800,Waived,,,\r\n")
        #expect(FeesCSV.fileName(Period(year: 2026, month: 10)) == "fees-2026-10.csv")
    }

    @Test func theAttendanceFileCountsAndPercents() {
        let rows = [
            AttendanceCSVRow(student: "Hemanth Reddy", className: "Class 10 Maths", present: 1, absent: 2),
            AttendanceCSVRow(student: "Sahil Verma", className: "", present: 0, absent: 0),
        ]
        #expect(rows[0].percentage == 33 && rows[1].percentage == nil)
        #expect(AttendanceCSV.make(rows) == "\u{FEFF}Student,Class,Present,Absent,Percentage\r\n"
            + "Hemanth Reddy,Class 10 Maths,1,2,33\r\nSahil Verma,,0,0,\r\n")
        #expect(AttendanceCSV.fileName(Period(year: 2026, month: 10)) == "attendance-2026-10.csv")
    }
}
