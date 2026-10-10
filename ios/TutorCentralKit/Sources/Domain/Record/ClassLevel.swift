/// The class a student is in, as `students.class_level` stores it (migration 0009). LKG and UKG are a stage with the
/// ladder and no chapters; classes 1 to 3 have the ladder for reading, writing and numbers beside the school's books
/// (docs/spec-v2.md section 5).
public enum ClassLevel: String, CaseIterable, Hashable, Sendable, Codable, Comparable {
    case lkg, ukg
    case one = "1", two = "2", three = "3", four = "4", five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case ten = "10"

    public enum Stage: Hashable, Sendable { case preschool, early, middle, secondary }

    public var stage: Stage {
        switch self {
        case .lkg, .ukg: .preschool
        case .one, .two, .three: .early
        case .four, .five, .six, .seven: .middle
        case .eight, .nine, .ten: .secondary
        }
    }

    /// The board matters from class 8 (D58); the form shows the Board row from there.
    public var expectsBoard: Bool {
        stage == .secondary
    }

    /// Homework is light up to class 5.
    public var homeworkIsLight: Bool {
        self <= .five
    }

    /// LKG to class 3 use the ladder.
    public var usesLadder: Bool {
        stage == .preschool || stage == .early
    }

    /// LKG and UKG have the ladder only.
    public var hasChapters: Bool {
        stage != .preschool
    }

    /// The class wheel's words.
    public var title: String {
        switch self {
        case .lkg: "LKG"
        case .ukg: "UKG"
        default: "Class \(rawValue)"
        }
    }

    private var ordinal: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    public static func < (lhs: ClassLevel, rhs: ClassLevel) -> Bool {
        lhs.ordinal < rhs.ordinal
    }
}
