import SwiftUI

/// Paste a message (P14-School-Paste, U41): a well under its label with the system's Paste button (iOS asks nothing,
/// the tap is the permission) and the line under it.
public struct PasteWell: View {
    let label: String
    let line: String
    let onPaste: (String) -> Void

    public init(label: String, line: String, onPaste: @escaping (String) -> Void) {
        self.label = label
        self.line = line
        self.onPaste = onPaste
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            VStack(spacing: Tokens.rowPaddingDense) {
                PasteButton(payloadType: String.self) { texts in
                    onPaste(texts.joined(separator: "\n"))
                }
                .buttonBorderShape(.capsule)
                .labelStyle(.titleAndIcon)
                .tint(Tokens.accent.color)
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(Tokens.cardPaddingCompact)
            .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                    .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
            )
        }
    }
}
