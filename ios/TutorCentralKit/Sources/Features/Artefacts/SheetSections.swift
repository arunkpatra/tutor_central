import DesignSystem
import Domain
import SwiftUI

/// The sheet as Paper (the section row "1 mark each" and the numbered questions) or Key (each answer under its
/// question, "Answers · for you").
struct SheetBody: View {
    let store: SheetStore

    var body: some View {
        if let sheet = store.sheet {
            let key = store.form == .key
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                Text(key ? "Key" : "Sheet").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                    .padding(.horizontal, Tokens.rowGapInner)
                Card {
                    VStack(spacing: 0) {
                        SectionRow(
                            title: key ? "Answers" : sheet.instructions ?? sheet.title,
                            line: key ? "for you" : "1 mark each"
                        )
                        ForEach(sheet.questions) { question in
                            let last = question.id == sheet.questions.last?.id
                            if key {
                                KeyRow(
                                    number: question.number,
                                    question: question.text,
                                    answer: question.answer,
                                    isLast: last
                                )
                            } else {
                                QuestionRow(number: question.number, text: question.text, marks: "1", isLast: last)
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The board, full screen (P10-Sheet-Board): one question at a time, the key under it when asked.
struct SheetBoard: View {
    let store: SheetStore

    var body: some View {
        if let question = store.boardQuestion {
            BoardView(
                eyebrow: store.sheet?.instructions, question: question.text, number: question.number,
                count: store.sheet?.questions.count ?? 0, answer: question.answer, showsKey: store.boardShowsKey,
                previous: store.previousQuestion, next: store.nextQuestion, done: { store.form = .paper },
                toggleKey: { store.boardShowsKey.toggle() }
            )
        }
    }
}

/// The footer band (components.md "Result footer, V2"): the AI line, the quiet Make it again, Share as PDF and Print.
struct SheetFooter: View {
    let store: SheetStore
    let pdf: URL?

    var body: some View {
        FooterButton {
            VStack(spacing: Tokens.rowPaddingDense) {
                Text(ArtefactWords.aiLine)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Make it again") {}
                    .buttonStyle(.quiet(emphasised: true))
                HStack(spacing: Tokens.tileGap) {
                    if let pdf {
                        ShareLink(item: pdf) { Label("Share as PDF", systemImage: "square.and.arrow.up") }
                            .buttonStyle(.secondary(.form))
                    } else {
                        Button {} label: { Label("Share as PDF", systemImage: "square.and.arrow.up") }
                            .buttonStyle(.secondary(.form)).disabled(true)
                    }
                    Button {
                        if let pdf {
                            Printer.print(pdf, title: store.title)
                        }
                    } label: { Label("Print", systemImage: "printer") }
                        .buttonStyle(.secondary(.form))
                        .disabled(pdf == nil)
                }
            }
        }
    }
}
