import DesignSystem
import Domain
import Foundation

/// The page's small words: a chapter's states, a skill's mark, a message's symbol, the pronouns.
extension StudentDetailStore {
    /// "4 of 4 secure", "2 of 3 secure · 1 practising", "1 secure · 1 revisit · 2 to come", "Not started".
    nonisolated static func statesLine(_ states: [SkillState]) -> String {
        let count = { (state: SkillState) in states.count { $0 == state } }
        let toCome = count(.notStarted)
        guard toCome < states.count else { return "Not started" }
        let others = [(SkillState.practising, "practising"), (.taught, "taught"), (.revisit, "revisit")]
            .compactMap { count($0.0) > 0 ? "\(count($0.0)) \($0.1)" : nil }
        let secure = toCome == 0 ? "\(count(.secure)) of \(states.count) secure"
            : count(.secure) > 0 ? "\(count(.secure)) secure" : nil
        let rest = toCome > 0 ? "\(toCome) to come" : nil
        return ([secure] + others.map(Optional.some) + [rest]).compactMap(\.self).joined(separator: " · ")
    }

    nonisolated static func mark(_ state: SkillState) -> SkillMark {
        switch state {
        case .secure: .secure
        case .practising: .practising
        case .taught: .taught
        case .revisit: .revisit
        case .notStarted: .notStarted
        }
    }

    nonisolated static func symbol(_ kind: MessageKind) -> String {
        switch kind {
        case .reminder: "bell"
        case .receipt: "doc.text"
        case .absence: "person.crop.circle.badge.exclamationmark"
        case .consent: "checkmark.shield"
        default: "text.bubble"
        }
    }

    nonisolated static func daysSinceMonday(_ weekday: Weekday) -> Int {
        weekday.rawValue - Weekday.monday.rawValue
    }

    /// "she stands", "he stands", "they stand", and her, his, their.
    struct Pronouns {
        let subject: String
        let possessive: String
        let verb: String
    }

    nonisolated static func pronouns(_ gender: Gender?) -> Pronouns {
        switch gender {
        case .female: Pronouns(subject: "she", possessive: "her", verb: "stands")
        case .male: Pronouns(subject: "he", possessive: "his", verb: "stands")
        case .other, nil: Pronouns(subject: "they", possessive: "their", verb: "stand")
        }
    }

    nonisolated static func possessive(_ gender: Gender?) -> String {
        pronouns(gender).possessive
    }
}
