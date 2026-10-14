import SwiftUI

/// School row (components.md 10.5): the day column (`time` over `caption`), the title `rowTitle`, the line `footnote`
/// `text2` (who, the school, the subject, the countdown), the kind chip, a chevron.
public struct SchoolRow: View {
    let day: String
    let date: String
    let title: String
    let line: String
    let kind: KindChipKind
    let action: () -> Void

    public init(
        day: String,
        date: String,
        title: String,
        line: String,
        kind: KindChipKind,
        action: @escaping () -> Void
    ) {
        self.day = day
        self.date = date
        self.title = title
        self.line = line
        self.kind = kind
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            // At the accessibility sizes the day goes above the words and the chip under them (Dynamic Type).
            AdaptiveRow {
                DayColumn(top: day, bottom: date)
                RowLines(title: title, line: line, lineTone: nil)
                KindChip(kind)
            }
            Chevron()
        }
    }
}

/// Preparation row (components.md 10.5): the School row's shape for a day of the split: the day column, the portion,
/// the line with what is made, and on the right a tick in `ok` (done), the Today chip (`due`, `clock`), the Mock chip
/// (neutral), or nothing.
public struct PreparationRow: View {
    /// `changed`: the `ok` chip with the tick, "Changed" (P21-Exam-LastDaysChanged).
    public enum Mark: Hashable, Sendable { case done, today, mock, changed, none }

    let day: String
    let date: String
    let title: String
    let line: String
    let mark: Mark
    let action: (() -> Void)?

    public init(day: String, date: String, title: String, line: String, mark: Mark, action: (() -> Void)?) {
        self.day = day
        self.date = date
        self.title = title
        self.line = line
        self.mark = mark
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            // At the accessibility sizes the day goes above the words and the mark under them (Dynamic Type).
            AdaptiveRow {
                DayColumn(top: day, bottom: date)
                RowLines(title: title, line: line, lineTone: nil)
                markView
            }
        }
    }

    @ViewBuilder private var markView: some View {
        switch mark {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: Tokens.iconButton, weight: .semibold))
                .foregroundStyle(Tokens.ok.color)
                .accessibilityLabel("Done")
        case .today: Chip(.status(.due, "Today", symbol: "clock"), compact: true)
        case .mock: Chip(.neutral("Mock"), compact: true)
        case .changed: Chip(.status(.ok, "Changed", symbol: "checkmark"), compact: true)
        case .none: EmptyView()
        }
    }
}

#Preview {
    Card {
        VStack(spacing: 0) {
            SchoolRow(
                day: "Fri", date: "16 Oct", title: "Science unit test 3",
                line: "Class 8 at Vidya Niketan · Dev, Meher, Nikhil · in 9 days", kind: .exam
            ) {}
                .rowDivider()
            PreparationRow(
                day: "Mon", date: "12 Oct", title: "Acids, bases and salts · first half",
                line: "Indicators, reactions with metals · a set", mark: .today, action: nil
            )
        }
    }
    .padding()
    .background(Tokens.ground.color)
}
