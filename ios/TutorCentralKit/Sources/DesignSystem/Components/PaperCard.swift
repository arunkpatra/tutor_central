import SwiftUI

/// Result hero (P6-Result-Paper): a hero card with the eyebrow, the title in title2 and a footnote line in text2.
public struct ResultHero: View {
    let eyebrow: String
    let title: String
    let line: String

    public init(eyebrow: String, title: String, line: String) {
        self.eyebrow = eyebrow
        self.title = title
        self.line = line
    }

    public var body: some View {
        Card(.hero) {
            VStack(alignment: .leading, spacing: Tokens.tileGap) {
                Eyebrow(eyebrow)
                Text(title).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// A paper card's section row: a surface2 band with the title (15 700) and "1 mark each" (footnote, text2), padding
/// 12 × 16, a hairline under it.
public struct SectionRow: View {
    let title: String
    let line: String

    public init(title: String, line: String) {
        self.title = title
        self.line = line
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.tileGap) {
            Text(title).typeStyle(Tokens.buttonStrong).foregroundStyle(Tokens.text.color)
            Spacer(minLength: Tokens.inline)
            Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .background(Tokens.surface2.color)
        .overlay(alignment: .bottom) { Rectangle().fill(Tokens.line.color).frame(height: Tokens.hairline) }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A paper card's question row: the number in a 24 pt column (15 600 text2, tabular), the text (subhead), the marks
/// on the right (footnote text3, tabular) when a paper has them; padding 12 × 16, a hairline under all but the last.
public struct QuestionRow: View {
    let number: Int
    let text: String
    let marks: String?
    let isLast: Bool
    static var numberColumn: CGFloat {
        24
    }

    public init(number: Int, text: String, marks: String?, isLast: Bool) {
        self.number = number
        self.text = text
        self.marks = marks
        self.isLast = isLast
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.tileGap) {
            Text("\(number).")
                .typeStyle(Tokens.buttonSecondary)
                .monospacedDigit()
                .foregroundStyle(Tokens.text2.color)
                .frame(minWidth: Self.numberColumn, alignment: .leading)
                .fixedSize()
            Text(text)
                .typeStyle(Tokens.subhead)
                .foregroundStyle(Tokens.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            if let marks {
                Text(marks).typeStyle(Tokens.footnote).monospacedDigit().foregroundStyle(Tokens.text3.color)
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Tokens.line.color).frame(height: Tokens.hairline)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        ResultHero(
            eyebrow: "Class 10 Maths · Mathematics",
            title: "Quadratic equations",
            line: "10 questions · 20 marks"
        )
        Card {
            VStack(spacing: 0) {
                SectionRow(title: "Section A", line: "1 mark each")
                QuestionRow(number: 1, text: "Write the discriminant of 2x² − 4x + 3 = 0.", marks: "1", isLast: false)
                QuestionRow(number: 2, text: "If one root of x² − 5x + k = 0 is 2, find k.", marks: "1", isLast: true)
            }
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
