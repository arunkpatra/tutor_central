import DesignSystem
import Domain
import SwiftUI

/// The student form's pickers and toggles: Class, Board, Date of birth, Gender.
extension StudentFormSheet {
    /// Class: the wheel of LKG to class 10 in a popover (P10-NewStudent-ClassPicker). Opened with no class, the wheel's
    /// middle class is chosen, as the wheel shows it.
    var classTile: some View {
        PickerField(
            label: "Class", value: store.classTitle, placeholder: "Choose", helper: store.classHelper
        ) {
            Keyboard.dismiss()
            if store.classLevel == nil {
                store.classLevel = .five
            }
            pickingClass = true
        }
        .popover(isPresented: $pickingClass, arrowEdge: .top) {
            WheelPopover(
                eyebrow: "Class", values: ClassLevel.allCases,
                selection: Binding(get: { store.classLevel ?? .five }, set: { store.classLevel = $0 })
            ) { $0.title }
        }
    }

    /// Board, from class 8 (P10-NewStudent-Class9): the system's menu of the four boards.
    var boardMenu: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Menu {
                Picker("Board", selection: Binding(get: { store.board }, set: { store.board = $0 })) {
                    ForEach(Board.allCases, id: \.self) { board in
                        Text(board.title).tag(Board?.some(board))
                    }
                }
            } label: {
                PickerTileLabel(label: "Board", value: store.board?.title, placeholder: "Choose")
            }
            .accessibilityLabel("Board, \(store.board?.title ?? "Choose")")
            FieldHelper(store.boardHelper)
        }
    }

    /// The tile with its switch; once on, the day beside the switch opens the system's calendar.
    var birthDate: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            TileRow(label: "Date of birth") {
                HStack(spacing: Tokens.rowPaddingDense) {
                    if store.hasBirthDate {
                        Button { pickingBirthDate = true } label: { PickerValue(store.birthDate.text) }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Date of birth, \(store.birthDate.text)")
                            .popover(isPresented: $pickingBirthDate) {
                                DatePicker(
                                    "Date of birth",
                                    selection: birthDateBinding,
                                    in: birthDateRange,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                // Its width (without it the calendar collapses to a sliver: build 10) and the
                                // centre's day, whatever zone the phone is in.
                                .calendarPopover(timeZone: DayHeading.india.timeZone)
                            }
                    }
                    // Nothing on one line (the tile fixes the row's size); the switch at the right edge when the
                    // date goes under the label.
                    Spacer(minLength: 0)
                    Switch(isOn: $store.hasBirthDate, label: "Add a date of birth")
                }
            }
            if let error = store.birthDateError {
                FieldMessage(error)
            }
        }
    }

    var gender: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            HStack(spacing: Tokens.rowGapInner * 2) {
                Text("Gender").foregroundStyle(Tokens.text2.color)
                Text("(optional)").foregroundStyle(Tokens.text3.color)
            }
            .typeStyle(Tokens.footnote)
            HStack(spacing: Tokens.inline) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    FilterChip(gender.label, isOn: store.gender == gender) { store.toggle(gender) }
                }
            }
        }
    }

    var birthDateBinding: Binding<Date> {
        Binding(
            get: { store.birthDate.date(in: DayHeading.india) },
            set: { store.birthDate = Day($0, calendar: DayHeading.india) }
        )
    }

    var birthDateRange: ClosedRange<Date> {
        let earliest = Day(year: StudentDraft.earliestBirthYear, month: 1, day: 1) ?? store.today
        return earliest.date(in: DayHeading.india) ... store.today.date(in: DayHeading.india)
    }
}
