import DesignSystem
import Domain
import SwiftUI

/// What a launch state opens over the detail: a confirmation, or the edit sheet.
public enum StudentDetailBoardState: Sendable {
    case archiveConfirm
    case deleteConfirm
    case edit
    /// Scrolled to the record with the current chapter open (P10-Student-Record); to the end (P10-Student-End).
    case record
    case end
    /// The consent ask's sheet (P10-Consent-Ask); the Parent agreed sheet (P10-Consent-Record).
    case consentAsk
    case consentRecord
}

/// One student's hub, to P3-StudentDetail (dark and light) and P3-StudentDetail-Archived: the header, the parent with
/// Call and WhatsApp, this month's fee, this month's attendance, notes, then Archive or Restore and Delete. Edit opens
/// the student form (P3-EditStudent).
public struct StudentDetailView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view, and this month's
    /// attendance read into the first must not be lost to the next.
    @State var store: StudentDetailStore
    let register: RegisterStore
    let actions: StudentsActions
    let navigation: StudentsNavigation
    let boardState: StudentDetailBoardState?
    let onMissing: () -> Void
    /// A refused write's words, for AppShell's system alert (U33).
    let onMessage: (String) -> Void
    @State var confirming: Confirmation?
    @State var deleting = false
    @State var editing: StudentFormStore?
    @State var asking = false
    @State var addingChapter: AddingChapter?
    @State var recordingConsent = false
    @State var topInset: CGFloat = 0
    @Environment(\.dismiss) var dismiss

    public init(
        store: StudentDetailStore,
        register: RegisterStore,
        actions: StudentsActions,
        navigation: StudentsNavigation,
        boardState: StudentDetailBoardState? = nil,
        onMissing: @escaping () -> Void,
        onMessage: @escaping (String) -> Void = { _ in }
    ) {
        self.onMessage = onMessage
        _store = State(initialValue: store)
        self.register = register
        self.actions = actions
        self.navigation = navigation
        self.boardState = boardState
        self.onMissing = onMissing
    }

    public var body: some View {
        ScrollViewReader { reader in
            page.task(id: store.recordLoaded) { await scrollForBoard(reader) }
        }
    }

    private var page: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                // Outside the student: a screen whose student has gone still has its way back.
                navigationRow(store.student)
                if let student = store.student {
                    header(student)
                    if let line = store.archivedLine {
                        Banner(symbol: "archivebox", text: line)
                    }
                    if let tracking = store.tracking {
                        TrackingSection(lines: tracking, firstName: student.firstName, place: nil)
                    }
                    ParentCard(student: student, call: store.callURL, whatsApp: store.whatsAppURL, addContact: edit)
                    if !consentAgreed {
                        consentSection
                    }
                    ThisWeekSection(rows: store.thisWeek)
                    RecordSection(
                        store: store, addTextbook: { navigation.openTextbook(store.id, $0) },
                        addChapter: { addingChapter = AddingChapter(subject: $0) }
                    )
                    .id(Anchor.record)
                    if let checks = store.checks {
                        ChecksSection(lines: checks)
                    }
                    HomeworkSection(rows: store.homework) { id, status in Task { await store.setHomework(id, status) } }
                    SchoolSection(line: store.schoolEmptyLine)
                    MessagesSection(rows: store.messages).id(Anchor.end)
                    if consentAgreed {
                        consentSection
                    }
                    MonthFeeCard(
                        store: store,
                        seeAll: { actions.openStudentFees(student.id) },
                        act: actions.openFeeAction
                    )
                    attendance
                    NotesSection(notes: store.notesLine, firstName: student.firstName, edit: edit)
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
                onClose: { editing = nil },
                addClass: { await register.addClass($0) },
                addSchool: { await register.addSchool(name: $0) }
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
        .sheet(isPresented: $asking) {
            ConsentAskSheet(store: store.consent) { asking = false }
                .boardDetents(MessageSheet.boardFraction)
        }
        .sheet(item: $addingChapter) { adding in
            ChapterSheet(
                position: store.nextPosition(adding.subject), initialName: "", initialSkills: [],
                onSave: { name, skills in
                    Task { await store.addChapter(subject: adding.subject, name: name, skills: skills) }
                },
                onRemove: nil, close: { addingChapter = nil }
            )
        }
        .onAppear {
            // Back from Add a textbook: the chapters the book brought.
            if store.recordLoaded {
                Task { await store.loadRecord() }
            }
        }
        .sheet(isPresented: $recordingConsent) {
            ConsentRecordSheet(store: store.consent) { recordingConsent = false }
        }
        .onChange(of: store.consent.failure) { _, failure in
            guard let failure else { return }
            onMessage(failure)
            store.consent.failure = nil
        }
        .onChange(of: store.message) { _, message in
            guard let message else { return }
            onMessage(message)
            store.message = nil
        }
        .onChange(of: store.student == nil) { _, missing in
            if missing, !deleting {
                onMissing()
            }
        }
    }

    /// Consent waits under the parent while it asks something of the tutor (P10-Student-NotKnown, -Consent-Waiting);
    /// agreed, it sits after the messages (P10-Student-End).
    private var consentAgreed: Bool {
        if case .agreed = store.consent.state {
            true
        } else {
            false
        }
    }

    private var consentSection: some View {
        ConsentSection(store: store.consent, ask: { asking = true }, agreed: { recordingConsent = true })
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
                    if let classChip = store.classChip {
                        Chip(.neutral(classChip))
                    }
                    if let classroom = store.classroom {
                        Button { navigation.openClass(classroom.id) } label: { Chip(.neutral(classroom.name)) }
                            .pressable()
                    }
                }
                if let school = store.schoolLine {
                    Text(school).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
                Text(store.feeLine).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
        }
    }

    private var attendance: some View {
        AttendanceCard(store: store) { actions.openStudentAttendance(store.id) }
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

    func edit() {
        guard let student = store.student else { return }
        editing = register.form(.edit(student))
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
}

/// Add a chapter of the tutor's own to a subject on the page.
struct AddingChapter: Identifiable, Hashable {
    let subject: String
    var id: String {
        subject
    }
}
