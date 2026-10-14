import Artefacts
import Data
import DesignSystem
import Domain
import Make
import School
import SwiftUI
import Today

/// The School tab's wiring (Phase 13): the root, "Check what was read", an item's page. The share hand-off is
/// `ShellState.inboxHandoff`.
extension RootView {
    /// One School tab per centre (`ShellState.school`), so a tab switch keeps its segment and day.
    func schoolStore(for workspace: Workspace) -> SchoolStore {
        if let store = shell.school {
            return store
        }
        let store = SchoolStore(
            workspace: workspace, items: deps.schoolItems, register: register(for: workspace), schools: deps.schools,
            cache: deps.cachesLists ? SchoolCache(centre: workspace.centre.id, directory: deps.filesDirectory) : nil,
            now: deps.now, calendar: DayHeading.india
        )
        shell.school = store
        shell.tabs.onTabChosen = { [weak store] in store?.showAll() }
        return store
    }

    var schoolActions: SchoolActions {
        SchoolActions(
            openItem: { shell.tabs.push(.schoolItem($0)) },
            read: { shell.tabs.push(.schoolRead($0)) },
            askParents: { shell.tabs.push(.schoolAsk) }
        )
    }

    @ViewBuilder var schoolView: some View {
        if case let .ready(workspace) = session.state {
            let store = schoolStore(for: workspace)
            SchoolView(
                store: store, actions: schoolActions, boardState: launch.flatMap(Self.schoolBoardState),
                status: { rootStatus(savedAt: $0, offlineRead: $1) }
            )
        }
    }

    @ViewBuilder func schoolScreen(_ route: Route) -> some View {
        if case let .ready(workspace) = session.state {
            switch route {
            case let .schoolRead(source):
                ReadScreen(
                    store: readStore(source, workspace: workspace),
                    boardState: launch == .schoolConfirmEdit ? .editFirst : nil,
                    leave: { shell.tabs.remove(route) },
                    done: { items in
                        shell.tabs.remove(route)
                        schoolItemsAdded(items, workspace: workspace)
                    }
                )
            case let .schoolItem(id):
                ItemScreen(
                    store: itemStore(id, workspace: workspace),
                    boardState: Self.itemBoardState(launch),
                    actions: ItemActions(
                        openToday: { shell.openToday(batch: $0) },
                        openArtefact: { shell.tabs.push(.artefact($0)) },
                        testTomorrow: { shell.testTomorrow = $0 },
                        markPaper: { student, mock, exam in markMock(student, mock: mock, exam: exam) },
                        openGapReport: { exam, student in shell.tabs.push(.schoolGapReport(exam, student)) },
                        openStudent: { shell.tabs.push(.student($0)) }
                    ),
                    recordChanged: shell.recordChanged,
                    back: { shell.tabs.remove(route) }
                )
            case .schoolAsk:
                AskScreen(
                    store: AskStore(
                        workspace: workspace, register: register(for: workspace), messages: deps.messages,
                        open: { url in systemOpenURL(url) }, now: deps.now,
                        online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
                    ),
                    back: { shell.tabs.remove(route) }
                )
            case let .schoolGapReport(exam, student):
                GapReportScreen(
                    store: gapReportStore(exam: exam, student: student, workspace: workspace),
                    actions: GapReportActions(openToday: { shell.openToday(batch: $0) })
                )
            default:
                EmptyView()
            }
        }
    }

    private func gapReportStore(exam: UUID, student: UUID, workspace: Workspace) -> GapReportStore {
        let store = GapReportStore(
            itemID: exam, studentID: student, workspace: workspace, register: register(for: workspace),
            plans: deps.plans, ai: deps.ai, record: deps.record, schoolItems: deps.schoolItems, now: deps.now,
            calendar: DayHeading.india
        )
        store.online = { [connectivity = deps.connectivity] in await connectivity.isOnline }
        store.onUsed = { [shell] student in
            shell.recordChanged += 1
            shell.schoolItemsChanged?([student])
        }
        return store
    }

    /// The last days' Mark from a photo: Check a paper with the student and the mock's key.
    private func markMock(_ student: Student, mock: Artefact, exam: SchoolItem) {
        guard let generation = mock.generationID else { return }
        let visit = UUID()
        shell.checkPresets[visit] = CheckPreset(
            studentID: student.id, scheme: .mock(generationID: generation, artefactID: mock.id),
            mark: MarkTarget(
                subject: exam.subject ?? "", test: "\(exam.title) · mock", schoolItemID: exam.id, artefactID: mock.id
            )
        )
        shell.tabs.push(.checkPaper(visit))
    }

    private func readStore(_ source: ReadSource, workspace: Workspace) -> ReadStore {
        let leave: (@MainActor () -> Void)? = if case let .shared(read) = source {
            { try? SharedInbox.live()?.remove(id: read.id) }
        } else {
            nil
        }
        return ReadStore(
            source: source, workspace: workspace, items: deps.schoolItems, ai: deps.ai,
            register: register(for: workspace),
            schools: deps.schools, photos: deps.photos, leaveInbox: leave, now: deps.now, calendar: DayHeading.india,
            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
        )
    }

    private func itemStore(_ id: UUID, workspace: Workspace) -> ItemStore {
        let store = ItemStore(
            itemID: id, workspace: workspace, items: deps.schoolItems, register: register(for: workspace),
            schools: deps.schools, photos: deps.photos, now: deps.now, calendar: DayHeading.india,
            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }, textbooks: deps.textbooks,
            plans: deps.plans, record: deps.record
        )
        store.jobs = deps.jobs
        store.onChanged = { students in
            shell.schoolItemsChanged?(students)
            Task { await shell.school?.refresh() }
        }
        return store
    }

    /// Test tomorrow's sheet and the absence alert over whichever tab asked.
    func schoolSheets(_ tabs: some View) -> some View {
        tabs
            .sheet(item: $shell.testTomorrow, onDismiss: refreshToday, content: testTomorrowSheet)
            .sheet(item: $shell.absenceAlert) { ask in
                if case let .ready(workspace) = session.state {
                    absenceSheet(ask, workspace: workspace)
                }
            }
    }

    private func refreshToday() {
        Task { await shell.today?.load() }
    }

    @ViewBuilder private func testTomorrowSheet(_ ask: TestTomorrowAsk) -> some View {
        if case let .ready(workspace) = session.state {
            TestTomorrowScreen(store: testTomorrowStore(ask, workspace: workspace), close: { shell.testTomorrow = nil })
        }
    }

    /// To parents' Send: Test tomorrow's sheet for the student and the exam, or the absence alert.
    func sendToParent(_ row: ParentRowModel, workspace: Workspace) {
        guard let student = register(for: workspace).student(row.studentID) else { return }
        switch row.kind {
        case let .testTomorrow(item): shell.testTomorrow = TestTomorrowAsk(item: item, student: student)
        case .absentToday: shell.absenceAlert = AbsenceAsk(id: student.id)
        }
    }

    func testTomorrowStore(_ ask: TestTomorrowAsk, workspace: Workspace) -> TestTomorrowStore {
        TestTomorrowStore(
            ask: ask, workspace: workspace, ai: deps.ai, messages: deps.messages, textbooks: deps.textbooks,
            open: { url in systemOpenURL(url) }, now: deps.now, calendar: DayHeading.india,
            online: { [connectivity = deps.connectivity] in await connectivity.isOnline }
        )
    }

    /// The absence alert (V1's message) for a student marked absent today, logged before WhatsApp opens.
    @ViewBuilder func absenceSheet(_ ask: AbsenceAsk, workspace: Workspace) -> some View {
        if let student = register(for: workspace).student(ask.id) {
            let today = Day(deps.now(), calendar: DayHeading.india)
            let text = AbsenceMessage(
                parentName: student.parentName, studentName: student.name,
                className: register(for: workspace).classroom(student.classID)?.name, day: today, today: today,
                tutorName: workspace.profile.displayName, centreName: workspace.centre.name
            ).text
            MessageSheet(
                title: "Absence alert", name: student.name,
                parentLine: [student.parentName, student.parentPhone?.display].compactMap(\.self)
                    .joined(separator: " · "),
                text: text,
                note: "Opens WhatsApp with the message ready to send. We note it on \(student.firstName)'s page.",
                canOpen: student.parentPhone != nil,
                open: {
                    guard let phone = student.parentPhone else { return }
                    _ = try? await deps.messages.logAbsence(
                        centre: workspace.centre.id,
                        studentID: student.id,
                        about: today
                    )
                    systemOpenURL(AbsenceMessage.whatsAppURL(phone: phone, text: text))
                    shell.absenceAlert = nil
                    await shell.today?.load()
                },
                close: { shell.absenceAlert = nil }
            )
        }
    }

    /// Items added on "Check what was read": the tab reads them, and the plan hears whom they reach (decision 16).
    private func schoolItemsAdded(_ items: [SchoolItem], workspace: Workspace) {
        let students = register(for: workspace).activeStudents
        let reached = Set(items.flatMap { SchoolItemRules.students(for: $0, in: students).map(\.id) })
        shell.schoolItemsChanged?(reached)
        Task { await shell.school?.refresh() }
    }
}

/// "Check what was read" with its store kept for the life of the push (a rebuild must not read again).
struct ReadScreen: View {
    @State private var store: ReadStore
    let boardState: ReadBoardState?
    let leave: () -> Void
    let done: ([SchoolItem]) -> Void

    init(
        store: ReadStore, boardState: ReadBoardState?, leave: @escaping () -> Void,
        done: @escaping ([SchoolItem]) -> Void
    ) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.leave = leave
        self.done = done
    }

    var body: some View {
        ReadView(store: store, boardState: boardState, leave: leave, done: done)
    }
}

/// Test tomorrow's sheet with its store kept while it is up.
struct TestTomorrowScreen: View {
    @State private var store: TestTomorrowStore
    let close: () -> Void

    init(store: TestTomorrowStore, close: @escaping () -> Void) {
        _store = State(initialValue: store)
        self.close = close
    }

    var body: some View {
        TestTomorrowSheet(store: store, close: close)
    }
}

/// Ask parents to forward with its store kept for the life of the push.
struct AskScreen: View {
    @State private var store: AskStore
    let back: () -> Void

    init(store: AskStore, back: @escaping () -> Void) {
        _store = State(initialValue: store)
        self.back = back
    }

    var body: some View {
        AskView(store: store, back: back)
    }
}

/// An item's page with its store kept for the life of the push.
struct ItemScreen: View {
    @State private var store: ItemStore
    let boardState: ItemBoardState?
    let actions: ItemActions
    /// A mark saved or a gap report used while the page sat under it: it reads itself again.
    let recordChanged: Int
    let back: () -> Void

    init(
        store: ItemStore, boardState: ItemBoardState?, actions: ItemActions, recordChanged: Int,
        back: @escaping () -> Void
    ) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.actions = actions
        self.recordChanged = recordChanged
        self.back = back
    }

    var body: some View {
        ItemView(store: store, boardState: boardState, actions: actions, back: back)
            .onChange(of: recordChanged) { Task { await store.load() } }
    }
}

/// A gap report pushed from the exam's last days, its store kept in `@State`.
struct GapReportScreen: View {
    @State private var store: GapReportStore
    let actions: GapReportActions

    init(store: GapReportStore, actions: GapReportActions) {
        _store = State(initialValue: store)
        self.actions = actions
    }

    var body: some View {
        GapReportView(store: store, actions: actions)
    }
}
