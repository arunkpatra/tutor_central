import DesignSystem
import Domain
import SwiftUI

/// The tracking card on the page (P10-Student): the stored status, why, and the next step; Place <name> when there is
/// something to place on (Task 19 gives it its screen).
struct TrackingSection: View {
    let lines: StudentDetailStore.TrackingLines
    let firstName: String
    let place: (() -> Void)?

    var body: some View {
        TrackingCard(
            word: lines.status.title, kind: lines.status.kind, since: lines.since, reasons: lines.reasons,
            next: lines.next, action: placeAction
        )
    }

    /// A typed property: a ternary of tuples inline stalls the type checker (ios/CLAUDE.md).
    private var placeAction: (label: String, run: () -> Void)? {
        guard lines.placeAction, let place else { return nil }
        return ("Place \(firstName)", place)
    }
}

/// This week (P10-Student): the sessions the student was in, the day column, came or absent with the checks, the batch
/// and the homework.
struct ThisWeekSection: View {
    let rows: [StudentDetailStore.WeekRow]
    /// The quiet Today when the batch meets today (U35).
    let openToday: (() -> Void)?

    var body: some View {
        if !rows.isEmpty || openToday != nil {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("This week", action: openToday.map { ("Today", $0) })
                Card {
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            HStack(alignment: .top, spacing: Tokens.rowPaddingDense) {
                                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                                    Text(row.day).typeStyle(Tokens.time).foregroundStyle(Tokens.text2.color)
                                    Text(row.date).typeStyle(Tokens.caption).foregroundStyle(Tokens.text3.color)
                                }
                                .frame(width: Tokens.groupGap * 2, alignment: .leading)
                                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                                    Text(row.title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                                    Text(row.line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, Tokens.rowPaddingDense)
                            .padding(.horizontal, Tokens.rowPaddingHorizontal)
                            .accessibilityElement(children: .combine)
                            .rowDivider()
                        }
                    }
                }
            }
        }
    }
}

/// Record (P10-Student-Record, -Ladder, -NotKnown): a card per subject; the book's chapters with their states, an open
/// chapter's skills; the ladder's areas; a subject waiting for its book.
struct RecordSection: View {
    @Bindable var store: StudentDetailStore
    /// Add a textbook, Add the book, Add a chapter: nil until their screens exist.
    let addTextbook: ((String?) -> Void)?
    let addChapter: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Record", action: headerAction)
            if let line = store.missingBookLine {
                Card { EmptyRow(symbol: "book.closed", title: "No book yet", line: line) }
            }
            ForEach(store.subjects) { subject in
                if let ladder = subject.ladder {
                    Card {
                        LadderRow(
                            title: subject.title,
                            line: ladder.line,
                            steps: ladder.steps.map { ($0.name, $0.step) }
                        )
                    }
                } else {
                    subjectCard(subject)
                }
            }
        }
    }

    private var headerAction: (label: String, run: () -> Void)? {
        guard store.missingBookLine == nil, let addTextbook else { return nil }
        return ("Add a textbook", { addTextbook(nil) })
    }

    private func subjectCard(_ subject: StudentDetailStore.SubjectCard) -> some View {
        Card {
            VStack(spacing: 0) {
                SubjectHead(title: subject.title, line: subject.line, action: subjectAction(subject)).rowDivider()
                if let empty = subject.emptyLine {
                    EmptyState(symbol: "book", title: "No chapters yet", line: empty)
                }
                ForEach(subject.chapters) { chapter in
                    ChapterRow(
                        position: chapter.position, name: chapter.name, line: chapter.line, open: chapter.open
                    ) { store.openChapter(chapter.id) }
                        .rowDivider()
                    ForEach(chapter.skills) { skill in
                        SkillRow(name: skill.name, line: skill.line, mark: skill.mark).rowDivider()
                    }
                }
            }
        }
    }

    private func subjectAction(_ subject: StudentDetailStore.SubjectCard) -> (label: String, run: () -> Void)? {
        if subject.chapters.isEmpty {
            guard let addTextbook else { return nil }
            return ("Add the book", { addTextbook(subject.title) })
        }
        guard let addChapter else { return nil }
        return ("Add a chapter", { addChapter(subject.title) })
    }
}

/// Checks (P10-Student-Record): the three weeks' trend.
struct ChecksSection: View {
    let lines: StudentDetailStore.ChecksLines

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Checks")
            TrendCard(title: "Three weeks", percent: lines.percent, right: lines.right, line: lines.line)
        }
    }
}

/// Homework (P10-Student-End): one row per homework given, its status as a chip that opens Done, Partial, Not done.
struct HomeworkSection: View {
    let rows: [StudentDetailStore.HomeworkLine]
    /// A row with its sheet opens it.
    let open: (UUID) -> Void
    let set: (UUID, HomeworkStatus) -> Void

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("Homework")
                Card {
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            HStack(spacing: Tokens.rowPaddingDense) {
                                if let sheet = row.artefactID {
                                    Button { open(sheet) } label: { titles(row) }
                                        .buttonStyle(.plain)
                                        .accessibilityHint("Opens the sheet")
                                } else {
                                    titles(row)
                                }
                                Menu {
                                    ForEach([HomeworkStatus.done, .partial, .notDone], id: \.self) { status in
                                        Button(status.title) { set(row.id, status) }
                                    }
                                } label: {
                                    Chip(Self.chip(row.status))
                                }
                                .accessibilityLabel("Homework, \(row.status.title)")
                            }
                            .padding(.vertical, Tokens.rowPaddingDense)
                            .padding(.horizontal, Tokens.rowPaddingHorizontal)
                            .rowDivider()
                        }
                    }
                }
            }
        }
    }

    private func titles(_ row: StudentDetailStore.HomeworkLine) -> some View {
        VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
            Text(row.title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
            Text(row.line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }

    nonisolated static func chip(_ status: HomeworkStatus) -> Chip.Kind {
        switch status {
        case .given: .neutral(status.title)
        case .done: .status(.ok, status.title, symbol: "checkmark")
        case .partial: .status(.due, status.title, symbol: "clock")
        case .notDone: .status(.overdue, status.title, symbol: "exclamationmark.circle")
        }
    }
}

/// School (P10-Student-End): the empty row until Phase 13 brings the school's items.
struct SchoolSection: View {
    let line: String

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("School")
            Card {
                EmptyRow(
                    symbol: "building.columns", title: line,
                    line: "Tests, homework and notices from the school arrive here in a later build."
                )
            }
        }
    }
}

/// Messages (P10-Student-End): what was sent from here, newest first.
struct MessagesSection: View {
    let rows: [StudentDetailStore.MessageLine]

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                SectionHeader("Messages")
                Card {
                    VStack(spacing: 0) {
                        ForEach(rows.prefix(5)) { row in
                            HStack(spacing: Tokens.rowPaddingDense) {
                                IconTile(symbol: row.symbol)
                                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                                    Text(row.title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                                    Text(row.line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, Tokens.rowPaddingDense)
                            .padding(.horizontal, Tokens.rowPaddingHorizontal)
                            .accessibilityElement(children: .combine)
                            .rowDivider()
                        }
                    }
                }
            }
        }
    }
}
