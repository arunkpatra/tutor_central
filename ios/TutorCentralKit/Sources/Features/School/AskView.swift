import DesignSystem
import Domain
import SwiftUI

/// Ask parents to forward (P10-School-Ask): the message once, editable, then one row per parent with Send; "2 of 7
/// sent".
public struct AskView: View {
    @Bindable var store: AskStore
    let back: () -> Void
    @State private var topInset: CGFloat = 0
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    public init(store: AskStore, back: @escaping () -> Void) {
        self.store = store
        self.back = back
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Ask parents to forward", back: back)
                Text("One message, sent once to each parent on WhatsApp. Edit it first if you like; what they forward "
                    + "lands on this tab.")
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    .padding(.horizontal, Tokens.rowGapInner)
                NotesWell(label: "Message", text: $store.message, placeholder: "", limit: ForwardAskMessage.limit)
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    HStack {
                        SectionHeader("Parents")
                        Spacer()
                        Text(store.countLine).typeStyle(Tokens.footnote).monospacedDigit()
                            .foregroundStyle(Tokens.text2.color)
                    }
                    if store.loadFailed {
                        LoadFailedView("Couldn't load the parents.") { Task { await store.load() } }
                    } else if !store.rows.isEmpty {
                        Card {
                            VStack(spacing: 0) {
                                ForEach(store.rows) { row in
                                    ParentSendRow(
                                        initials: row.initials, name: row.name, line: row.line,
                                        state: row.sent ? .sent : .send
                                    ) { await store.send(row) }
                                        .rowDivider(row.id != store.rows.last?.id)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .scrollDismissesKeyboard(.interactively)
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .task { await store.load() }
        .onChange(of: store.notice) { _, notice in
            guard let notice else { return }
            notices?.show(notice)
            store.notice = nil
        }
    }
}
