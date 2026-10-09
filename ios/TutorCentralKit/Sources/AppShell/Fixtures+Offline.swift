import Data
import Domain
import Fees
import Foundation
import Students
import Today

/// The offline boards (P7-Offline-*): the monitor offline, every read failing, the copies on this iPhone saved at
/// 14:10 on the boards' day.
extension Fixtures {
    static let offlineStates: Set<LaunchState> = [.offlineToday, .offlineStudents, .offlineFees, .offlineNoCache]

    /// 14:10 on Wednesday 7 October: when the boards' copies were saved.
    static var savedAt: Date {
        india(day: 7, hour: 14, minute: 10)
    }

    /// Writes the copies an offline state shows; Fees with nothing saved writes none.
    @MainActor static func keepCopies(for state: LaunchState, in folder: URL) {
        guard offlineStates.contains(state), state != .offlineNoCache else { return }
        let centre = meeraWorkspace.centre.id
        let october = Period(year: 2026, month: 10)
        let invoices = FakeFeesRepository.seed
        CachedRead<TodaySnapshot>(centre: centre, key: "today", directory: folder).keep(
            TodaySnapshot(
                counts: TodayCounts(students: 10, due: Money(rupees: 4000), classesToday: 1),
                sessions: FakeAttendanceRepository.seed.filter { $0.date.period == october },
                events: FakeEventsRepository.seed
            ),
            at: savedAt
        )
        CachedRead<FeesSnapshot>(centre: centre, key: "fees-\(october.isoMonth)", directory: folder).keep(
            FeesSnapshot(
                invoices: invoices.filter { $0.period == october },
                dueBefore: invoices.filter { $0.status == .due && $0.period < october },
                logs: FakeMessageLogRepository.feeSeed
            ),
            at: savedAt
        )
        try? RegisterCache.forCentre(centre, directory: folder).save(RegisterSnapshot(
            students: FakeStudentsRepository.seed, classes: FakeClassesRepository.seed, period: october,
            savedAt: savedAt
        ))
    }
}
