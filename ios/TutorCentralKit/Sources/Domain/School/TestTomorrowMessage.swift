import Foundation

/// Test tomorrow in English (P10-TestTomorrow; plan/phase-13-plan.md decision 19): a template on the phone, so nothing
/// about the student leaves it and no consent is asked. The other languages come from `/ai/make`.
public struct TestTomorrowMessage: Hashable, Sendable {
    public let parentName: String?
    public let studentName: String
    public let gender: Gender?
    public let title: String
    public let date: Day
    public let portions: String?
    /// The student's weakest skill among the portions'; without one the evening's sentence is general.
    public let revise: String?
    public let tutorName: String?
    public let centreName: String

    public init(
        parentName: String?, studentName: String, gender: Gender?, title: String, date: Day, portions: String?,
        revise: String?, tutorName: String?, centreName: String
    ) {
        self.parentName = parentName
        self.studentName = studentName
        self.gender = gender
        self.title = title
        self.date = date
        self.portions = portions
        self.revise = revise
        self.tutorName = tutorName
        self.centreName = centreName
    }

    public var text: String {
        let greeting = parentName.flatMap { $0.split(separator: " ").first }.map { "Hello \($0)," } ?? "Hello,"
        let child = studentName.split(separator: " ").first.map(String.init) ?? studentName
        let from = portionWords.map { ", from \($0)" } ?? ""
        let first = "\(greeting) \(child)'s \(lowered(title)) is tomorrow (\(date.weekdayLongText))\(from)."
        let evening = revise.map { "This evening, let \(pronoun) go over \($0) once." }
            ?? "This evening, a short revision will help."
        let signature = [tutorName, centreName].compactMap(\.self).joined(separator: "\n")
        return "\(first) \(evening) Thank you.\n\n\(signature)"
    }

    /// The portions as a list ("Chemical reactions and Acids, bases and salts"), or as written when they do not split.
    private var portionWords: String? {
        guard let portions = portions?.trimmingCharacters(in: .whitespacesAndNewlines), !portions.isEmpty else {
            return nil
        }
        let parts = ExamPreparation.portions(portions)
        return parts.isEmpty ? portions : ListWords.and(parts)
    }

    private var pronoun: String {
        switch gender {
        case .male: "him"
        case .female: "her"
        default: "them"
        }
    }

    /// "Science unit test" → "science unit test"; "FA2" stays.
    private func lowered(_ title: String) -> String {
        let characters = Array(title)
        guard let first = characters.first, characters.count < 2 || !characters[1].isUppercase else { return title }
        return first.lowercased() + String(characters.dropFirst())
    }
}
