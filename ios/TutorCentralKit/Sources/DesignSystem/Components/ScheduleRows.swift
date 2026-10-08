import SwiftUI

/// Schedule (a class on the schedule and on Today): the start over the end in the 46 column; the class; its line
/// ("5 of 6 present" in ok once marked, else the meeting summary in text2); a tick in ok when marked, else a chevron
/// (components.md, Rows).
public struct ScheduleRow: View {
    let start: String
    let end: String?
    let title: String
    let line: String
    let lineTone: StatusTone?
    let marked: Bool
    let action: () -> Void
    static var tick: CGFloat {
        Tokens.iconButton
    }

    public init(
        start: String, end: String?, title: String, line: String, lineTone: StatusTone? = nil, marked: Bool,
        action: @escaping () -> Void
    ) {
        self.start = start
        self.end = end
        self.title = title
        self.line = line
        self.lineTone = lineTone
        self.marked = marked
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            DayColumn(top: start, bottom: end)
            RowLines(title: title, line: line, lineTone: lineTone)
            if marked {
                Image(systemName: "checkmark")
                    .font(.system(size: Self.tick, weight: .semibold))
                    .foregroundStyle(Tokens.ok.color)
                    .accessibilityLabel("Marked")
            } else {
                Chevron()
            }
        }
    }
}

/// Event (schedule, coming up): the start over the end in the 46 column ("Sat 10" alone in a list of days); the
/// title; the note or the time; a chevron that opens Edit event.
public struct EventRow: View {
    let start: String
    let end: String?
    let title: String
    let line: String?
    let action: () -> Void

    public init(start: String, end: String?, title: String, line: String?, action: @escaping () -> Void) {
        self.start = start
        self.end = end
        self.title = title
        self.line = line
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            DayColumn(top: start, bottom: end)
            RowLines(title: title, line: line, lineTone: nil)
            Chevron()
        }
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        Card {
            ScheduleRow(
                start: "17:00", end: "18:00", title: "Class 10 Maths", line: "5 of 6 present", lineTone: .ok,
                marked: true
            ) {}
                .rowDivider()
            ScheduleRow(
                start: "16:30", end: "17:30", title: "Class 8 Science", line: "Tue, Thu · 16:30–17:30", marked: false
            ) {}
        }
        Card {
            EventRow(
                start: "11:00", end: "12:00", title: "Parents' meeting",
                line: "Class 10 parents. Bring the September test papers."
            ) {}
                .rowDivider()
            EventRow(start: "Sat 17", end: nil, title: "Mock test, Class 10", line: "10:00–12:00") {}
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
