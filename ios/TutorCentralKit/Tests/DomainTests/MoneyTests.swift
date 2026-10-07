import Testing
@testable import Domain

@Suite struct MoneyTests {
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
}
