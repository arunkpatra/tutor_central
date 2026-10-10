import SwiftUI

/// One numbered line of a PDF: a question with its marks, or an answer.
public struct PDFLine: Hashable, Sendable {
    public let number: Int
    public let text: String
    public let marks: String?

    public init(number: Int, text: String, marks: String?) {
        self.number = number
        self.text = text
        self.marks = marks
    }
}

/// A part of a PDF: a section of numbered lines under an optional heading, the answer key, a paragraph, a picture.
public enum PDFBlock: Hashable, Sendable {
    case section(title: String?, lines: [PDFLine])
    case key([PDFLine])
    case text(String)
    case image(UIImage)
}

/// What a PDF shows (a paper, a sheet, a note, a figure): the title, the instructions, the blocks in order.
public struct PDFSheet: Hashable, Sendable {
    public let title: String
    public let instructions: String?
    public let blocks: [PDFBlock]

    public init(title: String, instructions: String?, blocks: [PDFBlock]) {
        self.title = title
        self.instructions = instructions
        self.blocks = blocks
    }
}

/// Share as PDF and Print (P6-Result-Paper, P10-Sheet): the sheet drawn on A4 pages (595 × 842 pt, 40 pt margins) in
/// the
/// app's type, light, as a file in the temporary directory named after the title. Rendered on the phone (spec section
/// 7).
public enum PDFMaker {
    static var page: CGRect {
        CGRect(x: 0, y: 0, width: 595, height: 842)
    }

    static var margin: CGFloat {
        40
    }

    /// The width a page's content takes, for a picture drawn to go on it (a figure).
    public static var contentWidth: CGFloat {
        page.width - 2 * margin
    }

    /// The scale a picture for a page is rendered at, sharp in print.
    public static var imageScale: CGFloat {
        3
    }

    public enum Failure: Error {
        case noContext
    }

    @MainActor public static func pdf(for sheet: PDFSheet) throws -> URL {
        let width = page.width - 2 * margin
        let renderer = ImageRenderer(content: PDFContent(sheet: sheet).frame(width: width))
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
        let url = FileManager.default.temporaryDirectory.appending(path: "\(fileName(sheet.title)).pdf")
        try (data as Data).write(to: url, options: .atomic)
        return url
    }

    /// A title as a file name: no slashes or colons.
    public nonisolated static func fileName(_ title: String) -> String {
        title.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
    }
}

/// What the PDF shows, always light: a page is printed on white.
private struct PDFContent: View {
    let sheet: PDFSheet

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            Text(sheet.title).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
            if let instructions = sheet.instructions {
                Text(instructions).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
            }
            ForEach(Array(sheet.blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case let .section(title, lines):
                    section(title) { ForEach(lines, id: \.self) { line($0) } }
                case let .key(answers):
                    section("Answer key") { ForEach(answers, id: \.self) { line($0) } }
                case let .text(text):
                    Text(text).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                        .fixedSize(horizontal: false, vertical: true)
                case let .image(image):
                    Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.colorScheme, .light)
    }

    private func section(_ heading: String?, @ViewBuilder rows: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Tokens.inline) {
            if let heading {
                Text(heading).typeStyle(Tokens.buttonStrong).foregroundStyle(Tokens.text.color)
            }
            rows()
        }
    }

    private func line(_ line: PDFLine) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.tileGap) {
            Text("\(line.number).").typeStyle(Tokens.buttonSecondary).foregroundStyle(Tokens.text2.color)
            Text(line.text).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let marks = line.marks {
                Text(marks).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            }
        }
    }
}
