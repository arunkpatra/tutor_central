import Data
import DesignSystem
import Domain
import SwiftUI

/// New student, Edit student and Fix this row, to P3-NewStudent-Empty, -Filled, -Invalid, P3-EditStudent and
/// P6-Scan-Review-Edit (five fields and Remove this row): the eight fields in
/// the boards' order, Save until valid (and, editing, changed), Cancel asking before typing is thrown away.
public struct StudentFormSheet: View {
    @Bindable var store: StudentFormStore
    let showsFocus: Bool
    let autofocus: Bool
    let onSave: (StudentDraft) async -> Bool
    let onClose: () -> Void
    let onRemove: (() -> Void)?
    @State private var saving = false
    @State private var confirmingDiscard = false
    @State private var pickingBirthDate = false

    /// `showsFocus` draws the name focused without the keyboard (the empty board); `autofocus` raises the keyboard on
    /// the name of a new student (off for every board state).
    public init(
        store: StudentFormStore,
        showsFocus: Bool = false,
        autofocus: Bool = true,
        onSave: @escaping (StudentDraft) async -> Bool,
        onClose: @escaping () -> Void,
        onRemove: (() -> Void)? = nil
    ) {
        self.store = store
        self.showsFocus = showsFocus
        self.autofocus = autofocus
        self.onSave = onSave
        self.onClose = onClose
        self.onRemove = onRemove
    }

    public var body: some View {
        VStack(spacing: Tokens.sectionGap) {
            SheetHeader(
                title: store.title,
                cancel: ("Cancel", cancel),
                save: .init("Save", enabled: store.canSave && !saving, run: save)
            )
            .padding(.horizontal, Tokens.pageSide)
            ScrollView {
                fields
                    .padding(.horizontal, Tokens.pageSide)
                    .padding(.bottom, Tokens.contentBottom)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(.top, Tokens.inline)
        .background(Tokens.surface1.color)
        .overlay {
            if confirmingDiscard {
                discardDialog
            }
        }
        .animation(.timingCurve(Tokens.easeOut, duration: Tokens.panel), value: confirmingDiscard)
        .modifier(SheetToasts())
        .interactiveDismissDisabled(store.isChanged)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    private var isFix: Bool {
        if case .fix = store.mode {
            true
        } else {
            false
        }
    }

    private var isNew: Bool {
        if case .new = store.mode {
            true
        } else {
            false
        }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
            TextWell(
                label: "Name",
                text: $store.name,
                placeholder: "The student's full name",
                error: store.nameError,
                content: .name,
                showsFocus: showsFocus && !isFix,
                autofocus: autofocus && isNew
            )
            Menu {
                Button("No class") { store.select(classID: nil) }
                ForEach(store.classes) { classroom in
                    Button(classroom.name) { store.select(classID: classroom.id) }
                }
            } label: {
                PickerTile(label: "Class", value: store.classLabel) {}
            }
            .accessibilityLabel("Class, \(store.classLabel)")
            TextWell(
                label: "Monthly fee",
                text: $store.feeText,
                placeholder: store.feePlaceholder,
                helper: store.feeHelper,
                error: store.feeError,
                prefix: "₹",
                suffix: "per month",
                numeric: true,
                keyboard: .numberPad,
                capitalisation: .never
            )
            TextWell(
                label: "Parent's name",
                text: $store.parentName,
                placeholder: isFix ? "Parent's name" : "Who you call about this student",
                error: store.parentNameError,
                content: .name
            )
            PhoneWell(
                label: "Parent's WhatsApp number",
                digits: $store.digits,
                helper: store.phoneHelper,
                error: store.phoneError,
                showsFocus: showsFocus && isFix,
                onCommit: store.commitPhone
            )
            if isFix {
                // A scanned row (P6-Scan-Review-Edit): the fields a register carries, and the way to drop the row.
                if let onRemove {
                    Button("Remove this row", action: onRemove).buttonStyle(.destructive(.form))
                }
            } else {
                birthDate
                gender
                NotesWell(
                    label: "Notes",
                    text: $store.notes,
                    placeholder: "School, board, pickup, anything to remember",
                    limit: StudentDraft.notesLimit,
                    error: store.notesError
                )
            }
        }
    }

    /// The tile with its switch; once on, the day beside the switch opens the system's calendar.
    private var birthDate: some View {
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
                                .tint(Tokens.accent.color)
                                // The day is the centre's (India's), whatever zone the phone is in.
                                .environment(\.timeZone, DayHeading.india.timeZone)
                                .padding(Tokens.cardPaddingCompact)
                                .presentationCompactAdaptation(.popover)
                            }
                    }
                    Switch(isOn: $store.hasBirthDate, label: "Add a date of birth")
                }
            }
            if let error = store.birthDateError {
                FieldMessage(error)
            }
        }
    }

    private var gender: some View {
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

    private var birthDateBinding: Binding<Date> {
        Binding(
            get: { store.birthDate.date(in: DayHeading.india) },
            set: { store.birthDate = Day($0, calendar: DayHeading.india) }
        )
    }

    private var birthDateRange: ClosedRange<Date> {
        let earliest = Day(year: StudentDraft.earliestBirthYear, month: 1, day: 1) ?? store.today
        return earliest.date(in: DayHeading.india) ... store.today.date(in: DayHeading.india)
    }

    private var discardDialog: some View {
        ZStack {
            Tokens.dim.color.ignoresSafeArea().onTapGesture { confirmingDiscard = false }
            DialogView(
                title: "Discard changes?",
                message: "What you typed here goes away.",
                cancel: "Keep editing",
                action: "Discard",
                destructive: true,
                onCancel: { confirmingDiscard = false },
                onAction: onClose
            )
            .padding(.horizontal, Tokens.pageSide)
        }
        .transition(.opacity)
    }

    private func cancel() {
        if store.isChanged {
            confirmingDiscard = true
        } else {
            onClose()
        }
    }

    private func save() {
        saving = true
        // The keyboard goes first, so a refusal's toast is seen above the sheet (P7-Offline-WriteRefused).
        Keyboard.dismiss()
        Task {
            if await onSave(store.draft) {
                onClose()
            }
            saving = false
        }
    }
}

public extension StudentFormSheet {
    /// The boards' sample (P3-NewStudent-Filled): Riya Sharma in Class 10 Maths at her own fee; `invalid` leaves the
    /// number a digit short and checks it (P3-NewStudent-Invalid).
    static func fixture(invalid: Bool, classes: [Classroom], today: Day) -> StudentFormStore {
        let form = StudentFormStore(mode: .new, classes: classes, today: today)
        form.name = "Riya Sharma"
        form.select(classID: FakeClassesRepository.maths.id)
        form.feeText = "1,500"
        form.parentName = "Neha Sharma"
        form.digits = invalid ? "981112223" : "9811122233"
        form.hasBirthDate = true
        form.birthDate = Day(year: 2011, month: 3, day: 14) ?? today
        form.toggle(.female)
        form.notes = "Board exam in March. Prefers the evening batch."
        if invalid {
            form.commitPhone()
        }
        return form
    }
}
