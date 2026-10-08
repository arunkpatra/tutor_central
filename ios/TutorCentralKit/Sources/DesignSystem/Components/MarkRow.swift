import SwiftUI

/// Mark tile (P6-Check-Result): 36 high, at least 64 wide, surface2, a line border, radius 10, "2 / 4" in accentText
/// 15 700 tabular; a tap opens the marks popover.
public struct MarkTile: View {
    let marks: Int
    let of: Int
    let action: () -> Void
    static var height: CGFloat {
        36
    }

    static var minWidth: CGFloat {
        64
    }

    public init(marks: Int, of: Int, action: @escaping () -> Void) {
        self.marks = marks
        self.of = of
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text("\(marks) / \(of)")
                .typeStyle(Tokens.buttonStrong)
                .monospacedDigit()
                .foregroundStyle(Tokens.accentText.color)
                .padding(.horizontal, Tokens.tileGap)
                .frame(minWidth: Self.minWidth, minHeight: Self.height, maxHeight: Self.height)
                .background(Tokens.surface2.color, in: .rect(cornerRadius: Tokens.radiusSegment, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.radiusSegment, style: .continuous)
                        .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
                )
        }
        .pressable()
        .accessibilityLabel("\(marks) of \(of) marks")
        .accessibilityHint("Change the mark")
    }
}

/// Mark row: "4. Nature of the roots" (rowTitle), the AI's note (footnote text2) with "· Changed from 1" in ok 600 once
/// the tutor changed it, and the mark tile; padding 12 × 16, a hairline under all but the last.
public struct MarkRow<Tile: View>: View {
    let number: Int
    let text: String
    let note: String
    let changedFrom: Int?
    let isLast: Bool
    let tile: Tile

    public init(
        number: Int, text: String, note: String, changedFrom: Int?, isLast: Bool, @ViewBuilder tile: () -> Tile
    ) {
        self.number = number
        self.text = text
        self.note = note
        self.changedFrom = changedFrom
        self.isLast = isLast
        self.tile = tile()
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text("\(number). \(text)").typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                noteLine.typeStyle(Tokens.footnote).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            tile
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Tokens.line.color).frame(height: Tokens.hairline)
            }
        }
    }

    private var noteLine: Text {
        let base = Text(note).foregroundStyle(Tokens.text2.color)
        guard let changedFrom else { return base }
        let changed = Text(" · Changed from \(changedFrom)").foregroundStyle(Tokens.ok.color).fontWeight(.semibold)
        return Text("\(base)\(changed)")
    }
}

/// The marks popover's content (P6-Check-MarkPicker): the eyebrow "Marks for question 4" and a chip for every mark
/// from 0 to the question's, the current one on; 200 wide (padding 10 × 12).
public struct MarkPicker: View {
    let number: Int
    let of: Int
    let selected: Int
    let choose: (Int) -> Void
    public static var width: CGFloat {
        200
    }

    public init(number: Int, of: Int, selected: Int, choose: @escaping (Int) -> Void) {
        self.number = number
        self.of = of
        self.selected = selected
        self.choose = choose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.inline) {
            Eyebrow("Marks for question \(number)")
            FlowLayout(spacing: Tokens.inline) {
                ForEach(0 ... max(0, of), id: \.self) { mark in
                    FilterChip("\(mark)", isOn: mark == selected) { choose(mark) }
                }
            }
        }
        .padding(.vertical, Tokens.tileGap)
        .padding(.horizontal, Tokens.rowPaddingDense)
        .frame(width: Self.width, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        Card {
            VStack(spacing: 0) {
                MarkRow(
                    number: 4,
                    text: "Nature of the roots",
                    note: "Says real and distinct",
                    changedFrom: nil,
                    isLast: false
                ) { MarkTile(marks: 0, of: 1) {} }
                MarkRow(
                    number: 6,
                    text: "Roots of 3x² − 2√6 x + 2 = 0",
                    note: "Method right",
                    changedFrom: 1,
                    isLast: true
                ) { MarkTile(marks: 2, of: 2) {} }
            }
        }
        MarkPicker(number: 4, of: 4, selected: 2) { _ in }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
