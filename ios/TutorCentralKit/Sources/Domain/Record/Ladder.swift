/// Where a young student is in reading, writing and numbers (LKG to class 3; an ASER and NIPUN style ladder). Each area
/// is a chapter whose skills are its five steps, in order (`chapters.ladder`, migration 0009); the steps are the
/// approved boards' (P10-Student-Ladder).
public enum Ladder {
    public enum Area: String, CaseIterable, Hashable, Sendable, Codable {
        case reading, writing, numbers

        public var title: String {
            switch self {
            case .reading: "Reading"
            case .writing: "Writing"
            case .numbers: "Numbers"
            }
        }

        public var steps: [String] {
            switch self {
            case .reading: ["Letters", "Words", "Sentences", "Paragraph", "Story"]
            case .writing: ["Traces", "Letters", "Words", "Sentences", "Short text"]
            case .numbers: ["To 9", "To 99", "Add", "Subtract", "Multiply"]
            }
        }
    }

    /// The step the student is on: the first not yet secure; nil when every step is.
    public static func currentStep(_ states: [SkillState]) -> Int? {
        states.firstIndex { $0 != .secure }
    }
}
