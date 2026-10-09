import SwiftUI

/// Weekday initials caption text3; day numbers subhead 600, 40 high; today in a 36 accent disc with textOnAccent 700;
/// a chosen day (not today) in a surface2 disc; a day with classes or events carries a 4 pt accentText dot under the
/// number; other months' days hidden. In a card: padding 12 14, radiusCard. The month title headline with chevron
/// buttons sits above when `showsMonth`; the Kit board draws one week.
public struct CalendarMonth: View {
    let days: [Date?]
    let today: Date
    @Binding var selected: Date?
    let marked: Set<Date>
    let calendar: Calendar
    /// The month and week forms draw their own card; the schedule's sits in a card with its month header.
    let framed: Bool
    static var dayHeight: CGFloat {
        40
    }

    static var disc: CGFloat {
        36
    }

    static var dot: CGFloat {
        4
    }

    /// The month of `month`, Monday first.
    public init(month: Date, today: Date, selected: Binding<Date?>, marked: Set<Date>, calendar: Calendar = .current) {
        self.init(
            days: Self.monthDays(month, calendar),
            today: today,
            selected: selected,
            marked: marked,
            calendar: calendar
        )
    }

    /// The Monday-to-Sunday week that holds `week`.
    public init(week: Date, today: Date, selected: Binding<Date?>, marked: Set<Date>, calendar: Calendar = .current) {
        let monday = Self.monday(of: week, calendar)
        let days = (0 ..< 7).map { calendar.date(byAdding: .day, value: $0, to: monday) }
        self.init(days: days, today: today, selected: selected, marked: marked, calendar: calendar)
    }

    /// A month of days in the centre's calendar (Schedule): no card of its own, so the month header sits with it in
    /// the caller's (P4-Schedule-Month). `components` are year, month and day; DesignSystem knows no Domain types.
    public init(
        year: Int, month: Int, today: DateComponents, selected: Binding<DateComponents>, marked: Set<DateComponents>,
        calendar: Calendar
    ) {
        let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? .now
        let date: (DateComponents) -> Date? = { calendar.date(from: $0) }
        self.init(
            days: Self.monthDays(first, calendar),
            today: date(today) ?? .now,
            selected: Binding(
                get: { date(selected.wrappedValue) },
                set: { picked in
                    if let picked {
                        selected.wrappedValue = calendar.dateComponents([.year, .month, .day], from: picked)
                    }
                }
            ),
            marked: Set(marked.compactMap(date)),
            calendar: calendar,
            framed: false
        )
    }

    private init(
        days: [Date?], today: Date, selected: Binding<Date?>, marked: Set<Date>, calendar: Calendar,
        framed: Bool = true
    ) {
        self.days = days
        self.today = today
        _selected = selected
        self.marked = Set(marked.map { calendar.startOfDay(for: $0) })
        self.calendar = calendar
        self.framed = framed
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Tokens.rowGapInner * 2), count: 7),
            spacing: Tokens.rowGapInner * 2
        ) {
            ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, initial in
                Text(initial).typeStyle(Tokens.caption).foregroundStyle(Tokens.text3.color)
            }
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: Self.dayHeight)
                }
            }
        }
        .modifier(CalendarFrame(framed: framed))
    }

    private func dayCell(_ day: Date) -> some View {
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let isSelected = selected.map { calendar.isDate(day, inSameDayAs: $0) } ?? false
        let number = calendar.component(.day, from: day)
        return Button {
            selected = day
            Haptic.play(.selection)
        } label: {
            VStack(spacing: Tokens.rowGapInner) {
                Text("\(number)")
                    .typeStyle(isToday ? Tokens.dayToday : Tokens.day)
                    .foregroundStyle((isToday ? Tokens.textOnAccent : Tokens.text).color)
                    // Two digits stay on one line in their seventh of the width (never "1 / 0").
                    .lineLimit(1)
                    .minimumScaleFactor(SingleLineTitle.smallest)
                    .frame(width: Self.disc, height: isToday || isSelected ? Self.disc : nil)
                    .background {
                        if isToday {
                            Circle().fill(Tokens.accent.color)
                        } else if isSelected {
                            Circle().fill(Tokens.surface2.color)
                        }
                    }
                if marked.contains(calendar.startOfDay(for: day)), !isToday, !isSelected {
                    Circle().fill(Tokens.accentText.color).frame(width: Self.dot, height: Self.dot)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Self.dayHeight)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day
            .formatted(Date.FormatStyle(timeZone: calendar.timeZone).weekday(.wide).day().month(.wide)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The month and week forms' own card: padding 12 14, radiusCard.
    private struct CalendarFrame: ViewModifier {
        let framed: Bool

        func body(content: Content) -> some View {
            if framed {
                content
                    .padding(.vertical, Tokens.rowPaddingDense)
                    .padding(.horizontal, Tokens.cardPaddingCompact)
                    .surface(radius: Tokens.radiusCard)
            } else {
                content
            }
        }
    }

    nonisolated static func monday(of date: Date, _ calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: start) // Sunday 1 … Saturday 7
        return calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: start) ?? start
    }

    nonisolated static func monthDays(_ month: Date, _ calendar: Calendar) -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let count = calendar.range(of: .day, in: .month, for: month)?.count else { return [] }
        let first = interval.start
        let lead = (calendar.component(.weekday, from: first) + 5) % 7
        let days = (0 ..< count).map { calendar.date(byAdding: .day, value: $0, to: first) }
        return Array(repeating: nil, count: lead) + days
    }
}
