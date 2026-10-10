import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on the close: scrolled to Dev with three taps (P10-Close-Scrolled), or to Riya's
/// placement with her first answers (P10-Close-Placement).
public enum CloseBoardState: Sendable {
    case scrolled
    case placement
}

/// The close (P10-Close, -Scrolled, -Placement): the batch and its day, the students' cards, Done in the footer band.
/// Done pops to Today, whose hero reads the close.
public struct CloseView: View {
    @State var store: CloseStore
    let boardState: CloseBoardState?
    /// A refused write's words, for AppShell's system alert (U33).
    let onMessage: (String) -> Void
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: CloseStore, boardState: CloseBoardState? = nil, onMessage: @escaping (String) -> Void) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.onMessage = onMessage
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                    BackRow(title: store.title) { dismiss() }
                    heading
                    VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                        SectionHeader("Students")
                        ForEach(store.students.indices, id: \.self) { index in
                            CloseStudentCard(store: store, index: index).id(store.students[index].id)
                        }
                    }
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
            .safeAreaInset(edge: .bottom, spacing: 0) { footer }
            .task {
                if !store.loaded {
                    await store.load()
                }
                await setUpBoard(proxy)
            }
            .onChange(of: store.message) { _, message in
                guard let message else { return }
                onMessage(message)
                store.message = nil
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
            Text(store.batchName)
                .typeStyle(Tokens.title1)
                .foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Text(store.batchLine).typeStyle(Tokens.subhead).monospacedDigit().foregroundStyle(Tokens.text2.color)
            Text(store.intro)
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Tokens.rowGapInner * 2)
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.inline) {
                Button("Done") {
                    Task {
                        if await store.done() {
                            Haptic.play(.success)
                            dismiss()
                        }
                    }
                }
                .buttonStyle(.primary(.card, loading: store.closing))
                .disabled(!store.loaded)
                Text(store.footnote)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// P10-Close-Scrolled: Dev's checks Right, Wrong, Right; P10-Close-Placement: Riya's first answers.
    private func setUpBoard(_ proxy: ScrollViewProxy) async {
        guard let boardState else { return }
        switch boardState {
        case .scrolled:
            guard let dev = store.students.firstIndex(where: { $0.firstName == "Dev" }) else { return }
            store.tap(dev, 0, right: true)
            store.tap(dev, 1, right: false)
            store.tap(dev, 2, right: true)
            try? await Task.sleep(for: .seconds(Tokens.panel))
            proxy.scrollTo(store.students[dev].id, anchor: .top)
        case .placement:
            guard let riya = store.students.firstIndex(where: { $0.firstName == "Riya" }) else { return }
            store.tapPlacement(riya, subject: 0, row: 0, right: true)
            try? await Task.sleep(for: .seconds(Tokens.panel))
            proxy.scrollTo(store.students[riya].id, anchor: .top)
        }
    }
}
