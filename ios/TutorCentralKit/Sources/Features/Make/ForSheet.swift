import DesignSystem
import Domain
import SwiftUI

/// For whom (P10-Make-For): a floating sheet, Cancel, Student | Group | Batch | Class, the rows of the segment, and the
/// footnote. One choice closes the sheet.
struct ForSheet: View {
    @State var store: ForStore
    let pick: (MakeTarget) -> Void
    let close: () -> Void
    /// P10-Make-For: the sheet's top 252 pt down the board's 852.
    static var boardFraction: CGFloat {
        600.0 / 852
    }

    init(
        store: ForStore,
        segment: ForStore.Segment,
        pick: @escaping (MakeTarget) -> Void,
        close: @escaping () -> Void
    ) {
        store.segment = segment
        _store = State(initialValue: store)
        self.pick = pick
        self.close = close
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "For", cancel: ("Cancel", close))
            Segmented(
                options: ForStore.Segment.allCases.map { ($0, $0.title) },
                selection: Binding(get: { store.segment }, set: { store.segment = $0 })
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    Card(.onSheet) { rows }
                    if store.segment == .group || store.segment == .level {
                        Text(ForStore.footnote)
                            .typeStyle(Tokens.footnote)
                            .foregroundStyle(Tokens.text3.color)
                            .padding(.horizontal, Tokens.rowGapInner)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .boardDetents(Self.boardFraction)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
        .task { await store.load() }
    }

    private var rows: some View {
        VStack(spacing: 0) {
            switch store.segment {
            case .student:
                ForEach(store.students) { student in
                    ChoiceRow(
                        symbol: "person", title: student.name, line: store.className(student.classID) ?? "No batch",
                        chosen: store.chosen == .student(student.id)
                    ) { pick(.student(student.id)) }
                }
            case .group:
                if store.loaded, store.groups.isEmpty {
                    EmptyRow(symbol: "person.2", title: ForStore.groupsEmptyTitle, line: store.groupsEmptyLine)
                } else {
                    choiceRows(store.groups, symbol: "person.2")
                }
            case .batch:
                choiceRows(store.batches, symbol: "book.closed")
            case .level:
                ForEach(store.levels, id: \.self) { level in
                    ChoiceRow(
                        symbol: "graduationcap", title: level.title, line: nil,
                        chosen: store.chosen == .classLevel(level)
                    ) { pick(.classLevel(level)) }
                }
            }
        }
    }

    private func choiceRows(_ rows: [ForStore.Row], symbol: String) -> some View {
        ForEach(rows) { row in
            ChoiceRow(symbol: symbol, title: row.title, line: row.line, chosen: store.chosen == row.target) {
                pick(row.target)
            }
        }
    }
}

/// Skill or topic: the record's skills for the target, then a field to type a topic.
struct SkillChooserSheet: View {
    let choices: [String]
    let chosen: String
    let pick: (String) -> Void
    let close: () -> Void
    @State private var typed = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Skill or topic", cancel: ("Cancel", close))
            Card(.onSheet) {
                VStack(spacing: 0) {
                    ForEach(choices, id: \.self) { skill in
                        ChoiceRow(
                            symbol: "book.closed",
                            title: skill,
                            line: "From the record",
                            chosen: skill == chosen
                        ) {
                            pick(skill)
                        }
                    }
                    AddFieldRow(placeholder: "Type a topic", text: $typed) {
                        let topic = typed.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !topic.isEmpty {
                            pick(topic)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }
}

/// The mock's exam: the student's exams to come, nearest first, then Type it.
struct ExamChooserSheet: View {
    let exams: [SchoolItem]
    let chosen: ExamChoice?
    let pick: (ExamChoice) -> Void
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: "Exam", cancel: ("Cancel", close))
            Card(.onSheet) {
                VStack(spacing: 0) {
                    ForEach(exams) { exam in
                        ChoiceRow(
                            symbol: "calendar", title: exam.title,
                            line: [exam.subject, exam.date.shortWeekdayText].compactMap(\.self)
                                .joined(separator: " · "),
                            chosen: chosen == .item(exam)
                        ) { pick(.item(exam)) }
                    }
                    ChoiceRow(symbol: "pencil", title: "Type it", line: "Subject, title and portions", chosen: false) {
                        pick(.typed(subject: exams.first?.subject ?? "", title: "", portions: ""))
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }
}
