import DesignSystem
import SwiftUI

/// Under the tracking card while the parent has not been told (P10-Student-NotOnTrack): the title, the line, Call and
/// Tell the parent.
struct TellParentCard: View {
    let model: TellParentModel
    let tell: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(model.title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    Text(model.line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                HStack(spacing: Tokens.tileGap) {
                    if let call = model.callURL {
                        Link(destination: call) { Label("Call", systemImage: "phone") }
                            .buttonStyle(.secondary(.row))
                    }
                    Button(action: tell) { Label("Tell the parent", systemImage: "message").singleLineTitle() }
                        .buttonStyle(.primary(.row))
                }
                .environment(\.buttonIconSize, Tokens.iconSmall)
            }
            .padding(Tokens.rowPaddingHorizontal)
        }
    }
}
