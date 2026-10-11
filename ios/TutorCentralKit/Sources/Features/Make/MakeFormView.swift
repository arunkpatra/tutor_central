import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on a Make form: the For sheet open (P10-Make-For) at a segment, or Make tapped.
public enum MakeBoardState: Hashable, Sendable {
    case forSheet(ForStore.Segment)
    case making
}

/// A kind's form (P10-Make-Form), pushed from Make something: one card of the kind's tiles, the helper, and Make in the
/// footer. Making holds the form under the creating card; a failure shows the error row with Retry. The call is the
/// shell's store's: leaving the screen does not lose it.
public struct MakeFormView: View {
    @State private var store: MakeFormStore
    let boardState: MakeBoardState?
    let setUp: ((MakeFormStore) -> Void)?
    let onOutcome: (MakeOutcome, MakeFormStore) -> Void
    @State var sheet: MakeFormSheet?
    @State var typingSubject = false
    @State var typingChapter = false
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(
        store: @autoclosure () -> MakeFormStore, boardState: MakeBoardState? = nil,
        setUp: ((MakeFormStore) -> Void)? = nil, onOutcome: @escaping (MakeOutcome, MakeFormStore) -> Void
    ) {
        _store = State(initialValue: store())
        self.boardState = boardState
        self.setUp = setUp
        self.onOutcome = onOutcome
    }

    var form: MakeFormStore {
        store
    }

    private var making: Bool {
        store.make.running?.kind == store.kind
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: store.kind.title) { dismiss() }
                Card(.hero) {
                    VStack(alignment: .leading, spacing: Tokens.cardPaddingCompact) { fields }
                }
                .opacity(making ? Tokens.opacityDisabled : 1)
                .allowsHitTesting(!making)
                below
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
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { footer }
        .task {
            await store.prepare()
            setUp?(store)
            switch boardState {
            case let .forSheet(segment)?: sheet = .forWhom(segment)
            case .making?: make()
            case nil: break
            }
        }
        .sheet(item: $sheet) { which in sheetContent(which) }
    }

    @ViewBuilder private var below: some View {
        if making, let running = store.make.running {
            CreatingCard(title: running.title, line: AIWords.creatingLine) { store.make.cancel() }
        } else if let failure = store.make.failure, failure.kind == store.kind {
            ErrorRow(
                title: MakeWords.failedTitle, line: AIWords.failedLine(failure.message),
                retry: failure.canRetry ? { make() } : nil
            )
        } else if let helper = store.helper {
            Text(helper)
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Button {
                    make()
                } label: {
                    Label(store.kind.makeLabel, systemImage: "sparkles")
                }
                .buttonStyle(.primary(.card, loading: making))
                .disabled(!store.canMake)
                Text(AIWords.creatingLine)
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    func make() {
        guard !making else { return }
        Keyboard.dismiss()
        let store = store
        Task {
            let outcome = await store.make()
            onOutcome(outcome, store)
        }
    }
}
