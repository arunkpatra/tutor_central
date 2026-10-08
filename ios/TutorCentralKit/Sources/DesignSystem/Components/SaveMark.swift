import SwiftUI

/// The mark beside a section saved as you go (P2-Settings, P5-Payments): "Saving…" in text3 while the write runs,
/// then "Saved" with a tick in `ok`; nothing before the first save.
public struct SaveMark: View {
    let saving: Bool
    let saved: Bool

    public init(saving: Bool, saved: Bool) {
        self.saving = saving
        self.saved = saved
    }

    public var body: some View {
        if saving {
            Text("Saving…").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
        } else if saved {
            Label("Saved", systemImage: "checkmark")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.chipNeutralLabel)
                .foregroundStyle(Tokens.ok.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }
}
