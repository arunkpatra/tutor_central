import DesignSystem
import Domain
import SwiftUI

/// What a launch state opens over the detail: a confirmation, or the edit sheet.
public enum StudentDetailBoardState: Sendable {
    case archiveConfirm
    case deleteConfirm
    case edit
}

/// One student's hub, to P3-StudentDetail (dark and light) and P3-StudentDetail-Archived: the header, the parent
/// with Call and WhatsApp, this month's fee, this month's attendance, notes, then Archive or Restore and Delete. Edit
/// opens
/// the student form (P3-EditStudent).
public struct StudentDetailView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view, and this month's
    /// attendance
    /// read into the first must not be lost to the next.
    @State private var store: StudentDetailStore
    let register: RegisterStore
    let actions: StudentsActions
    let navigation: StudentsNavigation
    let boardState: StudentDetailBoardState?
    let onMissing: () -> Void
    @State private var confirming: Confirmation?
    @State private var deleting = false
    @State private var editing: StudentFormStore?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(
        store: StudentDetailStore,
        register: RegisterStore,
        actions: StudentsActions,
        navigation: StudentsNavigation,
        boardState: StudentDetailBoardState? = nil,
        onMissing: @escaping () -> Void
    ) {
        _store = State(initialValue: store)
        self.register = register
        self.actions = actions
        self.navigation = navigation
        self.boardState = boardState
        self.onMissing = onMissing
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                // Outside the student: a screen whose student has gone still has its way back.
                navigationRow(store.student)
                if let student = store.student {
                    header(student)
                    if let line = store.archivedLine {
                        Banner(symbol: "archivebox", text: line)
                    }
                    ParentCard(student: student, call: store.callURL, whatsApp: store.whatsAppURL, addContact: edit)
                    MonthFeeCard(
                        store: store,
                        seeAll: { actions.openStudentFees(student.id) },
                        act: actions.openFeeAction
                    )
                    attendance
                    notes(student)
                    buttons(student)
                }
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
            if let confirming, let student = store.student {
                ConfirmDialogs(
                    confirmation: confirming,
                    student: student,
                    deleting: deleting,
                    onCancel: { self.confirming = nil },
                    onArchive: archive,
                    onDelete: delete
                )
            }
        }
        .animation(.timingCurve(Tokens.easeOut, duration: Tokens.panel), value: confirming)
        .sheet(item: $editing) { form in
            StudentFormSheet(
                store: form,
                autofocus: false,
                onSave: { await register.updateStudent(store.id, with: $0) },
                onClose: { editing = nil }
            )
        }
        .task {
            await register.loadIfNeeded()
            guard store.student != nil else {
                // AppShell takes the route off the stack and says why: a dismiss during the push is lost.
                onMissing()
                return
            }
            setUpBoardState()
        }
        // A student who goes while the screen is open (deleted elsewhere, a refresh): the route leaves, with a word.
        // A deletion made here dismisses on its own.
        .onChange(of: store.student == nil) { _, missing in
            if missing, !deleting {
                onMissing()
            }
        }
    }

    private func navigationRow(_ student: Student?) -> some View {
        BackRow(title: student?.name ?? "", action: student == nil ? nil : editAction) { dismiss() }
    }

    /// A typed property: a ternary of tuples inline stalls the type checker (ios/CLAUDE.md).
    private var editAction: (label: String, run: () -> Void) {
        ("Edit", edit)
    }

    private func header(_ student: Student) -> some View {
        HStack(spacing: Tokens.cardPaddingCompact) {
            Avatar(initials: student.initials, size: Self.avatarSize)
            VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                Text(student.name)
                    .typeStyle(Tokens.title1)
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                FlowLayout(spacing: Tokens.inline) {
                    if let chip = store.archivedChip {
                        Chip(.neutral(chip, symbol: "archivebox"))
                    }
                    if let classroom = store.classroom {
                        Button { navigation.openClass(classroom.id) } label: { Chip(.neutral(classroom.name)) }
                            .pressable()
                    }
                    Text(store.feeLine)
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text2.color)
                        .frame(minHeight: Chip.height)
                }
            }
        }
    }

    private var attendance: some View {
        AttendanceCard(store: store) { actions.openStudentAttendance(store.id) }
    }

    private func notes(_ student: Student) -> some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Notes", action: ("Edit", edit))
            Card {
                if let notes = store.notesLine {
                    Text(notes)
                        .typeStyle(Tokens.body)
                        .foregroundStyle(Tokens.text.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Tokens.rowPaddingVertical)
                        .padding(.horizontal, Tokens.rowPaddingHorizontal)
                } else {
                    EmptyRow(
                        symbol: "doc.text",
                        title: "No notes yet",
                        line: "School, board, pickup: anything to remember about \(student.firstName)."
                    )
                }
            }
        }
    }

    private func buttons(_ student: Student) -> some View {
        HStack(spacing: Tokens.tileGap) {
            if student.isArchived {
                Button { Task { await store.restore() } } label: {
                    Label("Restore", systemImage: "arrow.counterclockwise")
                        .typeStyle(Tokens.buttonStrong)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary())
            } else {
                Button { confirming = .archive } label: {
                    Label("Archive", systemImage: "archivebox").frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary())
            }
            Button { confirming = .delete } label: {
                Label("Delete", systemImage: "trash").frame(maxWidth: .infinity)
            }
            .buttonStyle(.destructive())
        }
        .environment(\.buttonIconSize, Tokens.iconSmall)
    }

    /// 56 on a detail header (components.md, Avatar).
    static var avatarSize: CGFloat {
        56
    }

    private func edit() {
        guard let student = store.student else { return }
        editing = StudentFormStore(mode: .edit(student), classes: register.activeClasses, today: register.today)
    }

    private func archive() {
        confirming = nil
        Task { await store.archive() }
    }

    private func delete() {
        deleting = true
        Task {
            let deleted = await store.delete()
            confirming = nil
            if deleted {
                dismiss()
            } else {
                deleting = false
            }
        }
    }

    private func setUpBoardState() {
        switch boardState {
        case .archiveConfirm: confirming = .archive
        case .deleteConfirm: confirming = .delete
        case .edit: edit()
        case nil: break
        }
    }
}
