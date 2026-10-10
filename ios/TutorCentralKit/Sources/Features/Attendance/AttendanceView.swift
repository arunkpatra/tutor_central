import Data
import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on the mark screen so it can be photographed beside its board: the class menu open,
/// Hemanth marked absent, the class saved with him absent, his parent's alert open, Monday 5 October reopened.
public enum AttendanceBoardState: Sendable {
    case classMenu
    case oneAbsent
    case saved
    case alert
    case past
    /// One absent, then Save refused: the system alert with Try Again (U33-Attendance-SaveFailed).
    case saveFailed
}

/// The mark screen, pushed (D65; P10-Attendance-Pushed over P4-Attendance-Mark-Fresh, -ClassMenu, -Exceptions, -Saved,
/// -PastDate, P4-Absence-Alert and P4-Attendance-Empty): Back, the title and the quiet History; the date and the batch,
/// everyone present, the whole row toggles, Save in the footer band above the safe area; once saved, the absent
/// students with Tell parent.
public struct AttendanceView: View {
    @Bindable var store: AttendanceStore
    let actions: AttendanceActions
    let boardState: AttendanceBoardState?
    @State private var topInset: CGFloat = 0
    @State private var picksDate = false
    /// AppShell's: the offline or sync line under the title (D39).
    let status: RootStatus
    @State private var picksClass = false
    @State private var alert: AbsenceAlert?
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    public init(
        store: AttendanceStore, actions: AttendanceActions, boardState: AttendanceBoardState? = nil,
        status: RootStatus = .online
    ) {
        self.store = store
        self.actions = actions
        self.boardState = boardState
        self.status = status
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                titleRow
                if let line = status.line {
                    StatusLine(line)
                }
                if store.hasStudents {
                    pickers
                    if let error = store.error {
                        AttendanceErrorLine(error) { Task { await store.open(
                            classID: store.draft.classID,
                            date: store.draft.date
                        ) } }
                    }
                    stateLine
                    if !store.absentRows.isEmpty {
                        AbsentSection(rows: store.absentRows) { alert = store.alert(for: $0) }
                    }
                    MembersSection(store: store)
                } else if store.opened {
                    NoStudentsCard(openStudents: actions.openStudents)
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.sectionGap)
        }
        // A pull reads the class and day again, as Today, Students and Fees do; unsaved marks are kept.
        .refreshable { await store.reload() }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if store.hasStudents {
                FooterButton { footer }
            }
        }
        .sheet(item: $alert) { shown in
            AbsenceAlertSheet(alert: shown, open: { await tell(shown) }, close: { alert = nil })
        }
        .task {
            await store.load()
            await setUpBoardState()
        }
        .onChange(of: store.lastSavedAt) { Haptic.play(.success) }
    }

    private var titleRow: some View {
        BackRow(
            title: "Attendance",
            action: store.hasStudents ? ("History", actions.openHistory) : nil,
            back: { dismiss() }
        )
    }

    private var pickers: some View {
        VStack(spacing: 0) {
            PickerLine(label: "Date", value: store.dateText) { picksDate = true }
                .popover(isPresented: $picksDate) {
                    DatePicker(
                        "Date",
                        selection: dateBinding,
                        in: ...store.today.date(in: DayHeading.india),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .calendarPopover(timeZone: DayHeading.india.timeZone)
                }
                .rowDivider()
            PickerLine(label: "Batch", value: store.className) { picksClass = true }
                .popover(isPresented: $picksClass, arrowEdge: .top) {
                    ClassMenu(options: store.classOptions, chosen: store.draft.classID) { classID in
                        picksClass = false
                        Task { await store.open(classID: classID, date: store.draft.date) }
                    }
                    .presentationCompactAdaptation(.popover)
                }
        }
        .surface(radius: Tokens.radiusTile)
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { store.draft.date.date(in: DayHeading.india) },
            set: { date in
                picksDate = false
                Task { await store.open(classID: store.draft.classID, date: Day(date, calendar: DayHeading.india)) }
            }
        )
    }

    /// The hint while nothing is saved; the banner after a save or on a day marked before.
    @ViewBuilder private var stateLine: some View {
        if let banner = store.banner {
            Banner(symbol: banner.symbol, text: banner.text, tone: banner.ok ? .ok : banner.due ? .due : nil)
        } else {
            Text("Everyone starts present. Tap anyone who did not come, then save.")
                .typeStyle(Tokens.footnote)
                .foregroundStyle(Tokens.text3.color)
                .padding(.horizontal, Tokens.rowGapInner)
        }
    }

    @ViewBuilder private var footer: some View {
        if case .saved = store.phase {
            SavedMark()
        } else if case .savedHere = store.phase, !store.canSave {
            SavedMark("Saved on this iPhone", keptHere: true)
        } else {
            let saving = store.phase == .saving
            Button(store.saveLabel) { Task { await store.save() } }
                .buttonStyle(.primary(.card, loading: saving))
                .disabled(!saving && !store.canSave)
                .allowsHitTesting(!saving)
        }
    }

    private func tell(_ shown: AbsenceAlert) async {
        guard let url = await store.tell(shown.student.id) else { return }
        openURL(url)
        alert = nil
    }

    private func setUpBoardState() async {
        let hemanth = FakeAttendanceRepository.hemanth
        switch boardState {
        case .classMenu:
            picksClass = true
        case .oneAbsent:
            store.toggle(hemanth)
        case .saveFailed:
            store.toggle(hemanth)
            await store.save()
        case .saved, .alert:
            store.toggle(hemanth)
            await store.save()
            if boardState == .alert {
                alert = store.alert(for: hemanth)
            }
        case .past:
            if let monday = Day(year: 2026, month: 10, day: 5) {
                await store.open(classID: FakeClassesRepository.maths.id, date: monday)
            }
        case nil:
            break
        }
    }
}
