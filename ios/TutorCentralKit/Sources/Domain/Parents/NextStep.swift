/// What the plan does next for a student who is not on track or to watch (P10-NextStep; plan/phase-14-plan.md decision
/// 9). The plan's own choice follows the status; the tutor's choice is kept on the student (`students.next_step`) until
/// the status changes.
public enum NextStep: String, CaseIterable, Hashable, Sendable, Codable {
    case tellParent = "tell_parent", teachAgain = "teach_again", stepBack = "step_back", addToChecks = "add_to_checks"
    case leave

    public var title: String {
        switch self {
        case .tellParent: "Tell the parent, then teach again"
        case .teachAgain: "Teach again with the worked example"
        case .stepBack: "Step back to what comes before"
        case .addToChecks: "Add it to the checks"
        case .leave: "Leave it for now"
        }
    }

    /// The row's second line (P10-NextStep).
    public func meaning(language: MessageLanguage, skill: String?, before: String?) -> String {
        let skill = skill ?? "The skill"
        switch self {
        case .tellParent: return "A message in \(language.title); the worked example in the next class"
        case .teachAgain: return "\(skill) in the next class, a set after"
        case .stepBack: return "\(before ?? "What comes before"), then \(Self.lowered(skill))"
        case .addToChecks: return "Three questions on it, spaced over the next weeks"
        case .leave: return "The plan carries on; the status stays"
        }
    }

    /// The tracking card's Next sentence (P10-Student-NotOnTrack).
    public func nextLine(skill: String?, before: String?) -> String {
        switch self {
        case .tellParent: "Tell the parent, then teach again with the worked example."
        case .teachAgain: "Teach again with the worked example."
        case .stepBack: "Step back to \(before ?? "what comes before"), then \(skill ?? "the skill")."
        case .addToChecks: "Add \(skill ?? "it") to the checks."
        case .leave: "Leave it for now; the plan carries on."
        }
    }

    /// The plan's own choice from the stored status.
    public static func planned(_ status: TrackStatus) -> NextStep {
        switch status {
        case .notOnTrack: .tellParent
        case .watch: .teachAgain
        case .onTrack, .notKnown: .leave
        }
    }

    /// "Balancing equations" → "balancing equations"; a name that starts with an acronym stays.
    private static func lowered(_ text: String) -> String {
        let characters = Array(text)
        guard let first = characters.first, characters.count < 2 || !characters[1].isUppercase else { return text }
        return first.lowercased() + String(characters.dropFirst())
    }
}

public extension Student {
    /// The tutor's choice when one is kept, else the plan's own.
    var effectiveStep: NextStep {
        nextStep ?? NextStep.planned(trackStatus)
    }
}
