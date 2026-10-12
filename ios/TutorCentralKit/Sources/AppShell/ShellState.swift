import Artefacts
import Attendance
import Data
import Domain
import Fees
import Foundation
import Make
import Observation
import School
import Students
import Today

/// What the tabs remember while one tutor works in one centre: the selected tab, each tab's stack, Today's store and
/// the register. Leaving the tabs (sign-out) or arriving in another centre starts afresh, so the next tutor never sees
/// the last one's place, greeting or counts. One visit of Check a paper: its routes' id and its store.
struct CheckVisit {
    let id: UUID
    let store: CheckStore
}

extension CheckPreset {
    /// A mock's Mark from a photo as Check a paper's preset.
    init(_ mark: MockMark) {
        self.init(
            studentID: mark.student.id, scheme: mark.scheme,
            mark: MarkTarget(
                subject: mark.subject, test: mark.test, schoolItemID: mark.schoolItemID, artefactID: mark.artefactID
            )
        )
    }
}

/// A visit of Scan register: its number (`TabsState.scanVisits` when it was pushed) and its store.
struct ScanVisit {
    let number: Int
    let store: ScanStore
}

/// The student whose absence alert To parents opens.
struct AbsenceAsk: Identifiable, Hashable {
    let id: UUID
}

@MainActor @Observable final class ShellState {
    var tabs: TabsState
    var today: TodayStore?
    /// Made by the first Students screen and shared by every other; nothing observes the slot itself, so filling it
    /// while a view is built changes nothing on screen.
    @ObservationIgnored var register: RegisterStore?
    /// One mark screen per centre, so a tab switch keeps the date, the class and the unsaved toggles.
    @ObservationIgnored var attendance: AttendanceStore?
    /// One fees store per centre, so a tab switch keeps the month and the filter.
    @ObservationIgnored var fees: FeesStore?
    /// One tasks store per centre, shared by Today's Tasks card and the Tasks screen.
    @ObservationIgnored var tasks: TasksStore?
    /// One School tab per centre, so a tab switch keeps the segment and the chosen day.
    @ObservationIgnored var school: SchoolStore?
    /// Test tomorrow's sheet, over whichever tab asked (Today's To parents, an exam's page).
    var testTomorrow: TestTomorrowAsk?
    /// The absence alert's sheet for a student, from Today's To parents.
    var absenceAlert: AbsenceAsk?
    /// What an added, changed or deleted item reached: Today makes an open plan again for those students (Task 17).
    @ObservationIgnored var schoolItemsChanged: (@MainActor (Set<UUID>) -> Void)?
    /// Marks saved or undone and gap reports used: an exam's page on the stack reads itself again (hand run 9).
    var recordChanged = 0
    /// A mock's Mark from a photo, by the Check a paper visit it opens.
    @ObservationIgnored var checkPresets: [UUID: CheckPreset] = [:]
    /// One AI store per centre: a call outlives its screen, and Recent and History are read once.
    @ObservationIgnored var ai: AIStore?
    /// Make something's store for the centre (Recent and History read once; Phase 15).
    @ObservationIgnored var make: MakeStore?
    /// The tutor's words from Make's note, for the note screen it opens (taken when the screen is built).
    @ObservationIgnored var noteWords: [UUID: String] = [:]

    /// The words for the note screen being built, taken so a later open of the student's note makes nothing new.
    func takeNoteWords(for student: UUID) -> String? {
        noteWords.removeValue(forKey: student)
    }

    /// The visit of Check a paper in progress, by its routes' id.
    @ObservationIgnored var check: CheckVisit?
    /// The visit of Scan register in progress: its list lives until Add or Back (Phase 6's minor 1).
    @ObservationIgnored var scan: ScanVisit?
    /// The centre's queue of changes made offline (D39), read from its file when the centre arrives, and its runner.
    @ObservationIgnored var queue: ChangeQueue?
    /// The centre's activity log (D77): made with the queue, gone with it; none in the launch states.
    @ObservationIgnored var recorder: ActivityRecorder?
    /// The app came to the front (the scene's active, at a launch too) and that is not recorded yet: a launch waits for
    /// the centre's log.
    @ObservationIgnored private var openedPending = false
    @ObservationIgnored var runner: QueueRunner?
    /// The centre's reminder planner, made on first use.
    @ObservationIgnored var scheduler: ReminderScheduler?
    /// The network as the monitor last said; every root's status line follows it.
    var online = true
    var runState: RunState = .idle
    @ObservationIgnored private var centre: UUID?

    init(tabs: TabsState = TabsState()) {
        self.tabs = tabs
    }

    /// The replay's state as the status line shows it: sending wins; failed changes in the queue show until they
    /// are discarded or sent; a sign-out stop waits for the next sign-in.
    var effectiveRun: RunState {
        if case .sending = runState {
            return runState
        }
        if let failed = queue?.pending.failedCount, failed > 0 {
            return .failed(failed)
        }
        return runState == .signedOut ? .signedOut : .idle
    }

    /// The screens read what the server has now: on coming back to the app and after the queue sent (the owner,
    /// 2026-10-09: what changed meanwhile shows without a pull). Attendance keeps unsaved marks; a read that fails
    /// keeps what is shown.
    /// A student's This week "Today" (U35): the Today tab at its root, scrolled to the batch's plan.
    func openToday(batch: UUID) {
        tabs.paths[.today] = []
        tabs.select(.today)
        today?.focusBatch = batch
    }

    func refreshScreens() async {
        async let today: Void? = today?.load()
        async let tasks: Void? = tasks?.load()
        async let fees: Void? = fees?.reload()
        async let attendance: Void? = attendance?.reload()
        async let school: Void? = school?.refresh()
        _ = await (today, tasks, fees, attendance, school)
    }

    /// The share hand-off (plan/phase-13-plan.md decision 25): the first item in the inbox opens "Check what was read"
    /// on the School tab once signed in; one at a time, never over a read screen already up. A photo that cannot be
    /// read is passed over (removed).
    func inboxHandoff(_ inbox: SharedInbox?, signedIn: Bool) {
        guard signedIn, let inbox, let item = try? inbox.items().first else { return }
        let reading = tabs.paths.values.contains { path in
            path.contains {
                if case .schoolRead = $0 {
                    true
                } else {
                    false
                }
            }
        }
        guard !reading else { return }
        let image = item.kind == .image ? inbox.image(of: item).flatMap(PhotoReducer.reduce) : nil
        guard item.text != nil || image != nil else {
            try? inbox.remove(item)
            return
        }
        let read = SharedRead(id: item.id, text: item.text, image: image, receivedAt: item.receivedAt)
        tabs.selected = .school
        tabs.paths[.school] = [.schoolRead(.shared(read))]
    }

    /// `files` is where the centre's queue file lives (nil: Application Support).
    func sessionChanged(_ state: SessionStore.State, files: URL?, activity: (any ActivityRepository)? = nil) {
        guard case let .ready(workspace) = state else {
            reset()
            return
        }
        if let centre, centre != workspace.centre.id {
            reset()
        }
        if centre == nil {
            queue = ChangeQueue(centre: workspace.centre.id, directory: files)
            recorder = activity.map {
                ActivityRecorder(log: ActivityLog(centre: workspace.centre.id, repository: $0, directory: files))
            }
            tabs.onTabOpened = { [recorder] tab in Task { await recorder?.tabChosen(tab) } }
            recordOpened()
        }
        centre = workspace.centre.id
    }

    /// A launch or a return to the app: recorded and posted in a task of its own, never in the way of the return's
    /// refresh; at a launch, once the centre's log is made.
    func opened() {
        openedPending = true
        recordOpened()
    }

    private func recordOpened() {
        guard openedPending, let recorder else { return }
        openedPending = false
        Task { await recorder.cameBack() }
    }

    /// The scan visit is over (Add or Back): its store is let go.
    func endScan() {
        scan = nil
    }

    private func reset() {
        tabs = TabsState()
        today = nil
        register = nil
        attendance = nil
        fees = nil
        tasks = nil
        ai?.cancel()
        ai = nil
        make = nil
        noteWords = [:]
        school = nil
        schoolItemsChanged = nil
        testTomorrow = nil
        absenceAlert = nil
        check = nil
        checkPresets = [:]
        scan = nil
        queue = nil
        recorder = nil
        runner = nil
        scheduler = nil
        runState = .idle
        centre = nil
    }
}
