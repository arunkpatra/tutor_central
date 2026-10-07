import DesignSystem
import Domain
import SwiftUI

/// Today with nothing in it yet, to P2-Today-Empty-Dark and -Light: the date and greeting, three counts, the first
/// step, and the two empty sections. The greeting is the title; the tab's navigation bar is hidden.
public struct TodayView: View {
    let store: TodayStore
    let actions: TodayActions

    public init(store: TodayStore, actions: TodayActions) {
        self.store = store
        self.actions = actions
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                header
                tiles
                if let error = store.error {
                    refreshError(error)
                }
                startHere
                section("Today", action: ("Schedule", { actions.openLater(.schedule) })) {
                    EmptyRow(
                        symbol: "calendar",
                        title: "No classes yet",
                        line: "Classes you create show here on the days they meet, with one tap to mark attendance."
                    )
                }
                section("Tasks", action: ("Add", { actions.openLater(.tasks) })) {
                    EmptyRow(
                        symbol: "checkmark.circle",
                        title: "Nothing on your list",
                        line: "Add a task when there's something to remember."
                    )
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .refreshable {
            await store.load()
            Haptic.play(.impactLight)
        }
        .task { await store.load() }
    }

    @State private var topInset: CGFloat = 0

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                Eyebrow(store.heading)
                Text(store.greeting)
                    .typeStyle(Tokens.displayCompact)
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer(minLength: Tokens.inline)
            IconButton(initials: store.initials, label: "Account and settings", action: actions.openSettings)
        }
    }

    private var tiles: some View {
        HStack(spacing: Tokens.tileGap) {
            StatTile(value: "\(store.counts.students)", label: "Students", tone: tone(store.counts.students)) {
                actions.openTab(.students)
            }
            StatTile(
                value: store.counts.due.formatted,
                label: "Due",
                tone: store.counts.due == .zero ? .zero : .due
            ) { actions.openTab(.fees) }
            StatTile(
                value: "\(store.counts.classesToday)",
                label: "Classes today",
                tone: tone(store.counts.classesToday)
            ) {
                actions.openLater(.schedule)
            }
        }
        .opacity(store.loading ? Tokens.opacityStale : 1)
    }

    private func tone(_ count: Int) -> StatTone {
        count == 0 ? .zero : .plain
    }

    private func refreshError(_ error: String) -> some View {
        HStack {
            Label(error, systemImage: "exclamationmark.triangle")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
            Spacer()
            Button("Retry") { Task { await store.load() } }.buttonStyle(.quiet)
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }

    private var startHere: some View {
        Card(.hero) {
            VStack(alignment: .leading, spacing: Tokens.cardPaddingCompact) {
                Eyebrow("Start here", accent: true, strong: true)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                    Text("Add your first students").typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
                    Text("Type them in one by one, or photograph your paper register and we'll read it.")
                        .typeStyle(Tokens.subhead)
                        .foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: Tokens.tileGap) {
                    Button { actions.openLater(.students) } label: {
                        Label("Add a student", systemImage: "plus").typeStyle(Tokens.buttonStrong)
                    }
                    .buttonStyle(.primary())
                    Button { actions.openLater(.students) } label: {
                        Label("Scan register", systemImage: "viewfinder")
                    }
                    .buttonStyle(.secondary())
                }
                .environment(\.buttonIconSize, Tokens.iconSmall)
            }
        }
    }

    private func section(
        _ title: String,
        action: (label: String, run: () -> Void),
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(title, action: action)
            Card { content() }
        }
    }
}

/// An empty section's one row, as the Today board draws it: the symbol 28 in text3, then the title and its line.
struct EmptyRow: View {
    let symbol: String
    let title: String
    let line: String
    static var symbolSize: CGFloat {
        28
    }

    var body: some View {
        HStack(spacing: Tokens.cardPaddingCompact) {
            Image(systemName: symbol)
                .font(.system(size: Self.symbolSize, weight: .light))
                .foregroundStyle(Tokens.text3.color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(title).typeStyle(Tokens.rowHeading).foregroundStyle(Tokens.text.color)
                Text(line)
                    .typeStyle(Tokens.rowLine)
                    .foregroundStyle(Tokens.text2.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Tokens.rowPaddingHorizontal)
        .accessibilityElement(children: .combine)
    }
}
