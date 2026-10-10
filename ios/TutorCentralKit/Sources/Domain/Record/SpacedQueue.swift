import Foundation

/// Which skills the close checks (plan decision 6, the first version; Phase 12 refines it with the plan): the most
/// recently taught first, then the most overdue by its state's interval. A skill not started is never checked.
public enum SpacedQueue {
    public static let count = 3

    /// Days until a skill in this state is due again; nil for a skill not started.
    public static func interval(for state: SkillState) -> Int? {
        switch state {
        case .notStarted: nil
        case .taught, .revisit: 1
        case .practising: 3
        case .secure: 7
        }
    }

    /// At most `count` skills: the eligible one with the latest state change, then the rest by how overdue they are;
    /// ties by chapter position, then skill position.
    public static func pick(skills: [Skill], chapters: [Chapter], now: Date, calendar: Calendar) -> [Skill] {
        let positions = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0.position) })
        func order(_ skill: Skill) -> (Int, Int) {
            (positions[skill.chapterID] ?? Int.max, skill.position)
        }
        func overdue(_ skill: Skill) -> Int {
            let since = skill.lastCheckedAt ?? skill.stateAt
            let days = calendar.dateComponents([.day], from: since, to: now).day ?? 0
            return days - (interval(for: skill.state) ?? 0)
        }
        let eligible = skills.filter { interval(for: $0.state) != nil }
        guard let current = eligible.max(by: { lhs, rhs in
            lhs.stateAt != rhs.stateAt ? lhs.stateAt < rhs.stateAt : order(lhs) > order(rhs)
        }) else { return [] }
        let rest = eligible.filter { $0.id != current.id }.sorted { lhs, rhs in
            let (left, right) = (overdue(lhs), overdue(rhs))
            return left != right ? left > right : order(lhs) < order(rhs)
        }
        return Array(([current] + rest).prefix(count))
    }
}
