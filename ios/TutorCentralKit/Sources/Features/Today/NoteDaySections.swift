import DesignSystem
import Domain
import SwiftUI

/// The note day on Today (P10-Today-NoteDay, P10-NoteDay-Change): the hero with Change day (the wheel of the five
/// choices in a popover, written when it closes), then Notes with the count sent and one row per student.
struct NoteDaySection: View {
    @Environment(NoticeCenter.self) private var notices: NoticeCenter?
    let store: NoteDayStore
    let openHeld: (HeldNote) -> Void
    /// A board state opens the wheel at once (`today-note-day-change`).
    let showsWheel: Bool
    @State private var changing = false
    @State private var choice = NoteDay.default

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            hero
            VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                HStack {
                    SectionHeader("Notes")
                    Spacer()
                    Text(store.countLine).typeStyle(Tokens.footnote).monospacedDigit()
                        .foregroundStyle(Tokens.text2.color)
                }
                if store.loadFailed {
                    LoadFailedView("Couldn't load this week's notes.") { Task { await store.load() } }
                } else if !store.rows.isEmpty {
                    Card {
                        VStack(spacing: 0) {
                            ForEach(store.rows) { row in
                                NoteRow(
                                    initials: row.initials, name: row.name, line: row.line, state: state(row.state)
                                ) { open(row) }
                                    .rowDivider(row.id != store.rows.last?.id)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            notices?.show(message)
            store.message = nil
        }
        .task {
            choice = store.chosen
            if showsWheel {
                changing = true
            }
        }
    }

    private var hero: some View {
        Card(.hero) {
            VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
                HStack(alignment: .firstTextBaseline) {
                    Eyebrow("Note day", accent: true, strong: true)
                    Spacer()
                    Button("Change day") {
                        choice = store.chosen
                        changing = true
                    }
                    .buttonStyle(.quiet)
                    .popover(isPresented: $changing) {
                        WheelPopover(eyebrow: "Note day", values: NoteDay.choices, selection: $choice) { $0.title }
                    }
                }
                VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                    Text(store.heroLine).typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
                    Text(NoteDayStore.heroNote).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .onChange(of: changing) { _, open in
            guard !open, choice != store.chosen else { return }
            Task { _ = await store.changeDay(to: choice) }
        }
    }

    private func state(_ state: NoteRowModel.State) -> NoteRow.State {
        switch state {
        case .read: .read
        case .sent: .sent
        case .held: .held
        }
    }

    private func open(_ row: NoteRowModel) {
        if case .held = row.state, let held = store.held(for: row.id) {
            openHeld(held)
        } else {
            store.open(row)
        }
    }
}

/// The held sheet over Today (P10-Held): Send it now opens the note; Keep it for next week closes, writing nothing.
struct HeldNoteSheet: View {
    let held: HeldNote
    let store: NoteDayStore
    let close: () -> Void

    var body: some View {
        HeldSheet(
            initials: held.initials, parentLine: held.parentLine,
            messages: held.thisWeek.map { HeldSheet.Message(symbol: $0.symbol, kind: $0.kind, day: $0.day) },
            footnote: held.footnote,
            send: {
                close()
                store.sendNow(held)
            },
            close: close
        )
    }
}
