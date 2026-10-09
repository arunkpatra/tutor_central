import Domain
import Foundation
import Supabase
import Testing
@testable import Data

@MainActor struct FakeFeesRepositoryTests {
    let centre = FakeCentreRepository.meeraWorkspace.centre.id
    let october = Period(year: 2026, month: 10)

    @Test func theSeedIsTheBoards() async throws {
        let repo = FakeFeesRepository(invoices: FakeFeesRepository.seed)
        let month = try await repo.invoices(centre: centre, month: october)
        #expect(month.count == 10 && FeeTotals(invoices: month).outstanding == Money(rupees: 4000))
        #expect(FeeTotals(invoices: month).collected == Money(rupees: 7300))
        #expect(month.filter { $0.status == .paid }.allSatisfy {
            $0.paidOn(calendar: DayHeading.india) == Day(year: 2026, month: 10, day: 4) && $0.paidMethod == .upi
        })
        let september = try await repo.invoices(centre: centre, month: Period(year: 2026, month: 9))
        #expect(FeeTotals(invoices: september).collected == Money(rupees: 10300))
        #expect(september.filter { $0.status == .due }.map(\.id) == [FakeFeesRepository.nikhilSeptember])
        let before = try await repo.dueBefore(centre: centre, month: october)
        #expect(before.map(\.id) == [FakeFeesRepository.nikhilSeptember])
        let hemanth = try await repo.invoices(centre: centre, student: FakeAttendanceRepository.hemanth)
        #expect(hemanth.map(\.period.month) == [10, 9, 8, 7] && hemanth[2].paidMethod == .cash)
        #expect(hemanth[3].status == .waived)
        let octoberOnly = FakeFeesRepository(invoices: FakeFeesRepository.octoberOnly)
        #expect(try await octoberOnly.dueBefore(centre: centre, month: october).isEmpty)
    }

    @Test func writesChangeTheRowAndAreRecorded() async throws {
        let repo = FakeFeesRepository(invoices: FakeFeesRepository.seed)
        let at = FakeCountsRepository.fixedNow
        let paid = try await repo.markPaid(id: FakeFeesRepository.devOctober, method: .upi, at: at)
        #expect(paid.status == .paid && paid.paidAt == at && paid.paidMethod == .upi)
        #expect(repo.paid == [FakeFeesRepository.devOctober])
        let undone = try await repo.markDue(id: FakeFeesRepository.devOctober)
        #expect(undone.status == .due && undone.paidAt == nil && undone.paidMethod == nil)
        #expect(repo.undone == [FakeFeesRepository.devOctober])
        let waived = try await repo.waive(id: FakeFeesRepository.sahilOctober, reason: "Joined mid-month")
        #expect(waived.status == .waived && waived.waivedReason == "Joined mid-month")
        #expect(repo.waived == [FakeFeesRepository.sahilOctober])
        let paidAfterWaive = try await repo.markPaid(id: FakeFeesRepository.sahilOctober, method: .cash, at: at)
        #expect(paidAfterWaive.waivedReason == nil)
        repo.nextError = URLError(.notConnectedToInternet)
        await #expect(throws: URLError.self) {
            try await repo.markPaid(id: FakeFeesRepository.devOctober, method: .upi, at: at)
        }
        await #expect(throws: PostgrestError.self) { try await repo.markDue(id: UUID()) }
    }

    @Test func generateMakesOneDueFeePerSeedStudentWithoutOne() async throws {
        let repo = FakeFeesRepository(invoices: [])
        let made = try await repo.generate(centre: centre, month: october)
        #expect(made == 10 && repo.generated == [october])
        let month = try await repo.invoices(centre: centre, month: october)
        #expect(month.count == 10 && month.allSatisfy { $0.status == .due })
        #expect(month.map(\.amount).total == Money(rupees: 11300))
        #expect(try await repo.generate(centre: centre, month: october) == 0, "idempotent, as the function")
        repo.generateCount = 3
        #expect(
            try await repo.generate(centre: centre, month: Period(year: 2026, month: 11)) == 3,
            "a scripted answer for the stores' tests"
        )
    }
}
