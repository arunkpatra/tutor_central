import DesignSystem
import Domain
import SwiftUI

/// The mock (P10-Mock): "Mock test" with the quiet Key, the hero, Paper with the pattern line and the sections (or the
/// key), the footer with the AI line, Make it again, Share as PDF and Mark from a photo (whose paper, when the exam has
/// several students).
struct MockView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    @State private var store: MockStore
    let showsKey: Bool
    @State private var topInset: CGFloat = 0
    @State private var pdf: URL?
    @State private var choosing = false

    init(store: MockStore, showsKey: Bool) {
        _store = State(initialValue: store)
        self.showsKey = showsKey
    }

    static let footnote = "AI can make mistakes. Check every question before you give it. Marking from a photo uses "
        + "this paper's key."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Mock test", action: (store.form == .key ? "Paper" : "Key", toggleForm)) { dismiss() }
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
            if store.mock != nil {
                footer
            }
        }
        .overlay {
            if choosing {
                GlassMenu(
                    eyebrow: "Whose paper?",
                    rows: store.students.map { student in
                        GlassMenuRow(label: student.name, symbol: nil) { store.mark(student) }
                    },
                    alignment: .bottom
                ) { choosing = false }
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .task {
            await store.load()
            if showsKey {
                store.form = .key
            }
        }
        .task(id: PDFKey(form: store.form, artefact: store.artefact?.id)) {
            pdf = await store.sharedPDF(withKey: store.form == .key)
        }
    }

    @ViewBuilder private var content: some View {
        if let failed = store.loadFailed {
            Card { EmptyRow(symbol: "doc", title: failed, line: "Go back and open it from today's plan.") }
        } else if let mock = store.mock {
            ResultHero(eyebrow: store.eyebrow, title: store.title, line: store.line)
            MockPaper(mock: mock, key: store.form == .key, patternLine: store.patternLine)
                .opacity(store.making ? Tokens.opacityStale : 1)
        } else {
            Card { SkeletonRow() }
        }
    }

    private var footer: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text(Self.footnote).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Make it again") { Task { _ = await store.again() } }
                    .buttonStyle(.quiet(emphasised: true))
                HStack(spacing: Tokens.tileGap) {
                    if let pdf {
                        ShareLink(item: pdf) { Label("Share as PDF", systemImage: "square.and.arrow.up") }
                            .buttonStyle(.secondary(.form))
                    } else {
                        Button {} label: { Label("Share as PDF", systemImage: "square.and.arrow.up") }
                            .buttonStyle(.secondary(.form)).disabled(true)
                    }
                    Button(action: markFromPhoto) { Label("Mark from a photo", systemImage: "camera").singleLineTitle()
                    }
                    .buttonStyle(.primary(.form))
                    .disabled(!store.canMark || store.students.isEmpty)
                }
                .environment(\.buttonIconSize, Tokens.iconSmall)
                .disabled(store.making)
            }
        }
    }

    private func toggleForm() {
        store.form = store.form == .key ? .paper : .key
    }

    private func markFromPhoto() {
        let students = store.students
        if students.count == 1, let only = students.first {
            store.mark(only)
        } else {
            choosing = true
        }
    }
}

/// The paper by section (V1's paper rows: the section head with its marks each, each question with its marks), or the
/// key: each answer under its question.
struct MockPaper: View {
    let mock: MockContent
    let key: Bool
    let patternLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            HStack {
                Text(key ? "Key" : "Paper").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                Spacer()
                Text(key ? "for you" : patternLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .padding(.horizontal, Tokens.rowGapInner)
            Card {
                VStack(spacing: 0) {
                    ForEach(mock.sections) { section in
                        SectionRow(title: section.name, line: MockStore.marksEach(section.marksEach))
                        ForEach(section.questions) { question in
                            let last = question.id == section.questions.last?.id && section.id == mock.sections.last?.id
                            if key {
                                KeyRow(
                                    number: question.number, question: question.text, answer: question.answer,
                                    isLast: last
                                )
                            } else {
                                QuestionRow(
                                    number: question.number, text: question.text, marks: "\(question.marks)",
                                    isLast: last
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/// What the PDF is made from: the form and the artefact.
private struct PDFKey: Hashable {
    let form: MockStore.Form
    let artefact: UUID?
}
