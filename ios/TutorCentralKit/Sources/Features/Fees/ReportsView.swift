import DesignSystem
import Domain
import SwiftUI

/// What a launch state sets up on Reports: the Attendance segment, the Share as CSV sheet, or November (nothing yet).
public enum ReportsBoardState: Hashable, Sendable {
    case attendance
    case export
    case november
}

/// Reports (P5-Reports-Fees dark and light, -Attendance, -Empty), pushed from More: the month, Fees | Attendance, the
/// hero and one row per student; Share opens the CSV sheet (P5-Reports-Export).
public struct ReportsView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view.
    @State private var store: ReportsStore
    private let boardState: ReportsBoardState?
    private let onMessage: (String) -> Void
    @State private var exporting = false
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: ReportsStore, boardState: ReportsBoardState? = nil, onMessage: @escaping (String) -> Void) {
        _store = State(initialValue: store)
        self.boardState = boardState
        self.onMessage = onMessage
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Reports", action: ("Share", { exporting = true })) { dismiss() }
                MonthHeader(
                    title: store.monthTitle,
                    previous: { Task { await store.previous() } },
                    next: { Task { await store.next() } }
                )
                .padding(.horizontal, Tokens.rowGapInner)
                Segmented(options: ReportsStore.Segment.allCases.map { ($0, $0.title) }, selection: $store.segment)
                if let error = store.error {
                    FeesErrorLine(error) { Task { await store.retryLast() } }
                }
                Group {
                    if store.isEmpty {
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
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $exporting) {
            ExportSheet(store: store, initial: store.segment, onMessage: onMessage) { exporting = false }
        }
        .task {
            await store.load()
            await setUpBoardState()
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
        case nil: break
        }
    }
}
