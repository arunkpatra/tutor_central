import DesignSystem
import Domain
import SwiftUI

/// Consent on the page (P10-Student-NotKnown, -End, P10-Student-Consent-Waiting): one row in its state, the footnote
/// under the card; Ask on WhatsApp opens the ask sheet, Parent agreed and Change the record sheet.
struct ConsentSection: View {
    @Bindable var store: ConsentStore
    let ask: () -> Void
    let agreed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Consent")
            row
            if let footnote = store.footnote {
                Text(footnote)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .padding(.horizontal, Tokens.rowGapInner)
            }
        }
    }

    @ViewBuilder private var row: some View {
        switch store.state {
        case .agreed:
            ConsentRow(agreedTitle: store.title, line: store.line, change: agreed)
        case .notRecorded:
            ConsentRow(
                title: store.title,
                line: store.line,
                buttons: .init(ask: ("Ask on WhatsApp", ask), agreed: agreed)
            )
        case .waiting:
            ConsentRow(title: store.title, line: store.line, buttons: .init(ask: ("Ask again", ask), agreed: agreed))
        }
    }
}

/// The ask (P10-Consent-Ask): the message sheet with the consent message; Open WhatsApp logs the ask first (D3) and
/// copies the text too.
struct ConsentAskSheet: View {
    let store: ConsentStore
    let close: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        MessageSheet(
            title: "Ask the parent", name: store.student?.name ?? "", heading: store.askTitle,
            parentLine: store.askParentLine, text: store.message, note: store.askFootnote, canOpen: store.canAsk,
            open: {
                UIPasteboard.general.string = store.message
                if let url = await store.openWhatsApp() {
                    openURL(url)
                    close()
                }
            },
            close: close
        )
    }
}
