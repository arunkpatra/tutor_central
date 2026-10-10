import DesignSystem
import Domain
import SwiftUI

/// New class and Edit class, to P3-NewClass and P3-EditClass, at the content's height: name, subject, fee, the days it
/// meets, optional times and the summary they make; editing adds Archive class with its confirmation.
public struct ClassFormSheet: View {
    @Bindable var store: ClassFormStore
    let membersCount: Int
    let showsFocus: Bool
    let autofocus: Bool
    let confirmsArchive: Bool
    let onSave: (ClassroomDraft) async -> Bool
    let onArchive: (() async -> Void)?
    let onClose: () -> Void
    @State private var saving = false
    @State private var dialog: Dialog?

    enum Dialog: Hashable {
        case discard
        case archive
    }

    /// `onArchive` is given only when editing: it shows Archive class and its confirmation. `confirmsArchive` opens
    /// the confirmation at once (a launch state).
    public init(
        store: ClassFormStore,
        membersCount: Int = 0,
        showsFocus: Bool = false,
        autofocus: Bool = false,
        confirmsArchive: Bool = false,
        onSave: @escaping (ClassroomDraft) async -> Bool,
        onArchive: (() async -> Void)? = nil,
        onClose: @escaping () -> Void
    ) {
        self.store = store
        self.membersCount = membersCount
        self.showsFocus = showsFocus
        self.autofocus = autofocus
        self.confirmsArchive = confirmsArchive
        self.onSave = onSave
        self.onArchive = onArchive
        self.onClose = onClose
    }

    public var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.groupGap) {
            SheetHeader(
                title: store.title,
                cancel: ("Cancel", cancel),
                save: .init("Save", enabled: store.canSave && !saving, run: save)
            )
        } content: {
            fields
        }
        .overlay {
            if let dialog {
                dialogView(dialog)
            }
        }
        .animation(.timingCurve(Tokens.easeOut, duration: Tokens.panel), value: dialog)
        .modifier(SheetToasts())
        .interactiveDismissDisabled(store.isChanged)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
        .onAppear {
            if confirmsArchive {
                dialog = .archive
            }
        }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
            TextWell(
                label: "Name",
                text: $store.name,
                placeholder: "Class 9 English, Evening batch…",
                error: store.nameError,
                showsFocus: showsFocus,
                autofocus: autofocus
            )
            TextWell(label: "Subject", text: $store.subject, placeholder: "Mathematics, Science…", optional: true)
            TextWell(
                label: "Monthly fee",
                text: $store.feeText,
                placeholder: "0",
                helper: store.feeHelper,
                error: store.feeError,
                prefix: "₹",
                suffix: "per month",
                numeric: true,
                keyboard: .numberPad,
                capitalisation: .never
            )
            days
            times
            if onArchive != nil {
                archive
            }
        }
    }

    private var days: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            HStack {
                Text("Meets on").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                Spacer()
                FilterChip("Every day", isOn: store.everyDay) { store.everyDay.toggle() }
            }
            DayPicker(items: store.dayItems, selection: $store.daySelection)
        }
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
                    TimeControl(label: "Starts", time: store.startTime, set: store.setStart)
                }
                TileRow(label: "Ends", labelType: Tokens.subhead, labelTone: Tokens.text2) {
                    TimeControl(label: "Ends", time: store.endTime, set: store.setEnd)
                }
            }
            if let error = store.timeError {
                FieldMessage(error)
            }
            Text(store.summary)
                .typeStyle(Tokens.footnote)
                .monospacedDigit()
                .foregroundStyle(Tokens.text3.color)
        }
    }

    private var archive: some View {
        VStack(spacing: Tokens.tileGap) {
            Button { dialog = .archive } label: {
                Label("Archive class", systemImage: "archivebox").frame(maxWidth: .infinity)
            }
            .buttonStyle(.destructive())
            .environment(\.buttonIconSize, Tokens.iconSmall)
            Text("Its students stay in Students with no batch. Attendance history is kept.")
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, Tokens.rowGapInner)
    }

    private func dialogView(_ dialog: Dialog) -> some View {
        ZStack {
            Tokens.dim.color.ignoresSafeArea().onTapGesture { self.dialog = nil }
            Group {
                switch dialog {
                case .discard:
                    DialogView(
                        title: "Discard changes?",
                        message: "What you typed here goes away.",
                        cancel: "Keep editing",
                        action: "Discard",
                        destructive: true,
                        onCancel: { self.dialog = nil },
                        onAction: onClose
                    )
                case .archive:
                    DialogView(
                        title: "Archive \(store.name)?",
                        message: "\(membersCount == 1 ? "1 student stays" : "\(membersCount) students stay") in "
                            + "Students with no batch. Attendance history is kept. The batch leaves every list.",
                        action: "Archive",
                        destructive: false,
                        onCancel: { self.dialog = nil },
                        onAction: archiveNow
                    )
                }
            }
            .padding(.horizontal, Tokens.pageSide)
        }
        .transition(.opacity)
    }

    private func cancel() {
        if store.isChanged {
            dialog = .discard
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

    private func archiveNow() {
        dialog = nil
        Task {
            await onArchive?()
            onClose()
        }
    }
}

/// A time on a tile: the value in accentText bodyStrong that opens the system's 24-hour time picker (with Clear, so a
/// class can go back to no fixed time), or "Not set".
struct TimeControl: View {
    let label: String
    let time: TimeOfDay?
    let set: (TimeOfDay?) -> Void
    @State private var picking = false

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
                        // The time is the centre's (India's), whatever zone the phone is in.
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
            Button("Not set") { set(ClassFormStore.defaultStart) }.buttonStyle(.quiet)
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

public extension ClassFormSheet {
    /// The boards' new class (P3-NewClass): Class 12 Physics, Tuesday, Thursday and Saturday, 18:00 to 19:30.
    static func fixture() -> ClassFormStore {
        let form = ClassFormStore(mode: .new)
        form.name = "Class 12 Physics"
        form.subject = "Physics"
        form.feeText = "1,500"
        form.daySelection = [2, 4, 6]
        form.setStart(TimeOfDay(hour: 18, minute: 0))
        form.setEnd(TimeOfDay(hour: 19, minute: 30))
        return form
    }
}
