import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on Reports: the Attendance segment, the Share as CSV sheet, November (nothing yet), or
/// Progress by month, by term, with its sort menu open, or shared.
public enum ReportsBoardState: Hashable, Sendable {
    case attendance
    case export
    case november
    case progress, progressTerm, progressSort, progressExport
}

/// Reports (P5-Reports-Fees dark and light, -Attendance, -Empty), pushed from More: the month, Fees | Attendance, the
/// hero and one row per student; Share opens the CSV sheet (P5-Reports-Export).
public struct ReportsView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view.
    @State private var store: ReportsStore
    private let boardState: ReportsBoardState?
    private let onMessage: (String) -> Void
    /// AppShell's: the offline line when the report is this iPhone's copy (U26).
    private let status: (ReportsStore) -> RootStatus
    private let openStudent: (UUID) -> Void
    @State private var exporting = false
    @State private var sorting = false
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(
        store: ReportsStore, boardState: ReportsBoardState? = nil,
        status: @escaping (ReportsStore) -> RootStatus = { _ in .online },
        openStudent: @escaping (UUID) -> Void = { _ in }, onMessage: @escaping (String) -> Void
    ) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.status = status
        self.openStudent = openStudent
        self.onMessage = onMessage
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Reports", action: ("Share", { exporting = true })) { dismiss() }
                if let line = status(store).line {
                    StatusLine(line)
                }
                MonthHeader(
                    title: store.spanTitle,
                    previous: { Task { await store.previous() } },
                    next: { Task { await store.next() } }
                )
                .padding(.horizontal, Tokens.rowGapInner)
                Segmented(options: ReportsStore.Segment.allCases.map { ($0, $0.title) }, selection: $store.segment)
                if store.segment == .progress {
                    Segmented(options: ReportsStore.Span.allCases.map { ($0, $0.title) }, selection: $store.span)
                }
                if let error = store.error {
                    FeesErrorLine(error) { Task { await store.retryLast() } }
                }
                Group {
                    if store.segment == .progress {
                        progress
                    } else if store.isEmpty {
                        Card {
                            EmptyRow(
                                symbol: "chart.bar", title: "Nothing for \(store.month.monthName) yet",
                                line: "The month's fees and attendance appear here once there are some."
                            )
                        }
                    } else if store.segment == .fees {
                        fees
                    } else {
                        attendance
                    }
                }
                .opacity(store.loading ? Tokens.opacityStale : 1)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $exporting) {
            ExportSheet(store: store, initial: store.segment, onMessage: onMessage) { exporting = false }
        }
        .task {
            await setUpBoardState()
            await store.load()
            if boardState == .progressSort {
                sorting = true
            }
        }
        .onChange(of: store.segment) { Task { await store.load() } }
        .onChange(of: store.span) { Task { await store.load() } }
    }

    @ViewBuilder private var progress: some View {
        if store.showsNoStudents {
            Card {
                EmptyRow(
                    symbol: "chart.bar", title: "No students yet",
                    line: "Each student's progress appears here once you add students."
                )
            }
        } else {
            progressRowsSection
        }
    }

    @ViewBuilder private var progressRowsSection: some View {
        if let hero = store.progressHero {
            ProgressHeroCard(
                skillsSecure: hero.skillsSecure, rightText: hero.rightText, notOnTrack: hero.notOnTrack,
                notOnTrackLabel: hero.notOnTrackLabel
            )
        }
        let rows = store.progressRows
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            HStack(alignment: .firstTextBaseline) {
                Text(store.studentsTitle).typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Menu {
                    Picker("Sort by", selection: $store.sort) {
                        ForEach(ProgressSort.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                } label: {
                    Text(store.sort.title).typeStyle(Tokens.buttonSecondary).foregroundStyle(Tokens.accentText.color)
                }
                .accessibilityLabel("Sort by \(store.sort.title)")
                .popover(isPresented: $sorting) { sortChoices }
            }
            .padding(.horizontal, Tokens.rowGapInner)
            Card {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        StudentProgressRow(
                            initials: row.initials, name: row.name, status: Self.kind(row.status),
                            statusWord: row.status.title, line: row.line, percent: row.percentText
                        ) { openStudent(row.id) }
                            .rowDivider(row.id != rows.last?.id)
                    }
                }
            }
        }
    }

    /// The sort menu as a launch state draws it open (the system menu takes no injected tap).
    private var sortChoices: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(ProgressSort.allCases, id: \.self) { sort in
                Button {
                    store.sort = sort
                    sorting = false
                } label: {
                    HStack {
                        Image(systemName: "checkmark").opacity(store.sort == sort ? 1 : 0).accessibilityHidden(true)
                        Text(sort.title).typeStyle(Tokens.body)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, Tokens.rowPaddingDense)
                    .padding(.horizontal, Tokens.rowPaddingHorizontal)
                    .contentShape(.rect)
                }
                .foregroundStyle(Tokens.text.color)
            }
        }
        .presentationCompactAdaptation(.popover)
    }

    nonisolated static func kind(_ status: TrackStatus) -> TrackKind {
        switch status {
        case .notOnTrack: .notOnTrack
        case .watch: .watch
        case .onTrack: .onTrack
        case .notKnown: .notKnown
        }
    }

    @ViewBuilder private var fees: some View {
        MoneyPair(
            outstanding: store.totals.outstanding.formatted, outstandingLine: store.feesLines.outstandingLine,
            collected: store.totals.collected.formatted, collectedLine: store.feesLines.collectedLine
        )
        let lines = store.feeLines
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(store.studentsTitle)
            Card {
                VStack(spacing: 0) {
                    ForEach(lines) { line in
                        ReportFeeRow(
                            name: line.name, className: line.className, amount: line.amount,
                            chip: LedgerSections.chip(line.state)
                        )
                        .rowDivider(line.id != lines.last?.id)
                    }
                }
            }
        }
    }

    @ViewBuilder private var attendance: some View {
        if let hero = store.attendanceHero {
            PercentHero(eyebrow: store.monthTitle, percent: hero.percent, fraction: hero.fraction, line: hero.line)
        }
        let lines = store.attendanceLines
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(store.studentsTitle)
            Card {
                VStack(spacing: 0) {
                    ForEach(lines) { line in
                        ReportAttendanceRow(
                            name: line.name,
                            present: line.present,
                            absent: line.absent,
                            percent: line.percent
                        )
                        .rowDivider(line.id != lines.last?.id)
                    }
                }
            }
        }
    }

    private func setUpBoardState() async {
        switch boardState {
        case .attendance: store.segment = .attendance
        case .export: exporting = true
        case .november: await store.next()
        case .progress, .progressSort: store.segment = .progress
        case .progressTerm:
            store.segment = .progress
            store.span = .term
            await store.load()
            await store.previous()
        case .progressExport:
            store.segment = .progress
            exporting = true
        case nil: break
        }
    }
}
