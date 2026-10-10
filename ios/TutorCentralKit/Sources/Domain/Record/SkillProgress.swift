import Foundation

/// How a check moves a skill (plan decision 7; Phase 12 refines the rules with the plan).
public enum SkillProgress {
    /// One chapter of the placement: its skills and the tap (nil: skipped).
    public struct Answer: Hashable, Sendable {
        public let chapter: Chapter
        public let skills: [Skill]
        public let correct: Bool?

        public init(_ chapter: Chapter, _ skills: [Skill], _ correct: Bool?) {
            self.chapter = chapter
            self.skills = skills
            self.correct = correct
        }
    }

    /// The state after one check; nil when it does not move. Right moves not started, taught and revisit to practising,
    /// and practising to secure when the previous check on it was right too; wrong moves secure to revisit.
    public static func after(_ state: SkillState, correct: Bool, previousCorrect: Bool?) -> SkillState? {
        switch (state, correct) {
        case (.notStarted, true), (.taught, true), (.revisit, true): .practising
        case (.practising, true): previousCorrect == true ? .secure : nil
        case (.secure, false): .revisit
        default: nil
        }
    }

    /// The placement: every chapter answered right before the first wrong, in position order, makes its skills secure;
    /// the rest is left.
    public static func placementChanges(_ answered: [Answer]) -> [SkillStateChange] {
        var changes: [SkillStateChange] = []
        for item in answered.sorted(by: { $0.chapter.position < $1.chapter.position }) {
            guard let correct = item.correct else { continue }
            guard correct else { break }
            changes += item.skills.map { SkillStateChange(skillID: $0.id, state: .secure) }
        }
        return changes
    }
}
