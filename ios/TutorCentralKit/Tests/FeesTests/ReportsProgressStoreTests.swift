import Data
import Domain
import Foundation
import Students
import Testing
@testable import Fees

/// Reports' Progress (plan/phase-15-plan.md Task 10, decisions 15 to 18; Review focus 3, 4 and 9; U26).
@MainActor struct ReportsProgressStoreTests {
    nonisolated static let now = FakeCountsRepository.fixedNow

    struct Kit {
        let store: ReportsStore
        let students: FakeStudentsRepository
        let register: RegisterStore
        let textbooks: FakeTextbooksRepository
        let record: FakeRecordRepository
        let attendance: FakeAttendanceRepository
    }

    static func kit(
        students: [Student] = FakeStudentsRepository.eveningSeed, record: FakeRecordRepository = FakeRecordRepository(),
        cache: ReportsCache? = nil
    ) async -> Kit {
        let roster = FakeStudentsRepository(students: students)
        let register = RegisterStore(
            workspace: FakeCentreRepository.meeraWorkspace, students: roster,
            classes: FakeClassesRepository(classes: FakeClassesRepository.withEvening), cache: nil, now: { now }
        )
        await register.load()
        let textbooks = FakeTextbooksRepository.evening()
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithToday)
        let store = ReportsStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: register,
            fees: FakeFeesRepository(invoices: FakeFeesRepository.seed), attendance: attendance,
            messages: FakeMessageLogRepository(logs: [], feeLogs: []), now: { now },
            progress: ProgressReader(textbooks: textbooks, record: record, attendance: attendance), cache: cache
        )
        store.segment = .progress
        await store.load()
        return Kit(
            store: store, students: roster, register: register, textbooks: textbooks, record: record,
            attendance: attendance
        )
    }

    static func boards(_ board: Board?, for students: [Student]) -> [Student] {
        students.map { student in
            var changed = student
            changed.board = board
            return changed
        }
    }

    @Test func progressReadsEveryActiveStudentTogetherAndSumsTheRows() async {
        let kit = await Self.kit()
        let rows = kit.store.progressRows
        #expect(rows.count == kit.register.activeStudents.count && kit.textbooks.bookReads == 1)
        #expect(kit.store.progressHero?.skillsSecure == rows.reduce(0) { $0 + $1.skillsSecure })
        #expect(kit.store.spanTitle == "October 2026")
    }

    @Test func theTermIsTheCentresCalendarAndStepsByTerm() async {
        let kit = await Self.kit(students: Self.boards(.karnataka, for: FakeStudentsRepository.eveningSeed))
        kit.store.span = .term
        await kit.store.load()
        #expect(kit.store.spanTitle == "Term 1 · June to October")
        await kit.store.previous()
        #expect(kit.store.spanTitle == "Term 2 · November to April")
        #expect(kit.store.progressSpan == .term(Term(schoolYear: 2025, number: 2, calendar: .karnataka)))
    }

    @Test func steppingBackFromTermOneShowsLastYearsTermTwo() async {
        let kit = await Self.kit()
        kit.store.span = .term
        await kit.store.load()
        #expect(kit.store.spanTitle == "Term 2 · October to March")
        await kit.store.previous()
        #expect(kit.store.spanTitle == "Term 1 · June to September")
        #expect(kit.store.progressHero?.notOnTrackLabel == "not on track at the end")
        await kit.store.previous()
        #expect(kit.store.progressSpan == .term(Term(schoolYear: 2025, number: 2, calendar: .standard)))
        #expect(kit.store.month == Period(year: 2026, month: 10), "the month stays where it was")
    }

    @Test func lowestFirstIsTheDefaultAndTheMenuOffersThree() async {
        let kit = await Self.kit()
        #expect(kit.store.sort == .lowestFirst && ProgressSort.allCases.count == 3)
        kit.store.sort = .byName
        let names = kit.store.progressRows.map(\.name)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
    }

    @Test func archivingAStudentRemovesTheirRowAndTheirFigures() async throws {
        let kit = await Self.kit()
        let before = try #require(kit.store.progressHero)
        let dev = try #require(kit.store.progressRows.first { $0.id == FakeStudentsRepository.dev })
        try await kit.students.setArchived(id: FakeStudentsRepository.dev, true)
        await kit.register.refresh()
        await kit.store.load()
        #expect(!kit.store.progressRows.contains { $0.id == FakeStudentsRepository.dev })
        #expect(kit.store.progressHero?.skillsSecure == before.skillsSecure - dev.skillsSecure)
        #expect(!kit.store.export(.progress).text.contains("Dev Kumar"))
    }

    @Test func aCentreWithNoChecksStillLoads() async {
        let kit = await Self.kit(record: FakeRecordRepository(checks: [], homework: []))
        #expect(kit.store.error == nil && !kit.store.progressRows.isEmpty)
        #expect(kit.store.progressHero?.rightText == "–")
        #expect(kit.store.progressRows.allSatisfy { $0.percentText == "–" })
    }

    @Test func theCSVIsTheProgressRowsInTheSpansFile() async {
        let kit = await Self.kit()
        let file = kit.store.export(.progress)
        #expect(file.fileName == "progress-2026-10.csv")
        #expect(file.text.hasPrefix("\u{FEFF}Student,Class,Status,Skills secure,Checks,Right,Absences\r\n"))
        kit.store.span = .term
        #expect(kit.store.export(.progress).fileName == "progress-term-2-2026.csv")
    }

    @Test func aMonthMoveDropsAStaleAnswer() async {
        let kit = await Self.kit()
        kit.attendance.delay = .milliseconds(150)
        let back = Task { await kit.store.previous() }
        try? await Task.sleep(for: .milliseconds(20))
        await kit.store.next()
        await back.value
        #expect(kit.store.month == Period(year: 2026, month: 10) && kit.store.spanTitle == "October 2026")
        #expect(!kit.store.loading)
    }

    @Test func theReportOpensFromItsCopyOfflineAndSaysSo() async {
        let folder = FileManager.default.temporaryDirectory.appending(path: "reports-\(UUID().uuidString)")
        let cache = ReportsCache(centre: FakeCentreRepository.meeraWorkspace.centre.id, directory: folder)
        let online = await Self.kit(cache: cache)
        let rows = online.store.progressRows
        let record = FakeRecordRepository()
        record.nextError = URLError(.notConnectedToInternet)
        let offline = await Self.kit(record: record, cache: cache)
        #expect(offline.store.progressRows == rows && offline.store.error == nil)
        #expect(offline.store.savedAt != nil && offline.store.offlineRead)
    }

    /// Hand run 14: a good read keeps its time, so the line names it when the phone goes offline after.
    @Test func aGoodReadKeepsItsTimeForTheOfflineLine() async {
        let kit = await Self.kit()
        #expect(kit.store.savedAt == Self.now && !kit.store.offlineRead)
        kit.store.segment = .fees
        await kit.store.load()
        #expect(kit.store.savedAt == Self.now && !kit.store.offlineRead)
    }

    @Test func theFeesMonthOpensFromItsCopyOffline() async {
        let folder = FileManager.default.temporaryDirectory.appending(path: "reports-\(UUID().uuidString)")
        let cache = ReportsCache(centre: FakeCentreRepository.meeraWorkspace.centre.id, directory: folder)
        let online = await Self.kit(cache: cache)
        online.store.segment = .fees
        await online.store.load()
        let lines = online.store.feeLines
        #expect(!lines.isEmpty)
        let fees = FakeFeesRepository(invoices: [])
        fees.nextError = URLError(.notConnectedToInternet)
        let store = ReportsStore(
            workspace: FakeCentreRepository.meeraWorkspace, register: online.register, fees: fees,
            attendance: online.attendance, messages: FakeMessageLogRepository(logs: [], feeLogs: []), now: { Self.now },
            cache: cache
        )
        await store.load()
        #expect(store.feeLines == lines && store.error == nil && store.savedAt != nil)
    }
}
