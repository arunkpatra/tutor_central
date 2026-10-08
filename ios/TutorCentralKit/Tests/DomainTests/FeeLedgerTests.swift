import Foundation
import Testing
@testable import Domain

struct FeeLedgerTests {
    static let october = FeeInvoiceTests.october
    static let names: [Int: String] = [
        1: "Dev Kumar", 2: "Akshita Rao", 3: "Sahil Verma", 4: "Nikhil Das", 5: "Hemanth Reddy",
    ]

    static func name(_ id: UUID) -> String {
        let number = Int(id.uuidString.suffix(1)) ?? 0
        return names[number] ?? "?"
    }

    @Test func allListsDueThenPaidThenWaivedEachByName() {
        let invoices = [
            FeeInvoiceTests.paid(2, month: Self.october),
            FeeInvoiceTests.invoice(1, month: Self.october),
            FeeInvoiceTests.invoice(3, month: Self.october, status: .waived, reason: "x"),
            FeeInvoiceTests.invoice(5, month: Self.october),
            FeeInvoiceTests.invoice(4, month: FeeInvoiceTests.september),
        ]
        let all = FeeLedger.rows(invoices, filter: .all, current: Self.october, name: Self.name)
        #expect(all.map { Self.name($0.studentID) } == [
            "Dev Kumar", "Hemanth Reddy", "Nikhil Das", "Akshita Rao", "Sahil Verma",
        ])
        let due = FeeLedger.rows(invoices, filter: .due, current: Self.october, name: Self.name)
        #expect(due.map(\.studentID) == [invoices[1], invoices[3], invoices[4]].map(\.studentID))
        let paid = FeeLedger.rows(invoices, filter: .paid, current: Self.october, name: Self.name)
        #expect(paid.map(\.studentID) == [invoices[0].studentID])
        #expect(FeeLedger.title(count: 10, filter: .all) == "10 fees" && FeeLedger
            .title(count: 1, filter: .all) == "1 fee")
        #expect(FeeLedger.title(count: 4, filter: .due) == "4 due" && FeeLedger
            .title(count: 6, filter: .paid) == "6 paid")
        #expect(FeeFilter.allCases.map(\.title) == ["All", "Due", "Paid"])
    }

    @Test func paymentSettingsKnowWhenToAsk() {
        #expect(PaymentSettings(upiID: "meera@okhdfcbank").needsConfirmation)
        #expect(!PaymentSettings(upiID: "meera@okhdfcbank", upiConfirmedAt: Date()).needsConfirmation)
        #expect(!PaymentSettings().needsConfirmation, "no id: nothing to confirm; the empty card shows instead")
        #expect(PaymentSettings().sendReceipts, "receipts are on by default, as the column is")
    }
}
