import DesignSystem
import Domain
import SwiftUI

/// A worked example (P10-WorkedExample): the nav row with Show all, the hero with the problem and the intro, the Steps
/// card with "2 of 4", the footer with Show the next step and the slip under it.
struct WorkedExampleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store: WorkedExampleStore
    /// The board's state: the second step shown.
    let showsTwo: Bool
    @State private var topInset: CGFloat = 0

    init(store: WorkedExampleStore, showsTwo: Bool = false) {
        _store = State(initialValue: store)
        self.showsTwo = showsTwo
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Worked example", action: ("Show all", { store.showAll() })) { dismiss() }
                content
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
        .safeAreaInset(edge: .bottom) {
            if store.example != nil {
                footer
            }
        }
        .task {
            await store.load()
            if showsTwo {
                store.showNext()
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let failed = store.loadFailed {
            Card { EmptyRow(symbol: "doc", title: failed, line: "Go back and open it from today's plan.") }
        } else if let example = store.example {
            ResultHero(eyebrow: store.eyebrow, title: store.title, line: store.intro)
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Steps").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                    Spacer()
                    Text(store.countText).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
                .padding(.horizontal, Tokens.rowGapInner)
                Card {
                    VStack(spacing: 0) {
                        ForEach(Array(example.steps.enumerated()), id: \.offset) { index, step in
                            StepRow(
                                number: index + 1, title: step.title, working: step.working,
                                shown: index < store.shown
                            )
                            .rowDivider(index < example.steps.count - 1)
                        }
                    }
                }
            }
        } else {
            Card { SkeletonRow() }
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
                Button {
                    withAnimation(ReducedMotion.animation(.default, reduce: reduceMotion)) { store.showNext() }
                } label: {
                    Label("Show the next step", systemImage: "chevron.down")
                }
                .buttonStyle(.primary(.card))
                .disabled(!store.canShowNext)
                Text(store.slip).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
