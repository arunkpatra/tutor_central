import Foundation

/// Percentages and absences from saved sessions (the history, the student's month, the student detail).
public enum AttendanceStats {
    public struct Count: Hashable, Sendable {
        public let present: Int
        public let total: Int

        public init(present: Int, total: Int) {
            self.present = present
            self.total = total
        }

        /// Nil when nothing is marked: the screen says so instead of 0%.
        public var percent: Int? {
            total == 0 ? nil : Int((Double(present) / Double(total) * 100).rounded())
        }

        public var fraction: Double {
            total == 0 ? 0 : Double(present) / Double(total)
        }
    }

    public static func forStudent(_ id: UUID, in sessions: [AttendanceSession]) -> Count {
        let marks = sessions.compactMap { $0.marks[id] }
        return Count(present: marks.filter { $0 == .present }.count, total: marks.count)
    }

    public static func forMonth(_ sessions: [AttendanceSession]) -> Count {
        Count(present: sessions.map(\.presentCount).reduce(0, +), total: sessions.map(\.marks.count).reduce(0, +))
    }

    /// Newest first.
    public static func absences(of id: UUID, in sessions: [AttendanceSession]) -> [AttendanceSession] {
        sessions.filter { $0.marks[id] == .absent }.sorted { $0.date > $1.date }
    }

    public static func sessions(_ all: [AttendanceSession], in month: Period) -> [AttendanceSession] {
        all.filter { $0.date.period == month }
    }
}
