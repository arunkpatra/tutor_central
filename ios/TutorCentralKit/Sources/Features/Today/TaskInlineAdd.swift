import DesignSystem
import Domain
import SwiftUI

/// The inline add bound to the tasks store (P4-Today-AddingTask, P4-Tasks): the well, then while adding the date chip
/// (the chosen day, else the next weekday; it opens the system's date picker) and No date, and Add.
public struct TaskInlineAdd: View {
    @Bindable var store: TasksStore
    let showsFocus: Bool
    let autofocus: Bool
    @State private var picksDue = false

    public init(store: TasksStore, showsFocus: Bool, autofocus: Bool) {
        self.store = store
        self.showsFocus = showsFocus
        self.autofocus = autofocus
    }

    public var body: some View {
        let chips = store.dueChips
        InlineAdd(
            text: $store.newTitle,
            placeholder: "Add a task",
            showsFocus: showsFocus || store.adding,
            autofocus: autofocus,
            dueChips: [
                .init(chips[0].label, symbol: "calendar", isOn: store.newDue != nil) { picksDue = true },
                .init(chips[1].label, isOn: store.newDue == nil) { store.newDue = nil },
            ],
            canAdd: store.canAdd,
            add: { Task { await store.add() } }
        )
        .simultaneousGesture(TapGesture().onEnded { store.adding = true })
        .popover(isPresented: $picksDue) {
            DatePicker("Due", selection: dueBinding, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Tokens.accent.color)
                // The day is the centre's (India's), whatever zone the phone is in.
                .environment(\.timeZone, DayHeading.india.timeZone)
                .padding(Tokens.cardPaddingCompact)
                .presentationCompactAdaptation(.popover)
        }
    }

    private var dueBinding: Binding<Date> {
        Binding(
            get: { (store.newDue ?? store.suggestedDue).date(in: DayHeading.india) },
            set: { date in
                store.newDue = Day(date, calendar: DayHeading.india)
                picksDue = false
            }
        )
    }
}
