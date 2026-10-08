import SwiftUI

/// The system's graphical date picker shown in a popover from a row or a chip (the attendance date, an event's day, a
/// task's due day). Without a width the popover collapses the calendar to a sliver (seen in the hand run).
public enum CalendarPopover {
    /// The calendar's natural width on an iPhone.
    public static let width: CGFloat = 320
}

public extension View {
    /// On a `.graphical` `DatePicker` inside `.popover`: the calendar's width, the accent tint, the padding, and a
    /// popover (not a sheet) on iPhone; the day is the centre's (`timeZone`), whatever zone the phone is in.
    func calendarPopover(timeZone: TimeZone) -> some View {
        tint(Tokens.accent.color)
            .environment(\.timeZone, timeZone)
            .frame(width: CalendarPopover.width)
            .padding(Tokens.cardPaddingCompact)
            .presentationCompactAdaptation(.popover)
    }
}
