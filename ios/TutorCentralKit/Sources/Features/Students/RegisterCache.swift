import Data
import Domain
import Foundation

/// What the cache holds: the register as last read, with the month its fee marks belong to.
public struct RegisterSnapshot: Codable, Sendable {
    public var students: [Student]
    public var classes: [Classroom]
    public var period: Period
    /// When it was read (nil in a file written before Phase 7): the offline line says it.
    public var savedAt: Date?

    public init(students: [Student], classes: [Classroom], period: Period, savedAt: Date? = nil) {
        self.students = students
        self.classes = classes
        self.period = period
        self.savedAt = savedAt
    }
}

public typealias RegisterCache = JSONCache<RegisterSnapshot>

public extension RegisterCache {
    static func forCentre(_ id: UUID, directory: URL? = nil) -> RegisterCache {
        RegisterCache(name: "register-\(id.uuidString.lowercased())", directory: directory)
    }
}
