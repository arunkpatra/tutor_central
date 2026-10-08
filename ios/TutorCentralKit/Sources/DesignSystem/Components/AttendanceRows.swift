import SwiftUI

/// History (attendance): the day over the date in a 46 column (time text2 over caption text3); the class in rowTitle
/// and "5 of 6 present" in footnote text2 (or "Parent told on Mon 5 Oct" in ok); "1 absent" in footnote 600 overdue;
/// chevron (components.md, Rows).
public struct HistoryRow: View {
    let day: String
    let date: String
    let title: String
    let line: String
    let lineTone: StatusTone?
    let trailing: String?
    let action: () -> Void

    public init(
        day: String, date: String, title: String, line: String, lineTone: StatusTone? = nil, trailing: String? = nil,
        action: @escaping () -> Void
    ) {
        self.day = day
        self.date = date
        self.title = title
        self.line = line
        self.lineTone = lineTone
        self.trailing = trailing
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            DayColumn(top: day, bottom: date)
            RowLines(title: title, line: line, lineTone: lineTone)
            if let trailing {
                Text(trailing).typeStyle(Tokens.footnoteStrong).monospacedDigit().foregroundStyle(Tokens.overdue.color)
            }
            Chevron()
        }
    }
}

/// Student percentage (history by student): avatar 40; the name over a progress bar; the percentage in numberRow
/// over "9 of 12" in caption text2; chevron.
public struct StudentPercentRow: View {
    let name: String
    let fraction: Double
    let percent: String
    let count: String
    let action: () -> Void

    public init(name: String, fraction: Double, percent: String, count: String, action: @escaping () -> Void) {
        self.name = name
        self.fraction = fraction
        self.percent = percent
        self.count = count
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            Avatar(name: name)
            VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                Text(name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                ProgressBar(fraction: fraction)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: Tokens.rowGapInner) {
                Text(percent).typeStyle(Tokens.numberRow).monospacedDigit().foregroundStyle(Tokens.text.color)
                Text(count).typeStyle(Tokens.caption).monospacedDigit().foregroundStyle(Tokens.text2.color)
            }
            Chevron()
        }
    }
}

/// Absent student (saved attendance): avatar 40; the name and the parent with their number in footnote text2;
/// `TellParentButton` or `ToldMark` on the right.
public struct AbsentStudentRow<Trailing: View>: View {
    let name: String
    let line: String
    let trailing: Trailing

    public init(name: String, line: String, @ViewBuilder trailing: () -> Trailing) {
        self.name = name
        self.line = line
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Avatar(name: name)
            RowLines(title: name, line: line, lineTone: nil)
            trailing
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(minHeight: RowMetrics.minHeight)
    }
}

/// "Tell parent": a secondary button 36 high, radius 13, padding 0 12, footnote 600, the message glyph 16.
public struct TellParentButton: View {
    let enabled: Bool
    let action: () -> Void
    static var height: CGFloat {
        36
    }

    public init(enabled: Bool = true, action: @escaping () -> Void) {
        self.enabled = enabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.fieldGap) {
                Image(systemName: "message").font(.system(size: Tokens.iconInline))
                Text("Tell parent")
            }
            .typeStyle(Tokens.footnoteStrong)
            .foregroundStyle(Tokens.text.color)
            .padding(.horizontal, Tokens.rowPaddingDense)
            .frame(height: Self.height)
            .background(Tokens.buttonFill.color, in: .rect(cornerRadius: Tokens.radiusSegmentTrack, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radiusSegmentTrack, style: .continuous)
                    .strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline)
            )
            .shadowed(enabled ? [Tokens.shadowButton] : [], radius: Tokens.radiusSegmentTrack)
        }
        .pressable()
        .disabled(!enabled)
        .opacity(enabled ? 1 : Tokens.opacityDisabled)
        .fixedSize()
    }
}

/// "Told Mon 5 Oct": a tick 14 and the words in footnote 600 ok.
public struct ToldMark: View {
    let text: String
    static var tick: CGFloat {
        14
    }

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: Tokens.fieldGap) {
            Image(systemName: "checkmark").font(.system(size: Self.tick, weight: .bold))
            Text(text)
        }
        .typeStyle(Tokens.footnoteStrong)
        .foregroundStyle(Tokens.ok.color)
        .fixedSize()
        .accessibilityElement(children: .combine)
    }
}

/// The 46 column that leads a history, schedule or event row: a top line in time text2 and an optional second line in
/// caption text3 ("Wed" over "7 Oct", "17:00" over "18:00", "Sat 10" alone).
struct DayColumn: View {
    let top: String
    let bottom: String?
    static var width: CGFloat {
        46
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(top).typeStyle(Tokens.time).foregroundStyle(Tokens.text2.color)
            if let bottom {
                Text(bottom).typeStyle(Tokens.caption).foregroundStyle(Tokens.text3.color)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .fixedSize()
        .frame(minWidth: Self.width, alignment: .leading)
    }
}

/// A row's title in rowTitle and its line in footnote, text2 or a status colour.
struct RowLines: View {
    let title: String
    let line: String?
    let lineTone: StatusTone?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
            Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
            if let line {
                Text(line).typeStyle(Tokens.footnote).monospacedDigit()
                    .foregroundStyle((lineTone?.color ?? Tokens.text2).color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        Card {
            HistoryRow(
                day: "Wed",
                date: "7 Oct",
                title: "Class 10 Maths",
                line: "5 of 6 present",
                trailing: "1 absent"
            ) {}
                .rowDivider()
            HistoryRow(
                day: "Mon", date: "5 Oct", title: "Class 10 Maths", line: "Parent told on Mon 5 Oct", lineTone: .ok
            ) {}
        }
        Card {
            StudentPercentRow(name: "Hemanth Reddy", fraction: 1.0 / 3, percent: "33%", count: "1 of 3") {}
        }
        Card {
            AbsentStudentRow(name: "Hemanth Reddy", line: "Lakshmi Reddy · +91 93802 60871") {
                TellParentButton {}
            }
            .rowDivider()
            AbsentStudentRow(name: "Hemanth Reddy", line: "Lakshmi Reddy · +91 93802 60871") {
                ToldMark("Told Mon 5 Oct")
            }
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
