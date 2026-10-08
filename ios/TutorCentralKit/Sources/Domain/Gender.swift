/// `students.gender`: stored as the column's words, shown as the board's chips.
public enum Gender: String, CaseIterable, Hashable, Sendable, Codable {
    case female, male, other

    public var label: String {
        switch self {
        case .female: "Girl"
        case .male: "Boy"
        case .other: "Other"
        }
    }
}
