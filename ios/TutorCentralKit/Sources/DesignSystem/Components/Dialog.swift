import SwiftUI

/// A confirmation: surface1, lineStrong border, radiusSheet, shadowDialog, padding 22, 14 between parts; title title2,
/// body subhead text2; Cancel (secondary) then the action (primary, or solid destructive). A destructive dialog that
/// removes history asks for the name typed (`confirmName`), and the action waits for it; `loading` shows the action
/// running. Warning haptic on appearance.
/// Drawn over `dim` by its presenter.
public struct DialogView: View {
    let title: String
    let message: String
    let cancel: String
    let action: String
    let destructive: Bool
    let confirmName: String?
    let loading: Bool
    let onCancel: () -> Void
    let onAction: () -> Void
    @State private var typed = ""
    static var padding: CGFloat {
        22
    }

    public init(
        title: String,
        message: String,
        cancel: String = "Cancel",
        action: String,
        destructive: Bool,
        confirmName: String? = nil,
        loading: Bool = false,
        onCancel: @escaping () -> Void,
        onAction: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.cancel = cancel
        self.action = action
        self.destructive = destructive
        self.confirmName = confirmName
        self.loading = loading
        self.onCancel = onCancel
        self.onAction = onAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.cardPaddingCompact) {
            Text(title).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
            Text(message).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
            if let confirmName {
                TextField(text: $typed, prompt: Text(confirmName).foregroundStyle(Tokens.text3.color)) {
                    Text("Type \(confirmName) to confirm")
                }
                .typeStyle(Tokens.body)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .frame(height: Well<EmptyView>.height)
                .padding(.horizontal, Tokens.cardPaddingCompact)
                .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                        .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
                )
            }
            HStack(spacing: Tokens.tileGap) {
                Button(cancel, action: onCancel).buttonStyle(.secondary())
                if destructive {
                    Button(action, action: onAction)
                        .buttonStyle(.destructive(solid: true, loading: loading))
                        .disabled(!confirmed || loading)
                } else {
                    Button(action, action: onAction).buttonStyle(.primary())
                }
            }
        }
        .padding(Self.padding)
        .background(Tokens.surface1.color, in: .rect(cornerRadius: Tokens.radiusSheet, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radiusSheet, style: .continuous)
                .strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline)
        )
        .shadowed(Tokens.shadowDialog, radius: Tokens.radiusSheet)
        .onAppear { Haptic.play(.warning) }
    }

    private var confirmed: Bool {
        guard let confirmName else { return true }
        return Self.confirms(typed: typed, name: confirmName)
    }

    /// The typed name matches ignoring case and the spaces around it ("akshita " confirms "Akshita").
    public static func confirms(typed: String, name: String) -> Bool {
        typed.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(name) == .orderedSame
    }
}
