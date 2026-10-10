import SwiftUI

/// The check row (components.md "Check row"): the skill as the eyebrow (caption text2), the question (subhead), then
/// the expected answer (footnote text3) and the Right | Wrong pair on a `well` track 150 wide (radius 13, padding 3,
/// segments 34 high, radius 10): Right on is `ok` with `okInk`, Wrong on `overdue` with `overdueInk`, off segments
/// text2 600. Untapped is neither; tapping the lit segment again clears it.
public struct CheckRow: View {
    let skill: String
    let question: String
    let answer: String
    @Binding var tap: Bool?
    static var trackWidth: CGFloat {
        150
    }

    static var trackRadius: CGFloat {
        13
    }

    static var trackPadding: CGFloat {
        3
    }

    static var segmentHeight: CGFloat {
        34
    }

    static var segmentRadius: CGFloat {
        10
    }

    public init(skill: String, question: String, answer: String, tap: Binding<Bool?>) {
        self.skill = skill
        self.question = question
        self.answer = answer
        _tap = tap
    }

    /// Right or Wrong set; the same one again clears.
    public nonisolated static func toggled(_ current: Bool?, tapping right: Bool) -> Bool? {
        current == right ? nil : right
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text(skill).typeStyle(Tokens.caption).foregroundStyle(Tokens.text2.color)
            Text(question)
                .typeStyle(Tokens.subhead)
                .foregroundStyle(Tokens.text.color)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Tokens.inline) {
                Text(answer)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                pair
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
    }

    private var pair: some View {
        HStack(spacing: 0) {
            segment("Right", right: true, tone: .ok)
            segment("Wrong", right: false, tone: .overdue)
        }
        .padding(Self.trackPadding)
        .frame(width: Self.trackWidth)
        .background(Tokens.well.color, in: .rect(cornerRadius: Self.trackRadius, style: .continuous))
        .sensoryFeedback(.selection, trigger: tap)
    }

    private func segment(_ label: String, right: Bool, tone: StatusTone) -> some View {
        let on = tap == right
        return Button {
            tap = Self.toggled(tap, tapping: right)
        } label: {
            Text(label)
                .typeStyle(on ? Tokens.buttonStrong : Tokens.buttonSecondary)
                .foregroundStyle((on ? tone.ink : Tokens.text2).color)
                .frame(maxWidth: .infinity, minHeight: Self.segmentHeight)
                .background(on ? tone.color.color : .clear, in: .rect(cornerRadius: Self.segmentRadius))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label), \(question)")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
