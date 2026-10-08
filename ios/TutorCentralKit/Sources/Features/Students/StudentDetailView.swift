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
/// with Call and WhatsApp, this month's fee, attendance (later), notes, then Archive or Restore and Delete. Edit opens
/// the student form (P3-EditStudent).
public struct StudentDetailView: View {
    let store: StudentDetailStore
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
        self.store = store
        self.register = register
        self.actions = actions
        self.navigation = navigation
        self.boardState = boardState
        self.onMissing = onMissing
    }

    public var body: some View {
        ScrollView {
            if let student = store.student {
                VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                    navigationRow(student)
                    header(student)
                    if let line = store.archivedLine {
                        Banner(symbol: "archivebox", text: line)
                    }
                    ParentCard(student: student, call: store.callURL, whatsApp: store.whatsAppURL, addContact: edit)
                    MonthFeeCard(store: store) { actions.openStudentFees(student.id) }
                    attendance
                    notes(student)
                    buttons(student)
                }
                .padding(.horizontal, Tokens.pageSide)
                .padding(.top, max(0, Tokens.pageTop - topInset))
                .padding(.bottom, Tokens.contentBottom)
            }
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
    }

    private func navigationRow(_ student: Student) -> some View {
        ZStack {
            Text(student.name)
                .typeStyle(Tokens.headline)
                .foregroundStyle(Tokens.text.color)
                .lineLimit(1)
                .padding(.horizontal, IconButton.size + Tokens.inline)
            HStack {
                IconButton(symbol: "chevron.left", label: "Back") { dismiss() }
                Spacer()
                Button("Edit", action: edit).buttonStyle(.quiet)
            }
        }
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
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Attendance")
            Card {
                EmptyRow(
                    symbol: "checkmark.circle",
                    title: "Attendance comes in the next build",
                    line: "This month's presence and each absence will show here."
                )
            }
            .opacity(Tokens.opacityLater)
        }
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
            deleting = false
            confirming = nil
            if deleted {
                dismiss()
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
