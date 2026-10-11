import SwiftUI

/// The note's well (components.md 10.6, P10-Note): "The note · Hindi" over it with the counter "212 of 600" on the
/// right (overdue past the limit), the editable note in body at least 200 high, the helper under it.
public struct NoteWell: View {
    let title: String
    @Binding var text: String
    let limit: Int
    let helper: String
    let showsFocus: Bool
    @FocusState private var focused: Bool
    static var minHeight: CGFloat {
        200
    }

    public init(title: String, text: Binding<String>, limit: Int, helper: String, showsFocus: Bool = false) {
        self.title = title
        _text = text
        self.limit = limit
        self.helper = helper
        self.showsFocus = showsFocus
    }

    /// "212 of 600" and whether it is past the limit; the count is the caller's (Unicode scalars, D48).
    public static func counter(_ count: Int, limit: Int) -> (text: String, over: Bool) {
        ("\(count.formatted()) of \(limit.formatted())", count > limit)
    }

    public var body: some View {
        let counter = Self.counter(text.unicodeScalars.count, limit: limit)
        let shape = RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            HStack {
                Text(title).foregroundStyle(Tokens.text2.color)
                Spacer()
                Text(counter.text).monospacedDigit()
                    .foregroundStyle((counter.over ? Tokens.overdue : Tokens.text3).color)
            }
            .typeStyle(Tokens.footnote)
            TextEditor(text: $text)
                .typeStyle(Tokens.body)
                .foregroundStyle(Tokens.text.color)
                .tint(Tokens.accent.color)
                .scrollContentBackground(.hidden)
                .focused($focused)
                .frame(minHeight: Self.minHeight, alignment: .topLeading)
                .padding(.horizontal, Tokens.cardPaddingCompact - Tokens.inline)
                .padding(.vertical, Tokens.rowPaddingDense - Tokens.inline)
                .background(Tokens.well.color, in: shape)
                .overlay(shape.strokeBorder(
                    (counter.over ? Tokens.overdue : focused || showsFocus ? Tokens.accent : Tokens.line).color,
                    lineWidth: Tokens.hairline
                ))
                .shadowed(
                    focused || showsFocus ? [Tokens.shadowWell, Tokens.haloFocus] : [Tokens.shadowWell],
                    radius: Tokens.radiusControl
                )
                .accessibilityLabel(title)
            Text(helper).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// "In English, for you": the English beside a message, on surface2 in rowLine text2 (components.md 10.5).
public struct EnglishBlock: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text("In English, for you").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            Text(text)
                .typeStyle(Tokens.rowLine)
                .foregroundStyle(Tokens.text2.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Tokens.cardPaddingCompact)
                .background(Tokens.surface2.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
        }
    }
}

/// "What it says" (P10-Note): a list card of facts, each an icon tile beside the label over the fact in footnote text2.
public struct FactsCard: View {
    public struct Row: Hashable, Sendable {
        let label: String
        let fact: String
        let symbol: String

        public init(label: String, fact: String, symbol: String) {
            self.label = label
            self.fact = fact
            self.symbol = symbol
        }
    }

    let title: String
    let rows: [Row]

    public init(title: String, rows: [Row]) {
        self.title = title
        self.rows = rows
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title)
            Card {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        ListRow(action: nil) {
                            IconTile(symbol: row.symbol)
                            RowTitles(title: row.label, subtitle: row.fact)
                        }
                        .rowDivider(index < rows.count - 1)
                    }
                }
            }
        }
    }
}

/// "Moved up" (P10-CanNowDo): the area and its line, five bars, the steps under them: the secure ones in ok, the step
/// shown in accent, the rest surface2 and text3.
public struct LadderStrip: View {
    let area: String
    let steps: [String]
    let current: Int
    let line: String
    static var barHeight: CGFloat {
        6
    }

    public init(area: String, steps: [String], current: Int, line: String) {
        self.area = area
        self.steps = steps
        self.current = current
        self.line = line
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
                AdaptiveRow {
                    Text(area).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    AdaptiveSpacer(minLength: Tokens.inline)
                    Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
                HStack(alignment: .top, spacing: Tokens.rowGapInner * 2) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        VStack(spacing: Tokens.rowGapInner * 2) {
                            Capsule().fill(tone(index).bar.color).frame(height: Self.barHeight)
                            Text(step)
                                .typeStyle(index == current ? Tokens.captionStrong : Tokens.caption)
                                .foregroundStyle(tone(index).text.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(Tokens.cardPaddingCompact)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(area): \(steps.indices.contains(current) ? steps[current] : ""). \(line)")
        }
    }

    private func tone(_ index: Int) -> (bar: ColorToken, text: ColorToken) {
        if index < current {
            return (Tokens.ok, Tokens.ok)
        }
        return index == current ? (Tokens.accent, Tokens.accentText) : (Tokens.surface2, Tokens.text3)
    }
}
