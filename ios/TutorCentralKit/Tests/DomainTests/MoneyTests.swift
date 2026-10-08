import Foundation
import Testing
@testable import Domain

struct MoneyTests {
    @Test func formatsRupeesWithIndianGrouping() {
        #expect(Money(rupees: 1200).formatted == "₹1,200")
        #expect(Money(rupees: 14700).formatted == "₹14,700")
        #expect(Money(rupees: 120_000).formatted == "₹1,20,000")
        #expect(Money(rupees: 0).formatted == "₹0")
    }

    @Test func addsAndCompares() {
        #expect(Money(rupees: 1000) + Money(rupees: 200) == Money(rupees: 1200))
        #expect(Money(rupees: 999) < Money(rupees: 1000))
    }

    @Test func sumsASequence() {
        #expect([Money(rupees: 1), Money(rupees: 2)].total == Money(rupees: 3))
        #expect([Money]().total == .zero)
    }

    @Test func parsesWhatATutorTypes() {
        #expect(Money(typed: "1,500") == Money(rupees: 1500) && Money(typed: " ₹1200 ") == Money(rupees: 1200))
        #expect(Money(typed: "0") == Money(rupees: 0))
        #expect(Money(typed: "") == nil && Money(typed: "12a") == nil && Money(typed: "1.5") == nil &&
            Money(typed: "-5") == nil)
    }

    @Test func roundTripsThroughJSON() throws {
        let data = try JSONEncoder().encode([Money(rupees: 1200), .zero])
        #expect(try JSONDecoder().decode([Money].self, from: data) == [Money(rupees: 1200), .zero])
        let phone = try JSONDecoder().decode(
            PhoneNumber.self,
            from: JSONEncoder().encode(#require(PhoneNumber(e164: "+919799113211")))
        )
        #expect(phone.e164 == "+919799113211")
        let period = try JSONDecoder().decode(Period.self, from: JSONEncoder().encode(Period(year: 2026, month: 10)))
        #expect(period == Period(year: 2026, month: 10))
    }
}
