import Foundation

/// The marking by skill (P10-GapReport's By skill): the app's arithmetic, not the model's.
public enum GapTallies {
    /// Each skill's marks across the mock's questions, in the order the skills first appear; a question the marking
    /// missed counts nothing of its marks. The note is the first note on a question that lost marks.
    public static func bySkill(_ marking: CheckResult, mock: MockContent) -> [GapReportContent.Tally] {
        let marks = Dictionary(marking.questions.map { ($0.number, $0) }) { first, _ in first }
        var order: [String] = []
        var right: [String: Int] = [:]
        var of: [String: Int] = [:]
        var notes: [String: String] = [:]
        for question in mock.sections.flatMap(\.questions) {
            if right[question.skill] == nil {
                order.append(question.skill)
            }
            let marked = marks[question.number]
            let got = min(marked?.marks ?? 0, question.marks)
            right[question.skill, default: 0] += got
            of[question.skill, default: 0] += question.marks
            if got < question.marks, notes[question.skill] == nil, let note = marked?.note, !note.isEmpty {
                notes[question.skill] = note
            }
        }
        return order.map {
            GapReportContent.Tally(skill: $0, right: right[$0] ?? 0, of: of[$0] ?? 0, note: notes[$0])
        }
    }

    /// The weakest skills that lost marks, lowest share first (ties in the mock's order).
    public static func weakest(_ tallies: [GapReportContent.Tally], count: Int) -> [String] {
        tallies.enumerated()
            .filter { $0.element.right < $0.element.of }
            .sorted { lhs, rhs in
                let (left, right) = (lhs.element.share, rhs.element.share)
                return left != right ? left < right : lhs.offset < rhs.offset
            }
            .prefix(count)
            .map(\.element.skill)
    }
}
