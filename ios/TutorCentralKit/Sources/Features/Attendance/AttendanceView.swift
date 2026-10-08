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
}

/// The Attendance tab's root, to P4-Attendance-Mark-Fresh (dark and light), -ClassMenu, -Exceptions, -Saved,
/// -PastDate, P4-Absence-Alert and P4-Attendance-Empty: the date and the class, everyone present, the whole row
/// toggles, Save in a footer above the tab bar; once saved, the absent students with Tell parent.
public struct AttendanceView: View {
    @Bindable var store: AttendanceStore
    let actions: AttendanceActions
    let boardState: AttendanceBoardState?
    @State private var topInset: CGFloat = 0
    @State private var picksDate = false
    @State private var picksClass = false
    @State private var alert: AbsenceAlert?
    @Environment(\.openURL) private var openURL

    public init(store: AttendanceStore, actions: AttendanceActions, boardState: AttendanceBoardState? = nil) {
        self.store = store
        self.actions = actions
        self.boardState = boardState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                titleRow
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
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
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
        HStack(alignment: .lastTextBaseline) {
            Text("Attendance")
                .typeStyle(Tokens.display)
                .foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Tokens.inline)
            if store.hasStudents {
                Button("History", action: actions.openHistory).buttonStyle(.quiet)
            }
        }
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
                    .tint(Tokens.accent.color)
                    // The day is the centre's (India's), whatever zone the phone is in.
                    .environment(\.timeZone, DayHeading.india.timeZone)
                    .padding(Tokens.cardPaddingCompact)
                    .presentationCompactAdaptation(.popover)
                }
                .rowDivider()
            PickerLine(label: "Class", value: store.className) { picksClass = true }
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
            Banner(symbol: banner.symbol, text: banner.text, tone: banner.ok ? .ok : nil)
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
