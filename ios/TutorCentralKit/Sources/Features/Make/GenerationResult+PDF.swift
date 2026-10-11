import DesignSystem
import Domain

/// A result as the PDF draws it (P6-Result-Paper): the paper's sections and numbered questions with their marks, then
/// the answer key (unless left out); homework and worksheets without marks; a note its text.
extension GenerationResult {
    func pdfSheet(title: String, key: Bool) -> PDFSheet {
        switch self {
        case let .paper(paper):
            let sections = paper.sections.map { section in
                PDFBlock.section(
                    title: "\(section.title) (\(Self.marks(section.marksEach)) each)",
                    lines: section.questions.map { PDFLine(number: $0.number, text: $0.text, marks: "(\($0.marks))") }
                )
            }
            let answers = paper.questions.map { PDFLine(number: $0.number, text: $0.answer, marks: nil) }
            return PDFSheet(title: title, instructions: nil, blocks: sections + (key ? [.key(answers)] : []))
        case let .homework(set), let .worksheet(set):
            let questions = set.questions.map { PDFLine(number: $0.number, text: $0.text, marks: nil) }
            let answers = set.questions.map { PDFLine(number: $0.number, text: $0.answer, marks: nil) }
            return PDFSheet(
                title: title, instructions: set.instructions,
                blocks: [.section(title: nil, lines: questions)] + (key ? [.key(answers)] : [])
            )
        case let .progressNote(note):
            return PDFSheet(title: title, instructions: nil, blocks: [.text(note.note)])
        }
    }

    private static func marks(_ count: Int) -> String {
        count == 1 ? "1 mark" : "\(count) marks"
    }
}
