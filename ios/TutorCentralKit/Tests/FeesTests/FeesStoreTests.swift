import Data
import DesignSystem
import Domain
import Foundation
import Students
import Testing
@testable import Fees

@MainActor struct FeesStoreTests {
    let fees = FakeFeesRepository(invoices: FakeFeesRepository.seed)
    let messages = FakeMessageLogRepository(logs: [], feeLogs: FakeMessageLogRepository.feeSeed)
    let centres = FakeCentreRepository(workspace: FakeCentreRepository.meeraWorkspace)
    let october = Period(year: 2026, month: 10)
    let dev = FakeFeesRepository.devOctober
    let hemanth = FakeFeesRepository.hemanthOctober

    func make(
        workspace: Workspace = FakeCentreRepository.meeraWorkspace,
        invoices: [FeeInvoice]? = nil
    ) async -> FeesStore {
        if let invoices {
            fees.invoices = invoices
        }
        let register = RegisterStore(
            workspace: workspace, students: FakeStudentsRepository(students: FakeStudentsRepository.seed),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = FeesStore(
            workspace: workspace,
            register: register,
            fees: fees,
            messages: messages,
            centres: centres,
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        return store
    }

    @Test func theMonthOpensOnOctoberWithTheBoardsNumbers() async {
        let store = await make()
        #expect(store.month == october && store.monthTitle == "October 2026" && store.filter == .all && store.loaded)
        #expect(store.totals.outstanding == Money(rupees: 4000) && store.totals.outstandingLine == "4 parents")
        #expect(store.totals.collected == Money(rupees: 7300) && store.totals.collectedLine == "6 of 10 paid")
        #expect(store.rows.map(\.name) == [
            "Dev Kumar",
            "Hemanth Reddy",
            "Nikhil Das",
            "Sahil Verma",
            "Akshita Rao",
            "Ananya Iyer",
            "Bir Bikram Singh",
            "Lakshmi Menon",
            "Meher Shah",
            "Riya Sharma",
        ])
        #expect(store.rows[0].line == "Reminded Tue 6 Oct" && store.rows[0].lineTone == .ok && store.rows[0]
            .lineSymbol == "checkmark" && store.rows[0].showsButtons)
        #expect(store.rows[1].line == "Lakshmi Reddy · +91 93802 60871" && store.rows[1].lineTone == nil)
        #expect(store.rows[4].line == "Paid by UPI on 4 Oct" && store.rows[4].state == .paid && !store.rows[4]
            .showsButtons)
        #expect(store.ledgerTitle == "10 fees" && store.overdue?.text == "₹1,000 overdue from September · 1 parent")
        #expect(store.payee == nil, "the fixture's id is confirmed")
        #expect(!store.isEmptyMonth && !store.generatePreview.canCreate && store.generatePreview
            .title == "Everyone has a fee for October")
    }

    @Test func theFiltersAndTheMonthMoves() async {
        let store = await make()
        store.filter = .due
        #expect(store.rows.count == 4 && store.ledgerTitle == "4 due" && store.rows.allSatisfy(\.showsButtons))
        store.filter = .paid
        #expect(store.rows.count == 6 && store.ledgerTitle == "6 paid")
        await store.previous()
        #expect(store.month == Period(year: 2026, month: 9) && store.totals.collected == Money(rupees: 10300) && store
            .overdue == nil)
        store.filter = .all
        #expect(store.rows.first?.name == "Nikhil Das" && store.rows.first?.state == .overdue && store.rows.first?
            .line == "Reminded Wed 30 Sep")
        await store.next()
        await store.next()
        #expect(store.month == Period(year: 2026, month: 11) && store.isEmptyMonth && store.generatePreview.count == 10)
        await store.openOverdue()
        #expect(store.month == Period(year: 2026, month: 9), "the banner opens the latest overdue month")
    }

    @Test func aQuickSecondMonthMoveWins() async {
        let store = await make()
        fees.delay = .milliseconds(80)
        let first = Task { await store.open(month: Period(year: 2026, month: 9)) }
        try? await Task.sleep(for: .milliseconds(20))
        fees.delay = nil
        await store.open(month: Period(year: 2026, month: 11))
        await first.value
        #expect(store.month == Period(year: 2026, month: 11) && store.invoices.isEmpty)
    }

    @Test func thePayeeCardShowsUntilConfirmed() async {
        let store = await make(workspace: FakeCentreRepository.meeraWorkspaceUnconfirmed)
        #expect(store.payee == .confirm(upiID: "meera@okhdfcbank"))
        var changed: Workspace?
        store.onWorkspaceChanged = { changed = $0 }
        await store.confirmPayee()
        #expect(store.payee == nil && centres.confirmations.count == 1 && changed?.centre.payments
            .upiConfirmedAt != nil)
        let noID = await make(workspace: FakeCentreRepository.meeraWorkspaceWithoutUPI)
        #expect(noID.payee == .add)
    }

    @Test func generatingReadsTheMonthAgainAndSaysHowMany() async {
        let store = await make(invoices: [])
        #expect(store.isEmptyMonth && store.generatePreview.canCreate && store.generatePreview
            .buttonLabel == "Create 10 fees")
        let made = await store.generate()
        #expect(made == 10 && store.invoices.count == 10 && store.message == nil && !store
            .canRetry)
        #expect(store.sheet == nil && store.lastSavedAt != nil)
    }

    @Test func nothingToCreateDisablesTheButton() async {
        let store = await make()
        store.sheet = .generate
        #expect(!store.generatePreview.canCreate && store.generatePreview.buttonLabel == "Nothing to create")
        let empty = await make(invoices: [])
        fees.nextError = URLError(.badServerResponse)
        #expect(await empty.generate() == nil && empty
            .message == "Couldn't create the fees. Check your connection and try again." && empty.canRetry)
    }

    @Test func markingPaidWaitsForTheServerAndOffersUndo() async throws {
        let store = await make()
        fees.delay = .milliseconds(50)
        let task = Task { await store.markPaid(dev, method: .upi, on: store.today) }
        try await Task.sleep(for: .milliseconds(10))
        #expect(
            store.writing && store.rows.first { $0.id == dev }?.state == .due,
            "nothing moves before the server answers"
        )
        #expect(await task.value)
        #expect(!store.writing && store.totals.outstanding == Money(rupees: 3000) && store.totals
            .collectedLine == "7 of 10 paid")
        let row = try #require(store.rows.first { $0.id == dev })
        #expect(row.state == .paid && row.line == "Paid by UPI on 7 Oct" && !row.showsButtons)
        #expect(store.undo == FeesStore.UndoToast(text: "Dev's fee marked paid by UPI.", invoiceID: dev) && fees
            .paid == [dev])
        #expect(store.sheet == .receipt(dev), "receipts are on and Ramesh has a number")
    }

    @Test func undoReversesTheOneFeeNamed() async {
        let store = await make()
        _ = await store.markPaid(dev, method: .cash, on: store.today)
        _ = await store.markPaid(hemanth, method: .upi, on: store.today)
        #expect(store.undo?.invoiceID == hemanth, "the newer toast replaces the older; Dev stays paid")
        #expect(await store.undoPaid(dev))
        #expect(fees.undone == [dev] && store.rows.first { $0.id == dev }?.state == .due && store.rows
            .first { $0.id == hemanth }?.state == .paid)
        #expect(store.undo == nil && store.totals.outstanding == Money(rupees: 2800))
    }

    @Test func aFailedMarkPaidKeepsTheRowDueWithRetry() async {
        let store = await make()
        fees.nextError = URLError(.badServerResponse)
        #expect(await store.markPaid(dev, method: .upi, on: store.today) == false)
        #expect(store.rows.first { $0.id == dev }?.state == .due && store.undo == nil && store.sheet == nil)
        #expect(store.message == "Couldn't mark the fee paid. Check your connection and try again." && store.canRetry)
        await store.retryLast()
        #expect(fees.paid == [dev] && store.rows.first { $0.id == dev }?.state == .paid)
    }

    @Test func aFailedUndoLeavesTheFeePaid() async {
        let store = await make()
        _ = await store.markPaid(dev, method: .upi, on: store.today)
        fees.nextError = URLError(.badServerResponse)
        #expect(await store.undoPaid(dev) == false)
        #expect(store.rows.first { $0.id == dev }?.state == .paid && store
            .message == "Couldn't undo. Dev's fee stays paid." && store.canRetry)
    }

    @Test func aReceiptIsOfferedOnlyWhenOnAndThereIsANumber() async throws {
        var off = FakeCentreRepository.meeraWorkspace
        off.centre.payments.sendReceipts = false
        let store = await make(workspace: off)
        _ = await store.markPaid(dev, method: .upi, on: store.today)
        #expect(store.sheet == nil && store.undo != nil)
        let receipt = try #require(store.receipt(for: dev))
        #expect(receipt.title == "Send a receipt" && receipt.headline == "Dev's fee is paid" && receipt
            .parentLine == "Ramesh Kumar · +91 98848 43831" && receipt.label == "Receipt")
        #expect(receipt.text
            .hasPrefix("Hello Ramesh, received ₹1,000 by UPI on 7 Oct for Dev's October fee. Thank you."))
        #expect(receipt.note == "Opens WhatsApp with the receipt ready to send. We note it on the fee." && receipt.url?
            .host() == "wa.me")
        let url = await store.send(receipt)
        #expect(url == receipt.url && messages.feeLogged.map(\.kind) == [.receipt] && store.lastSavedAt != nil)
    }

    @Test func remindingLogsOnceAndReadsReminded() async throws {
        let store = await make()
        let sheet = try #require(store.reminder(for: hemanth))
        #expect(sheet.title == "Remind the parent" && sheet.headline == "Hemanth's October fee is due" && sheet
            .parentLine == "Lakshmi Reddy · +91 93802 60871")
        #expect(sheet.label == "Message" && sheet.text == """
        Hello Lakshmi, Hemanth's fee of ₹1,200 for October is due. You can pay by UPI to meera@okhdfcbank. Thank you.

        Meera Nair
        Bright Minds Tuition
        """)
        #expect(sheet.note == "Opens WhatsApp with the message ready to send. We note the date on the fee. "
            + "The text is copied too, in case WhatsApp can't open.")
        let url = await store.send(sheet)
        #expect(url == sheet.url && messages.feeLogged.map(\.kind) == [.reminder] && messages.feeLogged[0]
            .month == october)
        #expect(store.rows.first { $0.id == hemanth }?.line == "Reminded today" && store.rows
            .first { $0.id == hemanth }?.lineTone == .ok)
        #expect(store.reminder(for: FakeFeesRepository.id(1)) == nil, "a paid fee has no reminder")
        messages.nextError = URLError(.notConnectedToInternet)
        #expect(await store.send(sheet) == nil && store
            .message == "Couldn't open WhatsApp. Check your connection and try again.")
    }

    @Test func aStudentWithoutANumberShowsTheTextWithoutALink() async throws {
        var students = FakeStudentsRepository.seed
        students[9].parentPhone = nil
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: FakeStudentsRepository(students: students),
            classes: FakeClassesRepository(classes: FakeClassesRepository.seed), cache: nil,
            now: { FakeCountsRepository.fixedNow }
        )
        await register.load()
        let store = FeesStore(
            workspace: FakeCentreRepository.meeraWorkspace,
            register: register,
            fees: fees,
            messages: messages,
            centres: centres,
            now: { FakeCountsRepository.fixedNow }
        )
        await store.load()
        let sheet = try #require(store.reminder(for: FakeFeesRepository.sahilOctober))
        #expect(sheet.url == nil && sheet.parentLine == "Add the parent's number first")
        _ = await store.markPaid(FakeFeesRepository.sahilOctober, method: .cash, on: store.today)
        #expect(store.sheet == nil, "no number, no receipt sheet")
    }

    @Test func waivingSettlesWithoutCollecting() async {
        let store = await make()
        #expect(await store.waive(FakeFeesRepository.sahilOctober, reason: "  Joined mid-month "))
        let row = store.rows.first { $0.id == FakeFeesRepository.sahilOctober }
        #expect(row?.state == .waived && row?.line == "Waived · Joined mid-month" && row?.showsButtons == false)
        #expect(store.totals.outstanding == Money(rupees: 3200) && store.totals
            .collected == Money(rupees: 7300) && store.sheet == nil)
        #expect(store.message == nil && fees.waived == [FakeFeesRepository.sahilOctober])
    }

    @Test func aFailedReadSaysSoAndKeepsTheLastMonth() async {
        let store = await make()
        fees.nextError = URLError(.badServerResponse)
        await store.next()
        #expect(store.error == "Couldn't load fees. Check your connection and try again." && store.month == Period(
            year: 2026,
            month: 11
        ))
        #expect(!store.isEmptyMonth, "a failed read is not an empty month")
        await store.retryLast()
        #expect(store.error == nil && store.isEmptyMonth)
    }

    @Test func aPastMonthsOutstandingSaysOverdue() async {
        let store = await make()
        #expect(store.outstandingLine == "4 parents")
        await store.previous()
        #expect(store.outstandingLine == "1 parent, overdue", "P5-Fees-Overdue")
        await store.previous()
        #expect(store.outstandingLine == "Nothing due")
    }
}
