import Data
import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on the schedule so it can be photographed beside its board: Saturday 10 October
/// chosen, New event filled in, Edit event, the delete confirmation.
public enum ScheduleBoardState: Sendable {
    case saturday
    case newEvent
    case editEvent
    case deleteConfirm
}

/// The schedule (P4-Schedule-Month, -Day), pushed from More and from Today's Schedule: the month with today on the
/// accent disc and a dot under days with a class or an event, the chosen day's classes and events, and coming up when
/// today is chosen. "+" and the day's Add event open New event; an event opens Edit event; Delete asks over the month.
public struct ScheduleView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view.
    @State private var store: ScheduleStore
    let actions: ScheduleActions
    let boardState: ScheduleBoardState?
    let openEvent: UUID?
    let onMissingEvent: () -> Void
    @State private var topInset: CGFloat = 0
    @State private var adding: EventFormStore?
    @State private var editing: EventFormStore?
    @State private var deleting: CalendarEvent?
    /// AppShell's: the offline or sync line under the title (D39), for this screen's store.
    let status: StatusFor
    @State private var deletingNow = false
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toasts: ToastCenter?

    public init(
        store: ScheduleStore, actions: ScheduleActions, boardState: ScheduleBoardState? = nil, openEvent: UUID? = nil,
        onMissingEvent: @escaping () -> Void = {}, status: @escaping StatusFor = { _, _ in .online }
    ) {
        self.status = status
        _store = State(initialValue: store)
        self.actions = actions
        self.boardState = boardState
        self.openEvent = openEvent
        self.onMissingEvent = onMissingEvent
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                navigationRow
                if let line = status(store.savedAt, store.offlineRead).line {
                    StatusLine(line)
                }
                calendar
                if let error = store.error {
                    ScheduleErrorLine(error) { Task { await store.load() } }
                }
                Group {
                    day
                    if !store.comingUp.isEmpty || store.selected == store.today {
                        comingUp
                    }
                }
                .opacity(store.loading ? Tokens.opacityStale : 1)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if let deleting {
                deleteDialog(deleting)
            }
        }
        .animation(.timingCurve(Tokens.easeOut, duration: Tokens.panel), value: deleting)
        .sheet(item: $adding) { form in
            EventFormSheet(
                store: form,
                autofocus: boardState == nil,
                onSave: { await store.add($0) != nil },
                onClose: { adding = nil }
            )
        }
        .sheet(item: $editing) { form in
            EventFormSheet(
                store: form,
                onSave: { draft in
                    guard let id = form.editingID else { return false }
                    return await store.update(id, with: draft)
                },
                onDelete: { confirmDelete(form) },
                onClose: { editing = nil }
            )
        }
        .task {
            await store.load()
            await setUpBoardState()
            openLinkedEvent()
        }
        .onChange(of: store.lastSavedAt) { Haptic.play(.success) }
        // A failed write says so where the tutor is, with Retry (the sheets draw the toast over themselves).
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            Haptic.play(.error)
            toasts?.show(message, action: store.canRetry ? retry : nil)
            store.message = nil
        }
    }

    private var navigationRow: some View {
        ZStack {
            Text("Schedule").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            HStack {
                IconButton(symbol: "chevron.left", label: "Back") { dismiss() }
                Spacer()
                IconButton(symbol: "plus", label: "Add an event", action: add)
            }
        }
    }

    private var calendar: some View {
        VStack(spacing: Tokens.inline) {
            MonthHeader(
                title: store.monthTitle,
                previous: { Task { await store.previousMonth() } },
                next: { Task { await store.nextMonth() } }
            )
            CalendarMonth(
                year: store.month.year,
                month: store.month.month,
                today: Self.components(store.today),
                selected: Binding(
                    get: { Self.components(store.selected) },
                    set: { picked in
                        guard let year = picked.year, let month = picked.month, let day = picked.day,
                              let chosen = Day(year: year, month: month, day: day) else { return }
                        Task { await store.select(chosen) }
                    }
                ),
                marked: Set(store.markedDays.map(Self.components)),
                calendar: DayHeading.india
            )
        }
        .padding(.top, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.cardPaddingCompact)
        .padding(.bottom, Tokens.tileGap)
        .surface(radius: Tokens.radiusCard)
    }

    @ViewBuilder private var day: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(store.dayTitle, action: addOnDay)
            DayList(
                classes: store.classRows,
                events: store.eventRows,
                openClass: actions.openClass,
                openEvent: edit
            )
        }
        if let line = store.noClassLine {
            Text(line)
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }

    /// Add event beside a chosen day that is not today (P4-Schedule-Day).
    private var addOnDay: (label: String, run: () -> Void)? {
        guard store.selected != store.today else { return nil }
        return ("Add event", { add() })
    }

    private var comingUp: some View {
        let rows = store.comingUp
        return VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Coming up")
            Card {
                if rows.isEmpty {
                    EmptyRow(
                        symbol: "calendar",
                        title: "Nothing coming up",
                        line: "Events you add show here for the next two weeks."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            EventRow(start: row.day, end: nil, title: row.event.title, line: row.line) {
                                edit(row.event)
                            }
                            .rowDivider(row.id != rows.last?.id)
                        }
                    }
                }
            }
        }
    }

    private func deleteDialog(_ event: CalendarEvent) -> some View {
        ZStack {
            Tokens.dim.color.ignoresSafeArea().onTapGesture { deleting = nil }
            DialogView(
                title: "Delete this event?",
                message: "\(event.title) on \(event.date.shortWeekdayText) leaves the schedule. "
                    + "Classes are not affected.",
                action: "Delete",
                destructive: true,
                loading: deletingNow,
                onCancel: { deleting = nil },
                onAction: { delete(event) }
            )
            .padding(.horizontal, Tokens.pageSide)
        }
        .transition(.opacity)
    }

    /// The toast's Retry for the last failed write.
    private var retry: (label: String, run: @MainActor () -> Void) {
        let run: @MainActor () -> Void = { Task { await store.retryLast() } }
        return ("Retry", run)
    }

    private func add() {
        adding = EventFormStore(mode: .new(store.selected))
    }

    private func edit(_ event: CalendarEvent) {
        editing = EventFormStore(mode: .edit(event))
    }

    /// Delete event closes the sheet and asks over the schedule, on the event's day (P4-Event-Delete-Confirm).
    private func confirmDelete(_ form: EventFormStore) {
        guard case let .edit(event) = form.mode else { return }
        editing = nil
        Task {
            await store.select(event.date)
            deleting = event
        }
    }

    private func delete(_ event: CalendarEvent) {
        deletingNow = true
        Task {
            if await store.delete(event.id) {
                deleting = nil
            }
            deletingNow = false
        }
    }

    /// `tutorcentral://event/<id>`: Edit event over the month, once the events are read.
    private func openLinkedEvent() {
        guard let openEvent else { return }
        if let event = store.events.first(where: { $0.id == openEvent }) {
            Task {
                await store.select(event.date)
                edit(event)
            }
        } else {
            onMissingEvent()
        }
    }

    private func setUpBoardState() async {
        let parents = FakeEventsRepository.parentsMeeting
        switch boardState {
        case .saturday:
            await store.select(parents.date)
        case .newEvent:
            adding = EventFormSheet.fixture()
        case .editEvent:
            edit(parents)
        case .deleteConfirm:
            await store.select(parents.date)
            deleting = parents
        case nil:
            break
        }
    }

    private nonisolated static func components(_ day: Day) -> DateComponents {
        DateComponents(year: day.year, month: day.month, day: day.day)
    }
}

/// The chosen day's classes, then its events, in one card; nothing when the day has neither.
struct DayList: View {
    let classes: [ScheduleStore.ClassLine]
    let events: [ScheduleStore.EventLine]
    let openClass: (UUID) -> Void
    let openEvent: (CalendarEvent) -> Void

    var body: some View {
        if !classes.isEmpty || !events.isEmpty {
            Card {
                VStack(spacing: 0) {
                    ForEach(classes) { row in
                        ScheduleRow(
                            start: row.start, end: row.end, title: row.classroom.name, line: row.line,
                            lineTone: row.lineTone, marked: row.marked
                        ) { openClass(row.classroom.id) }
                            .rowDivider(row.id != classes.last?.id || !events.isEmpty)
                    }
                    ForEach(events) { row in
                        EventRow(start: row.start, end: row.end, title: row.event.title, line: row.line) {
                            openEvent(row.event)
                        }
                        .rowDivider(row.id != events.last?.id)
                    }
                }
            }
        }
    }
}

/// A read that failed: the line and Retry (Today's pattern).
struct ScheduleErrorLine: View {
    let text: String
    let retry: () -> Void

    init(_ text: String, retry: @escaping () -> Void) {
        self.text = text
        self.retry = retry
    }

    var body: some View {
        HStack {
            Label(text, systemImage: "exclamationmark.triangle")
                .labelStyle(InlineLabelStyle())
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text2.color)
            Spacer()
            Button("Retry", action: retry).buttonStyle(.quiet)
        }
        .padding(.horizontal, Tokens.rowGapInner)
    }
}
