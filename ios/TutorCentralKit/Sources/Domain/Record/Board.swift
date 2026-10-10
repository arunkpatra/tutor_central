/// The school's board, from class 8 (`students.board`, `schools.board`).
public enum Board: String, CaseIterable, Hashable, Sendable, Codable {
    case cbse, icse, karnataka, other

    public var title: String {
        switch self {
        case .cbse: "CBSE"
        case .icse: "ICSE"
        case .karnataka: "Karnataka state"
        case .other: "Other"
        }
    }
}
