import DesignSystem
import Domain
import SwiftUI

/// Make something (P10-Make, -Light), pushed from More and from Today's Create row: the intro line, the five kinds for
/// a student or a group, the four for the tutor, Recent (three, See all opens History), and the AI line.
public struct MakeHomeView: View {
    let store: MakeStore
    let actions: MakeActions
    /// A launch state's picture of Recent (`make-empty`): the home opens scrolled to it.
    let startsAtRecent: Bool
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: MakeStore, actions: MakeActions, startsAtRecent: Bool = false) {
        self.store = store
        self.actions = actions
        self.startsAtRecent = startsAtRecent
    }

    public var body: some View {
        ScrollViewReader { proxy in
            page.onChange(of: store.historyLoaded) { _, loaded in
                if loaded, startsAtRecent {
                    proxy.scrollTo(Self.recentAnchor, anchor: .bottom)
                }
            }
        }
    }

    private static let recentAnchor = "recent"

    private var page: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Make something", action: ("History", actions.openHistory)) { dismiss() }
                Text(MakeWords.homeLead)
                    .typeStyle(Tokens.intro)
                    .foregroundStyle(Tokens.text2.color)
                    .padding(.horizontal, Tokens.rowGapInner)
                kinds("For a student or a group", MakeKind.forSomeone)
                kinds("For you", MakeKind.forYou)
                recent.id(Self.recentAnchor)
                Text(AIWords.homeLine)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .padding(.horizontal, Tokens.rowGapInner)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadHistory() }
    }

    private func kinds(_ title: String, _ kinds: [MakeKind]) -> some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title)
            Card {
                VStack(spacing: 0) {
                    ForEach(kinds, id: \.self) { kind in
                        ToolRow(symbol: kind.symbol, title: kind.title, line: kind.line) { actions.openForm(kind) }
                    }
                }
            }
        }
    }

    @ViewBuilder private var recent: some View {
        if store.showsEmpty {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("Recent")
                Card { EmptyRow(symbol: "sparkles", title: MakeWords.emptyTitle, line: MakeWords.emptyLine) }
            }
        } else if !store.recent.isEmpty {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("Recent", action: ("See all", actions.openHistory))
                Card {
                    VStack(spacing: 0) {
                        ForEach(store.recent) { row in
                            ResultRow(symbol: row.symbol, title: row.title, line: row.line) { actions.open(row.opens) }
                        }
                    }
                }
            }
        }
    }
}
