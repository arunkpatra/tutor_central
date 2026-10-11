import Foundation

/// The next step in the plan (Phase 14; plan/phase-14-plan.md decision 9): the teach line a step makes, the skill a
/// step back teaches first, Today's caption until the parent is told, and the skills "Add it to the checks" puts first.
extension PlanRules {
    /// The teach line for the student's step (plan/phase-14-plan.md decision 9): telling the parent and teaching again
    /// both teach again with the worked example; stepping back teaches the skill before first; the rest teach as usual.
    static func teachWords(_ skill: String, step: NextStep, before: String?) -> String {
        switch step {
        case .tellParent, .teachAgain: "Teach again: \(skill), with the worked example"
        case .stepBack:
            before.map { "Step back: \($0), then \(skill)" } ?? "Teach again: \(skill), with the worked example"
        case .addToChecks, .leave: "Teach: \(skill)"
        }
    }

    /// The skill before this one: the one before it in its chapter, else the last of the chapter before.
    static func skillBefore(_ skill: Skill, chapters: [Chapter], skills: [Skill]) -> Skill? {
        let position = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0.position) })
        let ordered = skills.sorted { lhs, rhs in
            let (left, right) = (position[lhs.chapterID] ?? 0, position[rhs.chapterID] ?? 0)
            return left != right ? left < right : lhs.position < rhs.position
        }
        guard let index = ordered.firstIndex(where: { $0.id == skill.id }), index > 0 else { return nil }
        return ordered[index - 1]
    }

    /// "Since Fri 9 Oct · tell Ramesh after the class" on a not-on-track student's teach line until the parent is told.
    static func caption(_ student: Student, step: NextStep, input: PlanInput) -> String? {
        guard student.trackStatus == .notOnTrack, step == .tellParent, !input.told.contains(student.id) else {
            return nil
        }
        let who = student.parentName.flatMap { $0.split(
            separator: " "
        ).first }.map { "tell \($0)" } ?? "tell the parent"
        let since = student.trackSince.map { "Since \(Day($0, calendar: input.calendar).shortWeekdayText) · " } ?? ""
        return "\(since)\(who) after the class"
    }

    /// The skills put at the head of a student's own checks: the current skill when the step is "Add it to the checks".
    static func checkHeads(_ students: [Student], input: PlanInput) -> [UUID: [Skill]] {
        var heads: [UUID: [Skill]] = [:]
        for student in students where [.watch, .notOnTrack].contains(student.trackStatus)
            && student.effectiveStep == .addToChecks {
            let chapters = input.chapters[student.id] ?? []
            if let current = TrackingRules.currentSkill(skills: input.skills[student.id] ?? [], chapters: chapters) {
                heads[student.id] = [current]
            }
        }
        return heads
    }
}
