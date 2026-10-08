import Foundation
import Testing
@testable import Domain

/// Wednesday 7 October 2026, 18:30 in India (the boards' moment; Domain cannot see Data's FakeCountsRepository).
enum FakeInvoiceClock {
    static let now = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 18, minute: 30))
        ?? .distantPast
}

struct FeeInvoiceTests {
    static let october = Period(year: 2026, month: 10)
    static let september = Period(year: 2026, month: 9)
    static let paidOn4Oct = DayHeading.india.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 11))
        ?? .distantPast

    static func invoice(
        _ number: Int, month: Period, status: MonthFee.Status = .due, amount: Int = 1000, paidAt: Date? = nil,
        method: MonthFee.PaidMethod? = nil, reason: String? = nil
    ) -> FeeInvoice {
        FeeInvoice(
            id: UUID(uuidString: String(format: "bbbbbbbb-0000-0000-0000-%012d", number)) ?? UUID(),
            studentID: UUID(uuidString: String(format: "aaaaaaaa-0000-0000-0000-%012d", number)) ?? UUID(),
            period: month, amount: Money(rupees: amount), status: status, paidAt: paidAt, paidMethod: method,
            waivedReason: reason
        )
    }

    static func paid(
        _ number: Int,
        month: Period,
        method: MonthFee.PaidMethod = .upi,
        amount: Int = 1000
    ) -> FeeInvoice {
        invoice(number, month: month, status: .paid, amount: amount, paidAt: paidOn4Oct, method: method)
    }

    @Test func overdueIsAPastMonthStillDue() {
        #expect(Self.invoice(1, month: Self.september).state(current: Self.october) == .overdue)
        #expect(Self.invoice(1, month: Self.october).state(current: Self.october) == .due)
        #expect(
            Self.invoice(1, month: Self.october.next).state(current: Self.october) == .due,
            "a future month is due, not overdue"
        )
        let waived = Self.invoice(1, month: Self.september, status: .waived, reason: "Joined mid-month")
        #expect(waived.state(current: Self.october) == .waived)
        #expect(Self.paid(1, month: Self.september).state(current: Self.october) == .paid)
        #expect(FeeState.overdue.word == "Overdue" && FeeState.paid.isSettled && FeeState.waived.isSettled)
        #expect(!FeeState.overdue.isSettled && !FeeState.due.isSettled)
    }

    @Test func theSettledLineNamesTheMethodAndDay() {
        let india = DayHeading.india
        let upi = Self.paid(1, month: Self.october)
        #expect(upi.settledLine(calendar: india) == "Paid by UPI on 4 Oct")
        #expect(upi.paidOn(calendar: india) == Day(year: 2026, month: 10, day: 4))
        #expect(Self.paid(1, month: Self.october, method: .cash)
            .settledLine(calendar: india) == "Paid by cash on 4 Oct")
        #expect(Self.paid(1, month: Self.october, method: .other).settledLine(calendar: india) == "Paid on 4 Oct")
        let waived = Self.invoice(1, month: Self.october, status: .waived, reason: "Joined mid-month")
        #expect(waived.settledLine(calendar: india) == "Waived · Joined mid-month")
        #expect(Self.invoice(1, month: Self.october).settledLine(calendar: india) == nil)
    }

    @Test func theBannerSumsEarlierMonthsAndNamesTheLatest() {
        let august = Period(year: 2026, month: 8)
        let invoices = [
            Self.invoice(1, month: Self.october), Self.invoice(2, month: Self.september, amount: 1000),
            Self.invoice(3, month: august, amount: 1200), Self.paid(3, month: Self.september),
            Self.invoice(4, month: august, status: .waived, reason: "x"),
        ]
        let summary = FeeLedger.overdueBefore(invoices, current: Self.october)
        #expect(summary?.amount == Money(rupees: 2200) && summary?.parents == 2)
        #expect(summary?.latest == Self.september && summary?.months == 2)
        #expect(summary?.text == "₹2,200 overdue from September and before · 2 parents")
        let one = FeeLedger.overdueBefore([Self.invoice(2, month: Self.september, amount: 1000)], current: Self.october)
        #expect(one?.text == "₹1,000 overdue from September · 1 parent")
        #expect(FeeLedger.overdueBefore([Self.invoice(1, month: Self.october)], current: Self.october) == nil)
    }

    @Test func aPaidDayBecomesNoonOrNow() throws {
        let india = DayHeading.india
        let today = Day(FakeInvoiceClock.now, calendar: india)
        #expect(FeeInvoice
            .paidAt(for: today, today: today, now: FakeInvoiceClock.now, calendar: india) == FakeInvoiceClock.now)
        let earlier = try #require(Day(year: 2026, month: 10, day: 4))
        let at = FeeInvoice.paidAt(for: earlier, today: today, now: FakeInvoiceClock.now, calendar: india)
        #expect(Day(at, calendar: india) == earlier && india.component(.hour, from: at) == 12)
    }

    @Test func totalsCountDueAndOverdueAsOutstandingAndOnlyPaidAsCollected() {
        let invoices = [
            Self.invoice(1, month: Self.october, amount: 1000), Self.invoice(2, month: Self.october, amount: 1200),
            Self.paid(3, month: Self.october, amount: 1500),
            Self.invoice(4, month: Self.october, status: .waived, amount: 800, reason: "x"),
        ]
        let totals = FeeTotals(invoices: invoices)
        #expect(totals.outstanding == Money(rupees: 2200) && totals.outstandingCount == 2)
        #expect(totals.outstandingLine == "2 parents")
        #expect(totals.collected == Money(rupees: 1500) && totals.paidCount == 1 && totals.total == 4)
        #expect(totals.collectedLine == "1 of 4 paid")
        #expect(FeeTotals(invoices: []).outstandingLine == "Nothing due")
        #expect(FeeTotals(invoices: [invoices[0]]).outstandingLine == "1 parent")
    }
}
