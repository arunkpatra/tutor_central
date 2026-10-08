/// A result as plain text, for Copy: the title, the sections and numbered questions, the answer key last; a note is
/// its text.
public enum PaperText {
    public static func plain(_ result: GenerationResult) -> String {
        switch result {
        case let .paper(paper):
            let sections = paper.sections.map { section in
                let questions = section.questions.map { "\($0.number). \($0.text) (\(marks($0.marks)))" }
                return (["\(section.title) (\(marks(section.marksEach)) each)"] + questions).joined(separator: "\n")
            }
            let key = paper.questions.map { "\($0.number). \($0.answer)" }
            return ([paper.title] + sections + [(["Answer key"] + key).joined(separator: "\n")])
                .joined(separator: "\n\n")
        case let .homework(set), let .worksheet(set):
            let questions = set.questions.map { "\($0.number). \($0.text)" }.joined(separator: "\n")
            let key = (["Answer key"] + set.questions.map { "\($0.number). \($0.answer)" }).joined(separator: "\n")
            return ([set.title, set.instructions, questions, key].compactMap(\.self)).joined(separator: "\n\n")
        case let .progressNote(note):
            return note.note
        }
    }

    private static func marks(_ count: Int) -> String {
        count == 1 ? "1 mark" : "\(count) marks"
    }
}
