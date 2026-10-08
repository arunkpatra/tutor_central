import SwiftUI

/// "Parents are told to pay <id>" with Change (secondary) and That's right (primary, a tick) (P5-Fees-Payee): a
/// compact card, padding 14 16 16, radius 16.
public struct PayeeCard: View {
    let title: String
    let line: String
    let change: () -> Void
    let confirm: () -> Void
    let confirming: Bool

    public init(
        title: String, line: String, change: @escaping () -> Void, confirm: @escaping () -> Void, confirming: Bool
    ) {
        self.title = title
        self.line = line
        self.change = change
        self.confirm = confirm
        self.confirming = confirming
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.tileGap) {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .accessibilityElement(children: .combine)
            HStack(spacing: Tokens.tileGap) {
                Button("Change", action: change).buttonStyle(.secondary(.row))
                Button(action: confirm) {
                    Label("That's right", systemImage: "checkmark")
                }
                .buttonStyle(.primary(.row, loading: confirming))
                .disabled(confirming)
            }
            .environment(\.buttonIconSize, Tokens.iconSmall)
        }
        .padding(.top, Tokens.cardPaddingCompact)
        .padding([.horizontal, .bottom], Tokens.rowPaddingHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(radius: Tokens.radiusTile)
    }
}

#Preview {
    PayeeCard(
        title: "Parents are told to pay meera@okhdfcbank", line: "Reminders carry this UPI id. Not right? Change it.",
        change: {}, confirm: {}, confirming: false
    )
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
