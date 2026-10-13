import SwiftUI

/// Words and formulae drawn together (D102): the words in SF Pro through the type token, each inline formula drawn by
/// SwiftMath at the token's point size (Dynamic Type's) in the colour of the appearance, sitting on the text's
/// baseline,
/// so a formula flows with the words and grows with them; a display formula (`$$…$$`) on its own centred line at 1.25×
/// with the dense row padding above and below. A formula that does not parse is shown as its LaTeX, in `text2`, so a
/// slip never hides a question (P20-Kit-Maths). VoiceOver reads the formulae in words (`MathSpeech`). A text with no
/// `$` is plain text.
public struct MathText: View {
    let text: String
    let token: TypeToken
    let color: ColorToken
    let alignment: HorizontalAlignment

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme
    /// The line's width, so a formula wider than it is drawn to fit (the largest text sizes).
    @State private var width = CGFloat.infinity

    public init(
        _ text: String,
        style token: TypeToken = Tokens.body,
        color: ColorToken = Tokens.text,
        alignment: HorizontalAlignment = .leading
    ) {
        self.text = text
        self.token = token
        self.color = color
        self.alignment = alignment
    }

    public var body: some View {
        let runs = Self.spaced(MathSplit.runs(text))
        Group {
            if runs.allSatisfy(Self.isWords) {
                Text(text).foregroundStyle(color.color)
            } else {
                VStack(alignment: alignment, spacing: Tokens.rowPaddingDense) {
                    ForEach(Array(Self.lines(runs).enumerated()), id: \.offset) { _, line in
                        switch line {
                        case let .flow(pieces): flow(pieces)
                        case let .display(latex): display(latex)
                        }
                    }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            }
        }
        .typeStyle(token)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(MathSpeech.words(text)))
    }

    /// Words and inline formulae as one `Text`, so they wrap together.
    private func flow(_ pieces: [MathRun]) -> Text {
        let size = token.scaledSize(at: typeSize)
        let ink = uiColor(color)
        return pieces.reduce(Text(verbatim: "")) { line, piece in
            switch piece {
            case let .text(words):
                return Text("\(line)\(Text(verbatim: words).foregroundStyle(color.color))")
            case let .inline(latex), let .display(latex):
                // Display style in the line too: a fraction stacked full height, as the boards draw it.
                guard let drawn = MathRenderer.rendered(
                    latex: weighted(latex),
                    pointSize: size,
                    color: ink,
                    display: true,
                    fitting: width
                )
                else {
                    return Text("\(line)\(Text(verbatim: latex).foregroundStyle(Tokens.text2.color))")
                }
                return Text("\(line)\(Text(Image(uiImage: drawn.image)).baselineOffset(-drawn.descent))")
            }
        }
    }

    private func display(_ latex: String) -> some View {
        let size = token.scaledSize(at: typeSize) * 1.25
        return HStack {
            Spacer(minLength: 0)
            if let drawn = MathRenderer.rendered(
                latex: weighted(latex),
                pointSize: size,
                color: uiColor(color),
                display: true,
                fitting: width
            ) {
                Image(uiImage: drawn.image)
            } else {
                Text(verbatim: latex).foregroundStyle(Tokens.text2.color)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Tokens.rowPaddingDense)
    }

    /// A formula in a semibold or heavier token (the board view's 44/52 800, its key's title3) set bold, as the words
    /// beside it: letters bold italic (`\\bm`), and each number bold upright (`\\mathbf`), since bold italic has no
    /// digits and SwiftMath draws them regular.
    nonisolated static func weighted(_ latex: String, weight: Int) -> String {
        guard weight >= 600 else { return latex }
        let digits = latex.replacing(/[0-9]+(\.[0-9]+)?/) { "\\mathbf{\($0.output.0)}" }
        return "\\bm{\(digits)}"
    }

    private func weighted(_ latex: String) -> String {
        Self.weighted(latex, weight: token.weightNumber)
    }

    private func uiColor(_ token: ColorToken) -> UIColor {
        (scheme == .dark ? token.dark : token.light).uiColor
    }

    private static func isWords(_ run: MathRun) -> Bool {
        if case .text = run {
            true
        } else {
            false
        }
    }

    enum Line {
        case flow([MathRun])
        case display(String)
    }

    /// A formula's edge spaces as word spaces (SwiftMath drops spaces at a formula's edges, so "3 सेब + 2" lost its
    /// gaps): a space is added where the words beside it have none. The PDF's split does the same.
    nonisolated static func spaced(_ runs: [MathRun]) -> [MathRun] {
        var out: [MathRun] = []
        for (index, run) in runs.enumerated() {
            guard case let .inline(latex) = run else {
                out.append(run)
                continue
            }
            let trimmed = latex.trimmingCharacters(in: .whitespaces)
            if latex.first?.isWhitespace == true, let before = out.last, !endsWithSpace(before) {
                out.append(.text(" "))
            }
            out.append(.inline(binary(trimmed)))
            if latex.last?.isWhitespace == true, index + 1 < runs.count, !startsWithSpace(runs[index + 1]) {
                out.append(.text(" "))
            }
        }
        return out
    }

    private nonisolated static let operators = ["+", "-", "−", "\\times", "\\pm", "\\div", "\\cdot"]

    /// A formula that opens or closes on a binary operator keeps the operator's space beside it (TeX's medium space,
    /// `\>`): SwiftMath reads a leading `+` as a sign and drops its spaces, and honours neither an empty group nor
    /// `\mathbin`. A relation (`=`) keeps its own space.
    private nonisolated static func binary(_ latex: String) -> String {
        var out = latex
        if let op = operators.first(where: { out.hasPrefix($0) }) {
            out = op + "\\>" + out.dropFirst(op.count)
        }
        if let op = operators.first(where: { out.hasSuffix($0) }) {
            out = out.dropLast(op.count) + "\\>" + op
        }
        return out
    }

    private nonisolated static func endsWithSpace(_ run: MathRun) -> Bool {
        if case let .text(words) = run {
            words.last?.isWhitespace == true
        } else {
            false
        }
    }

    private nonisolated static func startsWithSpace(_ run: MathRun) -> Bool {
        if case let .text(words) = run {
            words.first?.isWhitespace == true
        } else {
            false
        }
    }

    /// The runs grouped into lines: words and inline formulae flow together; a display formula is a line of its own.
    nonisolated static func lines(_ runs: [MathRun]) -> [Line] {
        var lines: [Line] = []
        var flow: [MathRun] = []
        for run in runs {
            if case let .display(latex) = run {
                if !flow.isEmpty {
                    lines.append(.flow(flow))
                }
                flow = []
                lines.append(.display(latex))
            } else {
                flow.append(run)
            }
        }
        if !flow.isEmpty {
            lines.append(.flow(flow))
        }
        return lines
    }
}
