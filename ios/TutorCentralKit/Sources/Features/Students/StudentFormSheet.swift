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
    /// Makes a class from the menu's New class… (P7-NewStudent-NewClass); nil hides it (a scanned row).
    let addClass: ((ClassroomDraft) async -> Classroom?)?
    /// Adds a school from the school sheet's last row (V2); nil hides the row.
    let addSchool: ((String) async -> School?)?
    /// The board of the form's end (P10-NewStudent-End): opened scrolled to the notes.
    let scrolledToEnd: Bool
    @State private var newClass: ClassFormStore?
    @State var pickingClass = false
    @State var pickingSchool = false
    @State private var saving = false
    @State private var confirmingDiscard = false
    @State var pickingBirthDate = false

    /// `showsFocus` draws the name focused without the keyboard (the empty board); `autofocus` raises the keyboard on
    /// the name of a new student (off for every board state).
    public init(
        store: StudentFormStore,
        showsFocus: Bool = false,
        autofocus: Bool = true,
        onSave: @escaping (StudentDraft) async -> Bool,
        onClose: @escaping () -> Void,
        onRemove: (() -> Void)? = nil,
        addClass: ((ClassroomDraft) async -> Classroom?)? = nil,
        addSchool: ((String) async -> School?)? = nil,
        boardNewClass: ClassFormStore? = nil,
        boardPicker: StudentFormPicker? = nil,
        scrolledToEnd: Bool = false
    ) {
        self.scrolledToEnd = scrolledToEnd
        self.store = store
        self.showsFocus = showsFocus
        self.autofocus = autofocus
        self.onSave = onSave
        self.onClose = onClose
        self.onRemove = onRemove
        self.addClass = addClass
        self.addSchool = addSchool
        _newClass = State(initialValue: boardNewClass)
        _pickingClass = State(initialValue: boardPicker == .classWheel)
        _pickingSchool = State(initialValue: boardPicker == .school)
    }

    public var body: some View {
        VStack(spacing: Tokens.sectionGap) {
            SheetHeader(
                title: store.title,
                cancel: ("Cancel", cancel),
                save: .init("Save", enabled: store.canSave && !saving, run: save)
            )
            .padding(.horizontal, Tokens.pageSide)
            ScrollViewReader { reader in
                ScrollView {
                    fields
                        .padding(.horizontal, Tokens.pageSide)
                        .padding(.bottom, Tokens.contentBottom)
                    Color.clear.frame(height: 0).id(Self.end)
                }
                .task {
                    if scrolledToEnd {
                        try? await Task.sleep(for: .seconds(Tokens.panel))
                        reader.scrollTo(Self.end, anchor: .bottom)
                    }
                }
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
        .sheet(item: $newClass) { form in
            // On top of this form; saved, the class is chosen here (P7-NewStudent-ClassMade).
            ClassFormSheet(
                store: form,
                autofocus: true,
                onSave: { draft in
                    guard let made = await addClass?(draft) else { return false }
                    store.classAdded(made)
                    return true
                },
                onClose: { newClass = nil }
            )
        }
        .sheet(isPresented: $pickingSchool) {
            SchoolSheet(store: store, addSchool: addSchool) { pickingSchool = false }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    static let end = "end"

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
                placeholder: "The student's name",
                error: store.nameError,
                content: .name,
                showsFocus: showsFocus && !isFix,
                autofocus: autofocus && isNew
            )
            if !isFix {
                classTile
                PickerField(label: "School", value: store.schoolTitle, placeholder: "Choose or add") {
                    Keyboard.dismiss()
                    pickingSchool = true
                }
                if store.showsBoard {
                    boardMenu
                }
            }
            ClassMenu(store: store, canAdd: addClass != nil) { newClass = ClassFormStore(mode: .new) }
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
                placeholder: isFix ? "Parent's name" : "Who you message",
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
                ChipRow(
                    label: "Parent's message language",
                    options: MessageLanguage.allCases.map { ($0, $0.title) },
                    selection: $store.messageLanguage,
                    helper: store.languageHelper
                )
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
    /// The boards' sample (P10-NewStudent-Filled): Riya Sharma at class 5, Vidya Niketan, the Class 10 Maths batch at
    /// her
    /// own fee, her parent in Hindi; `invalid` leaves the number a digit short and checks it (P3-NewStudent-Invalid).
    @MainActor static func fixture(invalid: Bool, register: RegisterStore) -> StudentFormStore {
        let form = register.form(.new)
        form.name = "Riya Sharma"
        form.classLevel = .five
        form.schoolID = register.schools.first { $0.name == "Vidya Niketan" }?.id
        form.select(classID: FakeClassesRepository.maths.id)
        form.feeText = "1,500"
        form.parentName = "Neha Sharma"
        form.digits = invalid ? "981112223" : "9811122233"
        form.messageLanguage = .hindi
        form.hasBirthDate = true
        form.birthDate = Day(year: 2016, month: 3, day: 14) ?? register.today
        form.toggle(.female)
        form.notes = "Prefers the evening batch."
        if invalid {
            form.commitPhone()
        }
        return form
    }
}
