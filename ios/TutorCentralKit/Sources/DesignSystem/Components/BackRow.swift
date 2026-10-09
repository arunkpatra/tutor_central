import SwiftUI

/// A pushed screen's top row without the system bar: Back (the round icon button), the title `headline` centred, and an
/// optional quiet action on the right (Reports' Share).
public struct BackRow: View {
    @Environment(\.dynamicTypeSize) private var size
    let title: String
    let back: () -> Void
    let action: (label: String, run: () -> Void)?

    public init(title: String, action: (label: String, run: () -> Void)? = nil, back: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.back = back
    }

    /// At the accessibility sizes the title takes its own lines under Back and the action, leading, so it neither
    /// truncates nor runs under the action.
    public var body: some View {
        if TypeSizeLayout.stacks(size) {
            VStack(alignment: .leading, spacing: Tokens.inline) {
                buttons
                titleText.frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ZStack {
                titleText
                    .lineLimit(1)
                    .padding(.horizontal, IconButton.size + Tokens.inline)
                buttons
            }
        }
    }

    private var titleText: some View {
        Text(title)
            .typeStyle(Tokens.headline)
            .foregroundStyle(Tokens.text.color)
            .accessibilityAddTraits(.isHeader)
    }

    private var buttons: some View {
        HStack {
            IconButton(symbol: "chevron.left", label: "Back", action: back)
            Spacer()
            if let action {
                Button(action.label, action: action.run).buttonStyle(.quiet)
            }
        }
    }
}

#Preview {
    BackRow(title: "Hemanth's fees") {}
        .padding(Tokens.pageSide)
        .background(Tokens.ground.color)
}
