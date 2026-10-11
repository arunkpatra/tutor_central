import DesignSystem
import Domain
import SwiftUI

/// The calendar (P10-School-Calendar): the month with a dot per kind of item, then the chosen day's heading and items.
struct SchoolCalendarSection: View {
    @Bindable var store: SchoolStore
    let open: @MainActor (UUID) -> Void

    var body: some View {
        let calendar = store.calendar
        let day = store.selectedDay ?? store.today
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            Card {
                VStack(spacing: Tokens.tileGap) {
                    MonthHeader(title: store.month.title, previous: store.previousMonth, next: store.nextMonth)
                    CalendarMonth(
                        month: store.month.start(in: calendar.timeZone),
                        today: store.today.date(in: calendar),
                        selected: Binding(
                            get: { store.selectedDay?.date(in: calendar) },
                            set: { picked in store.selectedDay = picked.map { Day($0, calendar: calendar) } }
                        ),
                        dots: Dictionary(uniqueKeysWithValues: store.dots
                            .map { ($0.key.date(in: calendar), $0.value) }),
                        calendar: calendar
                    )
                }
                .padding(.vertical, Tokens.rowPaddingDense)
                .padding(.horizontal, Tokens.cardPaddingCompact)
            }
            // A day with nothing shows no section: no board draws an empty day.
            if !store.dayRows.isEmpty {
                VStack(alignment: .leading, spacing: Tokens.sectionHeaderGap) {
                    SectionHeader(day.weekdayLongText)
                    SchoolRowsCard(rows: store.dayRows, open: open)
                }
            }
        }
    }
}
