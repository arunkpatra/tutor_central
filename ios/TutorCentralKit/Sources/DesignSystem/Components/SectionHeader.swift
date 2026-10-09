import SwiftUI

/// Title headline, optional quiet action on the right, 2 pt side inset so text aligns with card content. The gap to the
/// card below is the caller's stack spacing (`sectionHeaderGap`).
public struct SectionHeader: View {
    let title: String
    let action: (label: String, run: () -> Void)?
    let actionEnabled: Bool

    /// `actionEnabled` false dims the action (Generate offline, P7-Offline-Fees).
    public init(_ title: String, action: (label: String, run: () -> Void)? = nil, actionEnabled: Bool = true) {
        self.title = title
        self.action = action
        self.actionEnabled = actionEnabled
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let action {
                Button(action.label, action: action.run).buttonStyle(.quiet).disabled(!actionEnabled)
            }
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }
}

/// The eyebrow over a group: caption 600, +0.08em, upper case, text3 (accentText for the next action).
public struct Eyebrow: View {
    let text: String
    let accent: Bool
    let strong: Bool

    /// `accent` is the next action's eyebrow (accentText); `strong` its 700 weight where the board draws it.
    public init(_ text: String, accent: Bool = false, strong: Bool = false) {
        self.text = text
        self.accent = accent
        self.strong = strong
    }

    public var body: some View {
        Text(text)
            .typeStyle(strong ? Tokens.eyebrowAccent : Tokens.eyebrow)
            .foregroundStyle((accent ? Tokens.accentText : Tokens.text3).color)
    }
}
