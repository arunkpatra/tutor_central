/// Whether a student is on track (`students.track_status`), in the order the Students list sorts them: the ones who
/// need the tutor first, students without checks last.
public enum TrackStatus: String, CaseIterable, Hashable, Sendable, Codable, Comparable {
    case notOnTrack = "not_on_track", watch, onTrack = "on_track", notKnown = "not_known"

    public var title: String {
        switch self {
        case .notOnTrack: "Not on track"
        case .watch: "Watch"
        case .onTrack: "On track"
        case .notKnown: "Not known yet"
        }
    }

    private var ordinal: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    public static func < (lhs: TrackStatus, rhs: TrackStatus) -> Bool {
        lhs.ordinal < rhs.ordinal
    }
}
