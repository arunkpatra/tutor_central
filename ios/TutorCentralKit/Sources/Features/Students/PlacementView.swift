import DesignSystem
import Domain
import SwiftUI

/// The placement (P10-Placement), pushed from Place <name> on the student's page: the footnote, per subject a card of
/// check rows with its count, Done in the footer; Done goes back to the page, whose card reads the new status.
public struct PlacementView: View {
    @State private var store: PlacementStore
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?

    /// `boardTaps` are P10-Placement's answers, tapped once the questions are in.
    private let boardTaps: [Bool?]

    public init(store: PlacementStore, boardTaps: [Bool?] = []) {
        _store = State(initialValue: store)
        self.boardTaps = boardTaps
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: store.title) { dismiss() }
                Text(store.footnote)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text2.color)
                    .padding(.horizontal, Tokens.rowGapInner)
                if store.loading, store.subjects.allSatisfy(\.rows.isEmpty) {
                    Card {
                        VStack(spacing: 0) {
                            SkeletonRow().rowDivider()
                            SkeletonRow(widths: (0.4, 0.65))
                        }
                    }
                }
                ForEach($store.subjects) { $subject in
                    PlacementSubjectCard(subject: $subject) { Task { await store.retry(subject.id) } }
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FooterButton {
                VStack(spacing: Tokens.inline) {
                    Button("Done") {
                        Task {
                            if await store.finish() {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(.primary(.card, loading: store.finishing))
                    .disabled(!store.canFinish)
                    Text(store.doneFootnote).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                }
            }
        }
        .onChange(of: store.failure) { _, failure in
            guard let failure else { return }
            notices?.show(failure)
            store.failure = nil
        }
        .task {
            if store.subjects.isEmpty {
                await store.load()
                for (index, tap) in boardTaps.enumerated()
                    where store.subjects.first?.rows.indices.contains(index) == true {
                    store.subjects[0].rows[index].tap = tap
                }
            }
        }
    }
}

/// One subject of the placement (also inside the close): the title and its count, then the check rows, or the in-place
/// failure with Try again.
struct PlacementSubjectCard: View {
    @Binding var subject: PlacementStore.SubjectRows
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            HStack(alignment: .firstTextBaseline) {
                Text(subject.title).typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                Spacer()
                if !subject.rows.isEmpty {
                    Text(subject.countLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
            }
            .padding(.horizontal, Tokens.rowGapInner)
            Card {
                if let failure = subject.failure {
                    ErrorRow(title: "Couldn't make the questions.", line: failure, retry: retry)
                } else {
                    VStack(spacing: 0) {
                        ForEach($subject.rows) { $row in
                            CheckRow(skill: row.skill, question: row.question, answer: row.answer, tap: $row.tap)
                                .rowDivider()
                        }
                    }
                }
            }
        }
    }
}
