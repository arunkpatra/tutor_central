import SwiftUI

/// A pushed screen's top row without the system bar: Back (the round icon button), the title `headline` centred, and an
/// optional quiet action on the right (Reports' Share).
public struct BackRow: View {
    let title: String
    let back: () -> Void
    let action: (label: String, run: () -> Void)?

    public init(title: String, action: (label: String, run: () -> Void)? = nil, back: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.back = back
    }

    public var body: some View {
        ZStack {
            Text(title)
                .typeStyle(Tokens.headline)
                .foregroundStyle(Tokens.text.color)
                .lineLimit(1)
                .padding(.horizontal, IconButton.size + Tokens.inline)
                .accessibilityAddTraits(.isHeader)
            HStack {
                IconButton(symbol: "chevron.left", label: "Back", action: back)
                Spacer()
                if let action {
                    Button(action.label, action: action.run).buttonStyle(.quiet)
                }
            }
        }
    }
}

#Preview {
    BackRow(title: "Hemanth's fees") {}
        .padding(Tokens.pageSide)
        .background(Tokens.ground.color)
}
