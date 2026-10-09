import Data
import DesignSystem
import Domain
import SwiftUI

/// The check's result route: checking (P6-Check-Checking), the failure (P6-Check-Failed), or the suggested marks
/// (P6-Check-Result, -MarkPicker, -Result-Edited, -Saved): the hero with the total and a bar, a row per question with
/// its mark tile (a popover of marks), Share in the nav row, and Save to the student's notes with Undo.
public struct CheckResultView: View {
    @Bindable var store: CheckStore
    let boardState: CheckBoardState?
    let backToPages: () -> Void
    @State private var picking: Int?
    @State private var sharing = false
    @State private var topInset: CGFloat = 0
    @State private var boardApplied = false
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toasts: ToastCenter?

    public init(store: CheckStore, boardState: CheckBoardState? = nil, backToPages: @escaping () -> Void) {
        self.store = store
        self.boardState = boardState
        self.backToPages = backToPages
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                switch store.stage {
                case .result: marks
                case let .failed(message): failed(message)
                default: checking
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if store.stage == .result {
                footer
            }
        }
        .sheet(isPresented: $store.askingConsent) {
            ConsentSheet(centreName: store.workspace.centre.name) {
                let agreed = await store.recordConsent()
                if agreed {
                    store.begin()
                }
                return agreed
            } close: {
                store.askingConsent = false
            }
        }
        .sheet(isPresented: $sharing) { ActivitySheet(text: store.shareText).presentationDetents([.medium, .large]) }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            toasts?.show(message)
            store.message = nil
        }
        .onChange(of: store.stage) { applyBoard() }
        .onAppear(perform: applyBoard)
    }

    /// Back or Cancel while checking abandons the check.
    private func leave() {
        store.cancel()
        dismiss()
    }

    private var firstPage: UIImage? {
        store.pages.first.flatMap { UIImage(data: $0.data) }
    }

    private var pagesTitle: String {
        store.pages.count == 1 ? "Checking 1 page" : "Checking \(store.pages.count) pages"
    }

    @ViewBuilder private var checking: some View {
        BackRow(title: "Check a paper", back: leave)
        let against = store.schemeMarks.map { "Against \(store.title) · \($0) marks. " } ?? "Against \(store.title). "
        CreatingCard(
            title: pagesTitle, line: against + "Usually a minute or two.", thumbnail: firstPage, cancel: nil
        )
        Button("Cancel", action: leave).buttonStyle(.quiet).frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func failed(_ message: String) -> some View {
        BackRow(title: "Check a paper") { dismiss() }
        CreatingCard(
            title: pagesTitle, line: "The pages are still here.", thumbnail: firstPage, working: false, cancel: nil
        )
        ErrorRow(
            title: "Couldn't check the paper.",
            line: message == APIFailure.offline.message
                ? "Check your connection and try again. The pages are sent again as they are." : message,
            retry: { store.begin() }
        )
        Button("Back to the pages", action: backToPages).buttonStyle(.secondary(.card))
    }

    @ViewBuilder private var marks: some View {
        BackRow(title: "Suggested marks", action: ("Share", { sharing = true })) { dismiss() }
        if let result = store.result {
            Card(.hero) {
                VStack(alignment: .leading, spacing: Tokens.tileGap) {
                    Eyebrow([store.student?.name, store.title].compactMap(\.self).joined(separator: " · "))
                    HStack(alignment: .firstTextBaseline, spacing: Tokens.inline) {
                        Text("\(result.total)").typeStyle(Tokens.numberHero).monospacedDigit()
                            .foregroundStyle(Tokens.text.color)
                            .contentTransition(.numericText())
                        Text("of \(result.outOf)").typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    }
                    ProgressBar(fraction: result.fraction, tone: nil)
                    Text(store.totalLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
                .accessibilityElement(children: .combine)
            }
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                AdaptiveRow(alignment: .firstTextBaseline, spacing: nil) {
                    Text("Questions").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                    AdaptiveSpacer()
                    Text("Tap a mark to change it").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
                .padding(.horizontal, Tokens.rowGapInner)
                Card {
                    VStack(spacing: 0) {
                        ForEach(result.questions) { question in
                            row(question, isLast: question.id == result.questions.last?.id)
                        }
                    }
                }
            }
        }
    }

    private func row(_ question: CheckResult.QuestionMark, isLast: Bool) -> some View {
        MarkRow(
            number: question.number, text: question.text, note: question.note, changedFrom: question.changedFrom,
            isLast: isLast
        ) {
            MarkTile(marks: question.marks, of: question.of) { picking = question.number }
                .disabled(store.saved)
                .popover(isPresented: Binding(
                    get: { picking == question.number }, set: {
                        if !$0 {
                            picking = nil
                        }
                    }
                )) {
                    MarkPicker(number: question.number, of: question.of, selected: question.marks) { mark in
                        withAnimation { store.set(question: question.number, to: mark) }
                        Haptic.play(.selection)
                        picking = nil
                    }
                    .presentationCompactAdaptation(.popover)
                }
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text("AI can make mistakes. Read each answer yourself; every mark is a suggestion until you save.")
                    .typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if store.saved, let name = store.student?.firstName {
                    SavedMark("Saved to \(name)'s notes")
                } else {
                    Button(store.saveLabel) { save() }
                        .buttonStyle(.primary(.card, loading: store.saving))
                }
            }
        }
    }

    private func save() {
        Task {
            guard await store.save(), let toast = store.toast else { return }
            Haptic.play(.success)
            toasts?.show(toast, action: ("Undo", { Task { _ = await store.undoSave() } }))
        }
    }

    private func applyBoard() {
        guard !boardApplied, store.stage == .result, let boardState else { return }
        boardApplied = true
        switch boardState {
        case .markPicker: picking = 4
        case .edited: store.set(question: 6, to: 2)
        case .saved:
            store.set(question: 6, to: 2)
            save()
        case .typed: break
        }
    }
}
