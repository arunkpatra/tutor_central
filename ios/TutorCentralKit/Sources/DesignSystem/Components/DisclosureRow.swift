import SwiftUI

/// A question that opens its answer (Help, P7-Help-Answer): the question in rowTitle with `chevron.down` in text3;
/// open, `chevron.up` and the answer in rowLine text2 under it, 32 short of the right edge. One open at a time is the
/// caller's rule.
public struct DisclosureRow: View {
    let question: String
    let answer: String
    let isOpen: Bool
    let toggle: () -> Void
    static var answerInset: CGFloat {
        32
    }

    public init(question: String, answer: String, isOpen: Bool, toggle: @escaping () -> Void) {
        self.question = question
        self.answer = answer
        self.isOpen = isOpen
        self.toggle = toggle
    }

    public var body: some View {
        Button(action: toggle) {
            VStack(alignment: .leading, spacing: Tokens.inline) {
                HStack(spacing: Tokens.rowPaddingDense) {
                    Text(question)
                        .typeStyle(Tokens.rowTitle)
                        .foregroundStyle(Tokens.text.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: Tokens.iconInline, weight: .semibold))
                        .foregroundStyle(Tokens.text3.color)
                        .accessibilityHidden(true)
                }
                if isOpen {
                    Text(answer)
                        .typeStyle(Tokens.rowLine)
                        .foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, Self.answerInset)
                }
            }
            .padding(.vertical, Tokens.rowPaddingVertical)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityValue(isOpen ? "Open" : "Closed")
        .accessibilityHint(isOpen ? "Hides the answer" : "Shows the answer")
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            DisclosureRow(question: "Does it work without a connection?", answer: "Mostly.", isOpen: true) {}
                .rowDivider()
            DisclosureRow(question: "How do I delete my account?", answer: "Settings → Account.", isOpen: false) {}
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
