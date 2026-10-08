import SwiftUI

/// A month title in headline with two 32 round chevron buttons (18, accentText): inside the calendar card on
/// Schedule, above a list on History (components.md, Calendar month).
public struct MonthHeader: View {
    let title: String
    let previous: () -> Void
    let next: () -> Void
    static var buttonSize: CGFloat {
        32
    }

    public init(title: String, previous: @escaping () -> Void, next: @escaping () -> Void) {
        self.title = title
        self.previous = previous
        self.next = next
    }

    public var body: some View {
        HStack(spacing: Tokens.inline) {
            Text(title).typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Tokens.inline)
            chevron("chevron.left", label: "Previous month", action: previous)
            chevron("chevron.right", label: "Next month", action: next)
        }
    }

    private func chevron(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Tokens.iconSmall, weight: .semibold))
                .foregroundStyle(Tokens.accentText.color)
                .frame(width: Self.buttonSize, height: Self.buttonSize)
                .contentShape(.circle)
        }
        .pressable()
        .accessibilityLabel(label)
    }
}

#Preview {
    MonthHeader(title: "October 2026", previous: {}, next: {})
        .padding(Tokens.pageSide)
        .background(Tokens.ground.color)
}
