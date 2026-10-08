import DesignSystem
import Domain
import SwiftUI

/// The AI Assistant (P6-Assistant, -Light, -Empty), pushed from More and from Today's Create row: the lead line, the
/// four tools, the three most recent results (See all opens History), and the AI line.
public struct AssistantView: View {
    let store: AIStore
    let actions: AIToolsActions
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: AIStore, actions: AIToolsActions) {
        self.store = store
        self.actions = actions
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "AI Assistant", action: ("History", actions.openHistory)) { dismiss() }
                Text(AIWords.homeLead)
                    .typeStyle(Tokens.intro)
                    .foregroundStyle(Tokens.text2.color)
                    .padding(.horizontal, Tokens.rowGapInner)
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    SectionHeader("Create")
                    Card {
                        VStack(spacing: 0) {
                            ForEach(GenerationKind.allCases, id: \.self) { kind in
                                ToolRow(symbol: kind.symbol, title: kind.title, line: kind.line) {
                                    actions.openForm(kind)
                                }
                            }
                        }
                    }
                }
                recent
                Text(AIWords.homeLine)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .padding(.horizontal, Tokens.rowGapInner)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadHistory() }
    }

    @ViewBuilder private var recent: some View {
        if store.historyLoaded, store.recent.isEmpty {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("Recent")
                Card { EmptyRow(symbol: "sparkles", title: AIWords.emptyTitle, line: AIWords.emptyLine) }
            }
        } else if !store.recent.isEmpty {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("Recent", action: ("See all", actions.openHistory))
                Card {
                    VStack(spacing: 0) {
                        ForEach(store.recent) { generation in
                            ResultRow(
                                symbol: generation.kind.symbol,
                                title: generation.title(studentName: store.studentName),
                                line: generation.line(className: store.className, calendar: store.calendar)
                            ) { actions.openResult(generation.id) }
                        }
                    }
                }
            }
        }
    }
}
