import DesignSystem
import Domain
import SwiftUI

/// Share as PDF (P6-Result-Paper): the result drawn on A4 pages (595 × 842 pt, 40 pt margins) in the app's type, light,
/// as a file in the temporary directory named after the title.
public enum PDFMaker {
    static var page: CGRect {
        CGRect(x: 0, y: 0, width: 595, height: 842)
    }

    static var margin: CGFloat {
        40
    }

    public enum Failure: Error {
        case noContext
    }

    @MainActor public static func pdf(for result: GenerationResult, title: String) throws -> URL {
        let width = page.width - 2 * margin
        let renderer = ImageRenderer(content: PDFContent(result: result, title: title).frame(width: width))
        renderer.proposedSize = ProposedViewSize(width: width, height: nil)
        let data = NSMutableData()
        var box = page
        guard let consumer = CGDataConsumer(data: data),
              let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { throw Failure.noContext }
        renderer.render { size, draw in
            let pageHeight = page.height - 2 * margin
            var offset: CGFloat = 0
            repeat {
                context.beginPDFPage(nil)
                context.saveGState()
                context.clip(to: page.insetBy(dx: margin, dy: margin))
                // PDF space is y-up: the content's top sits at the page's top margin, moved up a page each time.
                context.translateBy(x: margin, y: page.height - margin - size.height + offset)
                draw(context)
                context.restoreGState()
                context.endPDFPage()
                offset += pageHeight
            } while offset < size.height
        }
        context.closePDF()
        let url = FileManager.default.temporaryDirectory.appending(path: "\(fileName(title)).pdf")
        try (data as Data).write(to: url, options: .atomic)
        return url
    }

    /// A title as a file name: no slashes or colons.
    nonisolated static func fileName(_ title: String) -> String {
        title.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
    }
}

/// What the PDF shows: the title, then the paper's sections and numbered questions with their marks, then the answer
/// key; homework and worksheets without marks; a note its text. Always light: a page is printed on white.
private struct PDFContent: View {
    let result: GenerationResult
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            Text(title).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
            switch result {
            case let .paper(paper):
                ForEach(paper.sections) { section in
                    block("\(section.title) (\(marks(section.marksEach)) each)") {
                        ForEach(section.questions) { question in
                            line(question.number, question.text, marks: "(\(question.marks))")
                        }
                    }
                }
                key(paper.questions.map { (number: $0.number, answer: $0.answer) })
            case let .homework(set), let .worksheet(set):
                if let instructions = set.instructions {
                    Text(instructions).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                }
                VStack(alignment: .leading, spacing: Tokens.inline) {
                    ForEach(set.questions) { line($0.number, $0.text, marks: nil) }
                }
                key(set.questions.map { (number: $0.number, answer: $0.answer) })
            case let .progressNote(note):
                Text(note.note).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.colorScheme, .light)
    }

    private func block(_ heading: String, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.inline) {
            Text(heading).typeStyle(Tokens.buttonStrong).foregroundStyle(Tokens.text.color)
            rows()
        }
    }

    private func line(_ number: Int, _ text: String, marks: String?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.tileGap) {
            Text("\(number).").typeStyle(Tokens.buttonSecondary).foregroundStyle(Tokens.text2.color)
            Text(text).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let marks {
                Text(marks).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            }
        }
    }

    private func key(_ answers: [(number: Int, answer: String)]) -> some View {
        block("Answer key") {
            ForEach(answers, id: \.number) { line($0.number, $0.answer, marks: nil) }
        }
    }

    private func marks(_ count: Int) -> String {
        count == 1 ? "1 mark" : "\(count) marks"
    }
}
