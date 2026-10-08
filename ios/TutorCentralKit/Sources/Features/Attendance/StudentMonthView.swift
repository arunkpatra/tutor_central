import DesignSystem
import Domain
import SwiftUI

/// One student's month (P4-History-Student): the month with its chevrons, the percentage hero, the absences (each
/// with whether the parent was told) and the month before.
public struct StudentMonthView: View {
    /// Kept for the life of the screen: AppShell makes a store each time it builds the view.
    @State private var store: StudentMonthStore
    let openSession: (AttendanceSession) -> Void
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(store: StudentMonthStore, openSession: @escaping (AttendanceSession) -> Void) {
        _store = State(initialValue: store)
        self.openSession = openSession
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: store.name) { dismiss() }
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
                    let hero = store.hero
                    PercentHero(eyebrow: hero.eyebrow, percent: hero.percent, fraction: hero.fraction, line: hero.line)
                    absences
                    if !store.earlier.isEmpty {
                        earlier
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
        .task { await store.load() }
    }

    private var absences: some View {
        let rows = store.absences
        return VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader(rows.count == 1 ? "1 absence" : "\(rows.count) absences")
            Card {
                if rows.isEmpty {
                    EmptyRow(
                        symbol: "checkmark.circle",
                        title: "No absences this month",
                        line: "Each class \(store.name) misses shows here, with whether the parent was told."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(rows) { row in
                            HistoryRow(
                                day: row.day, date: row.date, title: row.title, line: row.line, lineTone: row.lineTone
                            ) { openSession(row.session) }
                                .rowDivider(row.id != rows.last?.id)
                        }
                    }
                }
            }
        }
    }

    private var earlier: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
            SectionHeader("Earlier")
            Card {
                VStack(spacing: 0) {
                    ForEach(store.earlier) { row in
                        HistoryRow(
                            day: String(row.title.prefix(3)), date: String(row.month.year), title: row.title,
                            line: row.line
                        ) { Task { await store.previousMonth() } }
                    }
                }
            }
        }
    }
}
