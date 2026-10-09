import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on History so it can be photographed beside its board: the By student view.
public enum HistoryBoardState: Sendable {
    case byStudent
}

/// History (P4-History-ByDate, -ByStudent, -Empty), pushed from the mark screen's History: By date | By student, the
/// month with its chevrons, then the month's summary and its classes, or every student with their percentage.
public struct HistoryView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view.
    @State private var store: HistoryStore
    let openSession: (AttendanceSession) -> Void
    let openStudent: (UUID) -> Void
    let boardState: HistoryBoardState?
    /// AppShell's: the offline or sync line under the title (D39), for this screen's store.
    let status: StatusFor
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(
        store: HistoryStore, openSession: @escaping (AttendanceSession) -> Void,
        openStudent: @escaping (UUID) -> Void, boardState: HistoryBoardState? = nil,
        status: @escaping StatusFor = { _, _ in .online }
    ) {
        self.status = status
        _store = State(initialValue: store)
        self.openSession = openSession
        self.openStudent = openStudent
        self.boardState = boardState
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "History") { dismiss() }
                if let line = status(store.savedAt, store.offlineRead).line {
                    StatusLine(line)
                }
                Segmented(options: [(.byDate, "By date"), (.byStudent, "By student")], selection: $store.view)
                MonthHeader(
                    title: store.monthTitle,
                    previous: { Task { await store.previousMonth() } },
                    next: { Task { await store.nextMonth() } }
                )
                .padding(.horizontal, Tokens.rowGapInner)
                if let error = store.error {
                    AttendanceErrorLine(error) { Task { await store.load() } }
                }
                Group {
                    if store.sessions.isEmpty, !store.loading {
                        Card {
                            EmptyRow(
                                symbol: "checkmark.circle",
                                title: "Nothing marked yet",
                                line: "Classes you mark show here by date and by student, with each month's percentage."
                            )
                        }
                    } else if store.view == .byDate {
                        byDate
                    } else {
                        byStudent
                    }
                }
                .opacity(store.loading ? Tokens.opacityStale : 1)
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            if boardState == .byStudent {
                store.view = .byStudent
            }
            await store.load()
        }
    }

    @ViewBuilder private var byDate: some View {
        if let summary = store.summary {
            HStack(spacing: Tokens.rowPaddingDense) {
                VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                    Text(summary.title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    ProgressBar(fraction: summary.fraction)
                }
                VStack(alignment: .trailing, spacing: Tokens.rowGapInner) {
                    Text(summary.percent).typeStyle(Tokens.numberRow).foregroundStyle(Tokens.text.color)
                    Text(summary.count).typeStyle(Tokens.caption).foregroundStyle(Tokens.text2.color)
                }
                .monospacedDigit()
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .accessibilityElement(children: .combine)
            .surface(radius: Tokens.radiusTile)
        }
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Classes")
            Card {
                VStack(spacing: 0) {
                    let rows = store.dateRows
                    ForEach(rows) { row in
                        HistoryRow(
                            day: row.day, date: row.date, title: row.title, line: row.line, trailing: row.absent
                        ) { openSession(row.session) }
                            .rowDivider(row.id != rows.last?.id)
                    }
                }
            }
        }
    }

    private var byStudent: some View {
        let rows = store.studentRows
        return VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(
                rows.count == 1 ? "1 student" : "\(rows.count) students",
                action: (store.sortLowestFirst ? "By name" : "Lowest first", { store.sortLowestFirst.toggle() })
            )
            Card {
                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        StudentPercentRow(
                            name: row.student.name, fraction: row.fraction, percent: row.percent, count: row.count
                        ) { openStudent(row.student.id) }
                            .rowDivider(row.id != rows.last?.id)
                    }
                }
            }
        }
    }
}
