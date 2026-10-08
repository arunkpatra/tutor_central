import DesignSystem
import Domain
import SwiftUI

/// A result (P6-Result-Paper, -Light, -Regenerating), pushed: the hero, the paper (sections, questions, the answer
/// key), and the footer with the AI line, Create again, Copy and Share as PDF. A progress note is NoteResultView's.
/// Creating again keeps this one at 0.55 until the new one lands; AppShell pushes the new one over it.
public struct ResultView: View {
    let store: AIStore
    let generationID: UUID
    let boardState: AIBoardState?
    let onMessage: (String) -> Void
    let onMissing: () -> Void
    @State private var generation: Generation?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    /// `onMissing`: the result is not here (a stale link); AppShell takes the screen off the stack.
    public init(
        store: AIStore, generationID: UUID, boardState: AIBoardState? = nil, onMessage: @escaping (String) -> Void,
        onMissing: @escaping () -> Void
    ) {
        self.store = store
        self.generationID = generationID
        self.boardState = boardState
        self.onMessage = onMessage
        self.onMissing = onMissing
    }

    private var regenerating: Bool {
        store.inFlight?.regenerating == generationID
    }

    public var body: some View {
        Group {
            if let generation, generation.kind == .progressNote {
                NoteResultView(store: store, generation: generation, boardState: boardState, onMessage: onMessage)
            } else {
                paperScreen
            }
        }
        .task {
            await store.prepare()
            generation = await store.generation(generationID)
            if generation == nil {
                onMissing()
            }
            if boardState == .regenerating, let generation {
                _ = store.createAgain(generation)
            }
        }
    }

    private var paperScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: generation?.kind.title ?? "Result") { dismiss() }
                if let generation {
                    content(generation).opacity(regenerating ? Tokens.opacityStale : 1)
                } else {
                    Card { SkeletonRow() }
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
            if let generation {
                ResultFooter(store: store, generation: generation, regenerating: regenerating, onMessage: onMessage)
            }
        }
    }

    @ViewBuilder
    private func content(_ generation: Generation) -> some View {
        let classID = generation.request?.classID
        let className = store.className(classID) ?? "No class"
        let subject = store.register.classroom(classID)?.subject ?? subjectOf(generation.request)
        ResultHero(
            eyebrow: [className, subject].compactMap(\.self).joined(separator: " · "),
            title: generation.title(studentName: store.studentName),
            line: generation.heroLine(today: store.today, calendar: store.calendar)
        )
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            HStack {
                Text(generation.kind == .paper ? "Paper" : generation.kind.title)
                    .typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                Spacer()
                if regenerating {
                    HStack(spacing: Tokens.inline) {
                        RefreshSpinner()
                        Text("Creating again").typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    }
                }
            }
            .padding(.horizontal, Tokens.rowGapInner)
            Card {
                VStack(spacing: 0) { rows(generation) }
            }
        }
    }

    @ViewBuilder
    private func rows(_ generation: Generation) -> some View {
        switch generation.result {
        case let .paper(paper):
            ForEach(paper.sections) { section in
                SectionRow(title: section.title, line: "\(marks(section.marksEach)) each")
                ForEach(section.questions) { question in
                    QuestionRow(number: question.number, text: question.text, marks: "\(question.marks)", isLast: false)
                }
            }
            key(paper.questions.map { (number: $0.number, answer: $0.answer) }, title: "Answer key")
        case let .homework(set), let .worksheet(set):
            SectionRow(title: set.title, line: set.instructions ?? "")
            ForEach(set.questions) { question in
                QuestionRow(number: question.number, text: question.text, marks: nil, isLast: false)
            }
            key(set.questions.map { (number: $0.number, answer: $0.answer) }, title: keyTitle(generation))
        case .progressNote:
            EmptyView()
        }
    }

    @ViewBuilder
    private func key(_ answers: [(number: Int, answer: String)], title: String) -> some View {
        SectionRow(title: title, line: "")
        ForEach(answers, id: \.number) { item in
            QuestionRow(number: item.number, text: item.answer, marks: nil, isLast: item.number == answers.last?.number)
        }
    }

    private func keyTitle(_ generation: Generation) -> String {
        if case let .worksheet(form)? = generation.request, !form.withAnswers {
            return "Answer key (for you)"
        }
        return "Answer key"
    }

    private func subjectOf(_ request: GenerateRequest?) -> String? {
        switch request {
        case let .paper(form): form.subject
        case let .homework(form): form.subject
        case let .worksheet(form): form.subject
        default: nil
        }
    }

    private func marks(_ count: Int) -> String {
        count == 1 ? "1 mark" : "\(count) marks"
    }
}
