import DesignSystem
import Domain
import SwiftUI

/// The next class (P4-Today-Soon, -Evening, -NoClass): the eyebrow in accentText while it is soon or running, the class
/// or the next class day in title2, its line, and Mark attendance while it can be marked.
struct HeroCard: View {
    let hero: TodayStore.Hero
    let markAttendance: () -> Void

    var body: some View {
        Card(.hero) {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
                Eyebrow(hero.eyebrow, accent: hero.accent, strong: hero.accent)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                    Text(hero.title).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
                    Text(hero.line).typeStyle(Tokens.subhead).monospacedDigit().foregroundStyle(Tokens.text2.color)
                }
                if hero.canMark {
                    Button(action: markAttendance) {
                        Label("Mark attendance", systemImage: "checkmark.circle").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary(.card))
                    .padding(.top, Tokens.rowGapInner)
                }
            }
        }
    }
}

/// "Today" with Schedule: the day's classes (a tick and "5 of 6 present" once marked) and events.
struct TodaySection: View {
    let store: TodayStore
    let actions: TodayActions

    var body: some View {
        let rows = store.todayRows
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Today", action: ("Schedule", actions.openSchedule))
            Card {
                if rows.isEmpty {
                    if store.hasClasses {
                        EmptyRow(
                            symbol: "calendar",
                            title: "Nothing today",
                            line: "No batches meet today and there are no events."
                        )
                    } else {
                        EmptyRow(
                            symbol: "calendar",
                            title: "No batches yet",
                            line: "Batches you create show here on the days they meet, with one tap to mark attendance."
                        )
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            Group {
                                if let classroom = row.classroom {
                                    ScheduleRow(
                                        start: row.start, end: row.end, title: row.title, line: row.line ?? "",
                                        lineTone: row.lineTone, marked: row.marked
                                    ) { actions.openClass(classroom.id) }
                                } else if let event = row.event {
                                    EventRow(start: row.start, end: row.end, title: row.title, line: row.line) {
                                        actions.openEvent(event.id)
                                    }
                                }
                            }
                            .rowDivider(row.id != rows.last?.id)
                        }
                    }
                }
            }
        }
    }
}

/// "Coming up": the next seven days' events, a day column and "11:00–12:00 · Class 10 parents".
struct ComingUpSection: View {
    let rows: [TodayStore.ComingLine]
    let open: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Coming up")
            Card {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        EventRow(start: row.day, end: nil, title: row.event.title, line: row.line) { open(row.event.id)
                        }
                        .rowDivider(row.id != rows.last?.id)
                    }
                }
            }
        }
    }
}

/// "Tasks" with Add (Cancel while adding): the inline add as the card's first row, then open tasks and those done
/// within a day (P4-Today-AddingTask).
struct TodayTasksSection: View {
    let store: TasksStore
    let showsFocus: Bool

    /// Add opens the field in the card; Cancel closes it.
    private var headerAction: (label: String, run: () -> Void) {
        if store.adding {
            return ("Cancel", { store.cancelAdd() })
        }
        return ("Add", { store.adding = true })
    }

    var body: some View {
        let tasks = store.onToday
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Tasks", action: headerAction)
            Card {
                VStack(spacing: 0) {
                    if store.adding {
                        TaskInlineAdd(store: store, showsFocus: showsFocus, autofocus: !showsFocus)
                            .padding(.vertical, Tokens.rowPaddingDense)
                            .padding(.horizontal, Tokens.rowPaddingHorizontal)
                            .rowDivider(!tasks.isEmpty)
                    }
                    if tasks.isEmpty, !store.adding {
                        EmptyRow(
                            symbol: "checkmark.circle",
                            title: "Nothing on your list",
                            line: "Add a task when there's something to remember."
                        )
                    }
                    ForEach(tasks) { task in
                        let trailing = store.trailing(for: task)
                        TaskRow(
                            title: task.title, done: task.isDone, trailing: trailing?.text,
                            trailingTone: trailing?.tone,
                            toggle: { Task { await store.setDone(task.id, !task.isDone) } }
                        )
                        .rowDivider(task.id != tasks.last?.id)
                    }
                }
            }
        }
    }
}

/// The empty register's first step (P2-Today-Empty): add students one by one or scan the paper register. The buttons
/// are plain labels, as on the Students empty card (the owner, 2026-10-09).
struct StartHereCard: View {
    let openStudents: () -> Void
    let openScanRegister: () -> Void

    var body: some View {
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
                    Button(action: openStudents) {
                        Text("Add a student").typeStyle(Tokens.buttonStrong)
                    }
                    .buttonStyle(.primary())
                    Button("Scan register", action: openScanRegister)
                        .buttonStyle(.secondary())
                }
            }
        }
    }
}
