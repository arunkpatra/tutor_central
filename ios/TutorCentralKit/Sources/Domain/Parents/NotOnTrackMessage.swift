/// The message to the parent of a student not on track (P10-NotOnTrack-Message; plan/phase-14-plan.md decision 10):
/// what
/// is hard, what we are doing, what helps at home and a five-minute talk. In English it is this template on the phone
/// (no
/// call, no consent); in Hindi, Hinglish or Kannada `/ai/make` writes it from the same facts.
public enum NotOnTrackMessage {
    public struct Facts: Hashable, Sendable {
        public let hard: [String]
        public let reasons: [String]
        public let doing: String
        public let atHome: String?

        public init(hard: [String], reasons: [String], doing: String, atHome: String?) {
            self.hard = hard
            self.reasons = reasons
            self.doing = doing
            self.atHome = atHome
        }
    }

    public static let title = "Tell the parent"
    public static let atHome = "Ten minutes of practice each evening at home will make a big difference."

    /// The facts from the status's reasons, the current skill, the skill before it and the step.
    public static func facts(reasons: [String], skill: Skill?, before: Skill?, step: NextStep) -> Facts {
        let hard = skill.map { [NoteWeek.lowered($0.name)] } ?? ["keeping up this month"]
        let doing = switch (step, skill, before) {
        case let (.stepBack, skill?, before?):
            "step back to \(NoteWeek.lowered(before.name)), then \(NoteWeek.lowered(skill.name))"
        case (_, .some, _): "teach it again with a worked example in the next class"
        case (_, nil, _): "go over the last chapter again in the next class"
        }
        return Facts(hard: hard, reasons: reasons.map(NoteWeek.lowered), doing: doing, atHome: atHome)
    }

    /// "Hello Ramesh, Dev is finding balancing equations hard and was absent twice this month. We will … Thank you."
    /// then the signature.
    public static func text(
        studentName: String, parentName: String?, facts: Facts, tutorName: String?, centreName: String
    ) -> String {
        MessageSignature.signed(
            body(studentName: studentName, parentName: parentName, facts: facts), tutorName: tutorName,
            centreName: centreName
        )
    }

    /// The template's words without the signature: the sheet draws the signature under the editable text.
    public static func body(studentName: String, parentName: String?, facts: Facts) -> String {
        let greeting = parentName.flatMap { $0.split(separator: " ").first }.map { "Hello \($0)," } ?? "Hello,"
        let child = studentName.split(separator: " ").first.map(String.init) ?? studentName
        let hard = ListWords.and(facts.hard)
        let why = facts.reasons.first.map { " and \(Self.was($0))" } ?? ""
        return [
            "\(greeting) \(child) is finding \(hard) hard\(why).",
            "We will \(facts.doing).",
            facts.atHome,
            "Could we talk for five minutes this week? Thank you.",
        ].compactMap(\.self).joined(separator: " ")
    }

    /// "Dev needs a hand this month".
    public static func heading(studentFirstName: String) -> String {
        "\(studentFirstName) needs a hand this month"
    }

    /// A reason as the second half of the first sentence: "absent twice this month" → "was absent twice this month";
    /// "3 of 10 on the mock" → "got 3 of 10 on the mock".
    private static func was(_ reason: String) -> String {
        if reason.hasPrefix("absent") {
            return "was \(reason)"
        }
        if reason.first?.isNumber == true {
            return "got \(reason)"
        }
        return "has had \(reason)"
    }
}
