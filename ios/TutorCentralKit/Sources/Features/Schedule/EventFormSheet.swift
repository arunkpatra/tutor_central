import DesignSystem
import Domain
import SwiftUI

/// New event and Edit event (P4-Event-New, -Edit): a floating sheet (D28) with Cancel and Save, the title, the day from
/// the system's date picker, optional start and end times, an optional note with its counter; Edit event ends with
/// Delete event, which the schedule confirms over itself (P4-Event-Delete-Confirm). With the keyboard up the fields
/// keep their size and Delete event scrolls under the keyboard (U7, P8-Event-Edit-Keyboard).
public struct EventFormSheet: View {
    @Bindable var store: EventFormStore
    let showsFocus: Bool
    let autofocus: Bool
    let onSave: (EventDraft) async -> Bool
    let onDelete: (() -> Void)?
    let onClose: () -> Void
    let focusNote: Bool
    @State private var saving = false
    @State private var picksDay = false
    @State private var discarding = false
    @State private var sheetHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    @State private var fieldsHeight: CGFloat = 0
    @State private var deleteHeight: CGFloat = 0

    /// `focusNote` focuses the note when the sheet opens (the board state with the keyboard up).
    public init(
        store: EventFormStore, showsFocus: Bool = false, autofocus: Bool = false,
        onSave: @escaping (EventDraft) async -> Bool, onDelete: (() -> Void)? = nil, onClose: @escaping () -> Void,
        focusNote: Bool = false
    ) {
        self.store = store
        self.showsFocus = showsFocus
        self.autofocus = autofocus
        self.onSave = onSave
        self.onDelete = onDelete
        self.onClose = onClose
        self.focusNote = focusNote
    }

    /// The fields' column is at least the sheet's room under the header, so Delete event sits at the bottom with the
    /// keyboard away and, with the keyboard up, the column keeps that height and scrolls: the well stays whole above
    /// the keyboard and Delete is under it (U7, P8-Event-Edit-Keyboard).
    nonisolated static func contentMinHeight(sheetHeight: CGFloat, headerHeight: CGFloat) -> CGFloat {
        max(0, sheetHeight - headerHeight - Tokens.sectionGap)
    }

    /// The room between the note and Delete event: what the column has left after the fields and the button, at least
    /// a section's gap. A height of its own, not a Spacer, so the note's well keeps its size (a Spacer would share the
    /// room with the flexible text editor).
    nonisolated static func deleteGap(
        sheetHeight: CGFloat, headerHeight: CGFloat, fieldsHeight: CGFloat, deleteHeight: CGFloat
    ) -> CGFloat {
        let left = contentMinHeight(sheetHeight: sheetHeight, headerHeight: headerHeight) - fieldsHeight - deleteHeight
        return max(Tokens.sectionGap, left)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(
                title: store.heading,
                cancel: ("Cancel", cancel),
                save: .init("Save", enabled: store.canSave && !saving, run: save)
            )
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    fields
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fieldsHeight = $0 }
                    if let onDelete {
                        Color.clear.frame(
                            height: Self.deleteGap(
                                sheetHeight: sheetHeight, headerHeight: headerHeight,
                                fieldsHeight: fieldsHeight, deleteHeight: deleteHeight
                            )
                        )
                        Button(action: onDelete) {
                            Label("Delete event", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.destructive(.card))
                        .environment(\.buttonIconSize, Tokens.iconSmall)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { deleteHeight = $0 }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            // A sheet does not take the root's setting: a drag down puts the keyboard away here too (U7).
            .scrollDismissesKeyboard(.interactively)
        }
        // The sheet's room before the keyboard came: on an iPhone only the keyboard makes it smaller, so the largest
        // measure is kept and the fields keep their size when the keyboard comes.
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = max(sheetHeight, $0) }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .overlay {
            if discarding {
                discardDialog
            }
        }
        .modifier(SheetToasts())
        .interactiveDismissDisabled(store.isChanged)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
            TextWell(
                label: "Title",
                text: $store.title,
                placeholder: "What is it",
                error: store.titleError,
                capitalisation: .sentences,
                showsFocus: showsFocus,
                autofocus: autofocus
            )
            day
            times
            NotesWell(
                label: "Note",
                text: $store.note,
                placeholder: "Anything to remember",
                limit: EventDraft.noteLimit,
                error: store.noteError,
                optional: true,
                autofocus: focusNote
            )
        }
    }

    private var day: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text("Date").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            PickerTile(label: "Day", value: store.date.fullText) { picksDay = true }
                .popover(isPresented: $picksDay) {
                    DatePicker("Day", selection: dayBinding, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .calendarPopover(timeZone: DayHeading.india.timeZone)
                }
        }
    }

    private var dayBinding: Binding<Date> {
        Binding(
            get: { store.date.date(in: DayHeading.india) },
            set: { date in
                store.date = Day(date, calendar: DayHeading.india)
                picksDay = false
            }
        )
    }

    private var times: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            HStack(spacing: Tokens.rowGapInner * 2) {
                Text("Time").foregroundStyle(Tokens.text2.color)
                Text("(optional)").foregroundStyle(Tokens.text3.color)
            }
            .typeStyle(Tokens.footnote)
            HStack(spacing: Tokens.tileGap) {
                TileRow(label: "Starts", labelType: Tokens.subhead, labelTone: Tokens.text2) {
                    EventTimeControl(label: "Starts", time: store.startTime, fresh: EventTimeControl.defaultStart) {
                        store.setStart($0)
                    }
                }
                TileRow(label: "Ends", labelType: Tokens.subhead, labelTone: Tokens.text2) {
                    EventTimeControl(label: "Ends", time: store.endTime, fresh: freshEnd) { store.setEnd($0) }
                }
            }
            if let error = store.timeError {
                FieldMessage(error)
            }
        }
    }

    /// "Not set" under Ends becomes an hour after the start, or 11:00.
    private var freshEnd: TimeOfDay {
        store.startTime.flatMap { TimeOfDay(hour: min($0.hour + 1, 23), minute: $0.minute) }
            ?? EventTimeControl.defaultEnd
    }

    private var discardDialog: some View {
        ZStack {
            Tokens.dim.color.ignoresSafeArea().onTapGesture { discarding = false }
            DialogView(
                title: "Discard changes?",
                message: "What you typed here goes away.",
                cancel: "Keep editing",
                action: "Discard",
                destructive: true,
                onCancel: { discarding = false },
                onAction: onClose
            )
            .padding(.horizontal, Tokens.pageSide)
        }
        .transition(.opacity)
    }

    private func cancel() {
        if store.isChanged {
            discarding = true
        } else {
            onClose()
        }
    }

    private func save() {
        saving = true
        // The keyboard goes first, so a failure's toast is seen above the sheet (U9's cause).
        Keyboard.dismiss()
        Task {
            if await onSave(store.draft) {
                onClose()
            }
            saving = false
        }
    }
}

/// A time on a tile: the value in accentText bodyStrong that opens the system's 24-hour wheel with Clear, or "Not set"
/// (the class form's control, P3-NewClass).
struct EventTimeControl: View {
    let label: String
    let time: TimeOfDay?
    let fresh: TimeOfDay
    let set: (TimeOfDay?) -> Void
    @State private var picking = false
    static let defaultStart = TimeOfDay(hour: 10, minute: 0)!
    static let defaultEnd = TimeOfDay(hour: 11, minute: 0)!

    var body: some View {
        if let time {
            Button { picking = true } label: {
                Text(time.text).typeStyle(Tokens.bodyStrong).monospacedDigit().foregroundStyle(Tokens.accentText.color)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label), \(time.text)")
            .popover(isPresented: $picking) {
                VStack(spacing: Tokens.inline) {
                    DatePicker(label, selection: binding(time), displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        // 24-hour, as every time in the app is written (components.md).
                        .environment(\.locale, Locale(identifier: "en_GB"))
                        .environment(\.timeZone, DayHeading.india.timeZone)
                    Button("Clear") {
                        picking = false
                        set(nil)
                    }
                    .buttonStyle(.quiet)
                }
                .padding(Tokens.cardPaddingCompact)
                .presentationCompactAdaptation(.popover)
                .onAppear { Keyboard.dismiss() }
            }
        } else {
            Button("Not set") { set(fresh) }.buttonStyle(.quiet)
        }
    }

    private func binding(_ time: TimeOfDay) -> Binding<Date> {
        let calendar = DayHeading.india
        return Binding(
            get: { calendar.date(from: DateComponents(hour: time.hour, minute: time.minute)) ?? .distantPast },
            set: { date in
                let parts = calendar.dateComponents([.hour, .minute], from: date)
                set(TimeOfDay(hour: parts.hour ?? 0, minute: parts.minute ?? 0))
            }
        )
    }
}

public extension EventFormSheet {
    /// The boards' new event (P4-Event-New): Parents' meeting on Saturday 10 October, 11:00 to 12:00, with its note.
    static func fixture() -> EventFormStore {
        let form = EventFormStore(mode: .new(Day(year: 2026, month: 10, day: 10)!))
        form.title = "Parents' meeting"
        form.setEnd(TimeOfDay(hour: 12, minute: 0))
        form.note = "Class 10 parents. Bring the September test papers."
        return form
    }
}
