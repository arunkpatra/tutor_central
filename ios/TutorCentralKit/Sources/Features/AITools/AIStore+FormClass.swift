import Data
import Domain
import Foundation

/// Where a paper, homework or worksheet form starts (P12-Form-Paper-Class, -NoClass): the class by level, the last
/// class and subject of its kind kept on this iPhone.
extension AIStore {
    /// What a kind's last form was for.
    struct Remembered: Hashable {
        let classLevel: ClassLevel?
        let subject: String
    }

    /// The last class chosen for the kind, else the class most of the centre's students are in (a tie goes to the
    /// higher class); nil when neither is known (Class reads Choose).
    static func startingLevel(students: [Student], remembered: ClassLevel?) -> ClassLevel? {
        if let remembered {
            return remembered
        }
        let counts = Dictionary(grouping: students.compactMap(\.classLevel), by: \.self).mapValues(\.count)
        let ordinal = { (level: ClassLevel) in ClassLevel.allCases.firstIndex(of: level) ?? 0 }
        return counts.max { lhs, rhs in
            lhs.value != rhs.value ? lhs.value < rhs.value : ordinal(lhs.key) < ordinal(rhs.key)
        }?.key
    }

    /// Where a new form of a kind starts, from the register as read now.
    func startingLevel(for kind: GenerationKind) -> ClassLevel? {
        Self.startingLevel(
            students: register.activeStudents,
            remembered: Self.remembered(kind: kind, in: formDefaults)?
                .classLevel
        )
    }

    /// The key each kind is kept under; `Wipe` removes it at sign-out.
    static func defaultsKey(_ kind: GenerationKind) -> String {
        "aiForm.\(kind.rawValue)"
    }

    static func remembered(kind: GenerationKind, in defaults: UserDefaults?) -> Remembered? {
        guard let kept = defaults?.dictionary(forKey: defaultsKey(kind)) as? [String: String] else { return nil }
        return Remembered(classLevel: kept["class"].flatMap(ClassLevel.init(rawValue:)), subject: kept["subject"] ?? "")
    }

    /// The class and subject a form was sent with, for the next form of its kind.
    func remember(_ request: GenerateRequest) {
        guard let defaults = formDefaults, request.kind != .progressNote else { return }
        var kept: [String: String] = [:]
        kept["class"] = request.classLevel?.rawValue
        kept["subject"] = switch request {
        case let .paper(form): form.subject
        case let .homework(form): form.subject
        case let .worksheet(form): form.subject
        case .progressNote: nil
        }
        defaults.set(kept, forKey: Self.defaultsKey(request.kind))
    }
}
