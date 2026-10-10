import SwiftUI

/// A note over a plan line (P10-Today-Plan-Changed): a student moved here today, or a line skipped today.
public enum PlanLineNote: Hashable, Sendable {
    case movedFrom(Int)
    case skipped(String)

    public var words: String {
        switch self {
        case let .movedFrom(group): "Moved here from Group \(group)"
        case let .skipped(words): words
        }
    }
}

/// One item of a plan line's second line: "Practise set 1", "Check 3", "Homework sheet 1"; struck when skipped today.
public struct LineBit: Hashable, Sendable {
    public let text: String
    public let struck: Bool

    public init(text: String, struck: Bool) {
        self.text = text
        self.struck = struck
    }
}

/// A student's line in a group card (components.md "Plan line"): avatar 36, the name `rowTitle`, an optional note
/// (`caption` 600, `accentText` for a move, `text3` for a skip), the teach line led by the status word, the rest
/// `footnote` `text2` with a skipped item struck through in `text3`, the chevron. The whole line presses; a long press
/// is the caller's `contextMenu`.
public struct PlanLineRow: View {
    let initials: String
    let name: String
    let status: (word: String, kind: TrackKind)?
    let note: PlanLineNote?
    let teachLine: String
    let rest: [LineBit]
    let onPress: () -> Void

    public init(
        initials: String, name: String, status: (word: String, kind: TrackKind)?, note: PlanLineNote?,
        teachLine: String, rest: [LineBit], onPress: @escaping () -> Void
    ) {
        self.initials = initials
        self.name = name
        self.status = status
        self.note = note
        self.teachLine = teachLine
        self.rest = rest
        self.onPress = onPress
    }

    /// "Practise set 1 · Check 3 · Homework sheet 1".
    public nonisolated static func restText(_ bits: [LineBit]) -> String {
        bits.map(\.text).joined(separator: " · ")
    }

    public var body: some View {
        Button(action: onPress) {
            HStack(alignment: .top, spacing: Tokens.rowPaddingDense) {
                Avatar(initials: initials, size: 36)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    if let note {
                        Text(note.words)
                            .typeStyle(Tokens.captionStrong)
                            .foregroundStyle(noteColor(note).color)
                    }
                    teach.typeStyle(Tokens.footnote)
                    restLine.typeStyle(Tokens.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Chevron().padding(.top, Tokens.rowGapInner)
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .pressable()
        .accessibilityElement(children: .combine)
    }

    private var teach: Text {
        guard let status else { return Text(teachLine).foregroundStyle(Tokens.text.color) }
        return Text(status.word).foregroundStyle(status.kind.color.color).fontWeight(.semibold)
            + Text(" · \(teachLine)").foregroundStyle(Tokens.text.color)
    }

    private var restLine: Text {
        rest.enumerated().reduce(Text("")) { line, entry in
            let (index, bit) = entry
            let separator = index == 0 ? Text("") : Text(" · ").foregroundStyle(Tokens.text2.color)
            let piece = Text(bit.text).strikethrough(bit.struck)
                .foregroundStyle((bit.struck ? Tokens.text3 : Tokens.text2).color)
            return line + separator + piece
        }
    }

    private func noteColor(_ note: PlanLineNote) -> ColorToken {
        if case .movedFrom = note {
            return Tokens.accentText
        }
        return Tokens.text3
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            PlanLineRow(
                initials: "DK", name: "Dev Kumar", status: ("Not on track", .notOnTrack), note: nil,
                teachLine: "Teach again: Balancing equations, with the worked example",
                rest: [
                    LineBit(text: "Practise set 1", struck: false), LineBit(text: "Check 3", struck: false),
                    LineBit(text: "Homework sheet 1", struck: true),
                ],
                onPress: {}
            )
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
