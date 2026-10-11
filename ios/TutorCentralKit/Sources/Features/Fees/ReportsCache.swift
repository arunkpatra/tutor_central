import Data
import Domain
import Foundation

/// Reports' copies on this iPhone (U26): a month's fees and attendance, and Progress per span, under the centre
/// (`cache-<centre>-reports-<month>.json`, `cache-<centre>-reports-progress-<span>.json`), wiped with its files.
public struct ReportsCache: Sendable {
    let centre: UUID
    let directory: URL?

    public init(centre: UUID, directory: URL?) {
        self.centre = centre
        self.directory = directory
    }

    func month(_ period: Period) -> CachedRead<MonthCopy> {
        CachedRead(centre: centre, key: "reports-\(period.isoMonth)", directory: directory)
    }

    func progress(_ stem: String) -> CachedRead<[ProgressRow]> {
        CachedRead(centre: centre, key: "reports-progress-\(stem)", directory: directory)
    }
}

/// A month's reads as kept.
struct MonthCopy: Codable, Sendable {
    let invoices: [FeeInvoice]
    let sessions: [AttendanceSession]
    let logs: [FeeLog]
}
