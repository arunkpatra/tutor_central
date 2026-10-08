import Foundation
import Testing
@testable import Domain

struct FeeMessageTests {
    static let october = Period(year: 2026, month: 10)
    static func reminder(
        upi: String? = "meera@okhdfcbank",
        link: String? = nil,
        parent: String? = "Lakshmi Reddy"
    ) -> FeeMessage {
        FeeMessage(
            kind: .reminder, parentName: parent, studentName: "Hemanth Reddy", month: october,
            amount: Money(rupees: 1200),
            upiID: upi, paymentLink: link, tutorName: "Meera Nair", centreName: "Bright Minds Tuition"
        )
    }

    static func receipt(_ method: MonthFee.PaidMethod, parent: String?, tutor: String?) throws -> FeeMessage {
        let day = try #require(Day(year: 2026, month: 10, day: 7))
        return FeeMessage(
            kind: .receipt(method: method, day: day), parentName: parent, studentName: "Dev Kumar", month: october,
            amount: Money(rupees: 1000), upiID: nil, paymentLink: nil, tutorName: tutor,
            centreName: "Bright Minds Tuition"
        )
    }

    @Test func theReminderNamesEverything() {
        #expect(Self.reminder().text == """
        Hello Lakshmi, Hemanth's fee of ₹1,200 for October is due. You can pay by UPI to meera@okhdfcbank. Thank you.

        Meera Nair
        Bright Minds Tuition
        """)
        #expect(Self.reminder(link: "https://pay.example/meera").text.contains(
            "You can pay by UPI to meera@okhdfcbank or through this link: https://pay.example/meera. Thank you."
        ))
        #expect(Self.reminder(upi: nil, link: "https://pay.example/meera").text.contains(
            "You can pay through this link: https://pay.example/meera. Thank you."
        ))
    }

    @Test func withoutAPayeeTheReminderStillReads() {
        let text = Self.reminder(upi: nil, link: nil, parent: nil).text
        #expect(text.hasPrefix("Hello, Hemanth's fee of ₹1,200 for October is due. Thank you.\n\nMeera Nair"))
    }

    @Test func theReceiptNamesTheMethodAndDay() throws {
        let upi = try Self.receipt(.upi, parent: "Ramesh Kumar", tutor: nil)
        #expect(upi
            .text ==
            "Hello Ramesh, received ₹1,000 by UPI on 7 Oct for Dev's October fee. Thank you.\n\nBright Minds Tuition")
        let cash = try Self.receipt(.cash, parent: "Ramesh Kumar", tutor: "Meera Nair")
        #expect(cash.text.hasPrefix("Hello Ramesh, received ₹1,000 by cash on 7 Oct for Dev's October fee."))
        let other = try Self.receipt(.other, parent: nil, tutor: nil)
        #expect(other.text.hasPrefix("Hello, received ₹1,000 on 7 Oct for Dev's October fee."))
    }
}
