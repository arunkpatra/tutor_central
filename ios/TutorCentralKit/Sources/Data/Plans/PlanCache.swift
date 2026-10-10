import Domain
import Foundation

/// The plan's copy on this iPhone (D39): one file per batch and day, `cache-<centre>-plan-<class>-<date>.json`, kept
/// whenever the plan or an artefact lands and read when the network is away; the sign-out wipe takes it with the
/// centre's other copies. Days before the one kept are removed on each keep.
public struct PlanCache: Sendable {
    private let centre: UUID
    private let directory: URL?

    public init(centre: UUID, directory: URL? = nil) {
        self.centre = centre
        self.directory = directory
    }

    public func load(classID: UUID, date: Day) -> CachedValue<PlanRecord>? {
        read(classID: classID, date: date).load()
    }

    /// Never throws: a copy is a convenience.
    public func keep(_ plan: PlanRecord, at: Date) {
        removeAll(before: plan.date)
        read(classID: plan.classID, date: plan.date).keep(plan, at: at)
    }

    /// Removes the copies of days before `day`, for any batch.
    public func removeAll(before day: Day) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        for name in names where name.hasPrefix(prefix) && name.hasSuffix(".json") {
            let iso = String(name.dropLast(".json".count).suffix(10))
            if let date = Day(iso: iso), date < day {
                try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
            }
        }
    }

    private var prefix: String {
        "cache-\(centre.uuidString.lowercased())-plan-"
    }

    private var folder: URL {
        directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TutorCentral", isDirectory: true)
    }

    private func read(classID: UUID, date: Day) -> CachedRead<PlanRecord> {
        CachedRead(centre: centre, key: "plan-\(classID.uuidString.lowercased())-\(date.iso)", directory: directory)
    }
}
