import SwiftUI

/// The mark beside a section saved as you go (P2-Settings, P5-Payments, P7-Settings): "Saving" with a 14 pt spinner in
/// text3 while the write runs, then "Saved" with a tick in `ok`; nothing before the first save.
public struct SaveMark: View {
    let saving: Bool
    let saved: Bool

    static var spinner: CGFloat {
        14
    }

    public init(saving: Bool, saved: Bool) {
        self.saving = saving
        self.saved = saved
    }

    public var body: some View {
        if saving {
            HStack(spacing: Tokens.fieldGap) {
                ProgressView().controlSize(.mini).tint(Tokens.text3.color).frame(
                    width: Self.spinner,
                    height: Self.spinner
                )
                Text("Saving")
            }
            .typeStyle(Tokens.chipNeutralLabel)
            .foregroundStyle(Tokens.text3.color)
            .padding(.horizontal, Tokens.rowGapInner)
            .accessibilityElement(children: .combine)
        } else if saved {
            Label("Saved", systemImage: "checkmark")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.chipNeutralLabel)
                .foregroundStyle(Tokens.ok.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }
}
