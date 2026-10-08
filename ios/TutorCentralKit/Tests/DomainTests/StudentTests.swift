import Foundation
import Testing
@testable import Domain

struct StudentTests {
    static func student(
        _ name: String,
        fee: Money? = nil,
        classID: UUID? = nil,
        thisMonth: MonthFee? = nil,
        archived: Bool = false
    ) -> Student {
        Student(
            id: UUID(), name: name, classID: classID, monthlyFee: fee, parentName: "Parent",
            parentPhone: PhoneNumber(e164: "+919799113211"),
            dateOfBirth: nil, gender: nil, notes: nil, archivedAt: archived ? Date() : nil, thisMonth: thisMonth
        )
    }

    @Test func theFeeIsTheirOwnElseTheClassesElseNothing() {
        let maths = ClassroomTests.maths
        #expect(Self.student("Akshita Rao").fee(in: maths) == Money(rupees: 1200))
        #expect(Self.student("Riya Sharma", fee: Money(rupees: 1500)).fee(in: maths) == Money(rupees: 1500))
        #expect(Self.student("Sahil Verma").fee(in: nil) == nil)
        #expect(Self.student("Sahil Verma", fee: Money(rupees: 800)).fee(in: nil) == Money(rupees: 800))
    }

    @Test func thisMonthsMarkInTheBoardsWords() throws {
        let paid = MonthFee(
            amount: Money(rupees: 1200),
            status: .paid,
            paidOn: Day(year: 2026, month: 10, day: 4),
            paidMethod: .upi
        )
        #expect(try Self.student("A", thisMonth: paid).feeMark == .paid(on: #require(Day(
            year: 2026,
            month: 10,
            day: 4
        ))))
        #expect(try FeeMark.paid(on: #require(Day(year: 2026, month: 10, day: 4))).text == "Paid 4 Oct")
        #expect(Self.student("B", thisMonth: MonthFee(amount: .zero, status: .due, paidOn: nil)).feeMark?.text == "Due")
        #expect(Self.student("C", thisMonth: MonthFee(amount: .zero, status: .waived, paidOn: nil)).feeMark?
            .text == "Waived")
        #expect(Self.student("D").feeMark == nil)
    }

    @Test func initialsAndFirstName() {
        #expect(Self.student("Bir Bikram Singh").initials == "BB" && Self.student("Bir Bikram Singh")
            .firstName == "Bir")
        #expect(Self.student("Dev").firstName == "Dev" && Self.student("Akshita Rao").isArchived == false)
    }
}
