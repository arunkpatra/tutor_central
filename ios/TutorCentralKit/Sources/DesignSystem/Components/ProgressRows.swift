import SwiftUI

/// The Progress row (components.md 10.7): avatar 40, the name, the line led by the status word, the percentage in
/// `numberRow` on the right, a chevron; the row opens the student.
public struct StudentProgressRow: View {
    let initials: String
    let name: String
    let status: TrackKind
    let statusWord: String
    let line: String
    let percent: String
    let action: () -> Void

    public init(
        initials: String, name: String, status: TrackKind, statusWord: String, line: String, percent: String,
        action: @escaping () -> Void
    ) {
        self.initials = initials
        self.name = name
        self.status = status
        self.statusWord = statusWord
        self.line = line
        self.percent = percent
        self.action = action
    }

    static func spoken(name: String, status: String, line: String, percent: String) -> String {
        [name, status, line, percent].joined(separator: ", ")
    }

    public var body: some View {
        ListRow(action: action) {
            Avatar(initials: initials)
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                (Text(statusWord).foregroundStyle(status.color.color).fontWeight(.semibold)
                    + Text(" · \(line)").foregroundStyle(Tokens.text2.color))
                    .typeStyle(Tokens.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(percent).typeStyle(Tokens.numberRow).foregroundStyle(Tokens.text.color)
            Image(systemName: "chevron.right").accessibilityHidden(true)
                .font(.system(size: Tokens.iconInline, weight: .semibold))
                .foregroundStyle(Tokens.text3.color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.spoken(name: name, status: statusWord, line: line, percent: percent))
    }
}

/// The Progress hero (components.md 10.7): the Kit's hero card with three columns, a `numberTile` value in `ok`, `text`
/// and `overdue` over a `footnote` `text2` label.
public struct ProgressHeroCard: View {
    struct Column: Hashable {
        let value: String
        let label: String
        let tone: ColorToken
    }

    let columns: [Column]

    public init(skillsSecure: Int, rightText: String, notOnTrack: Int, notOnTrackLabel: String) {
        columns = Self.columns(
            skillsSecure: skillsSecure, rightText: rightText, notOnTrack: notOnTrack, label: notOnTrackLabel
        )
    }

    static func columns(skillsSecure: Int, rightText: String, notOnTrack: Int, label: String) -> [Column] {
        [
            Column(value: "\(skillsSecure)", label: "skills made secure", tone: Tokens.ok),
            Column(value: rightText, label: "checks right", tone: Tokens.text),
            Column(value: "\(notOnTrack)", label: label, tone: Tokens.overdue),
        ]
    }

    public var body: some View {
        Card(.hero) {
            HStack(alignment: .top, spacing: Tokens.rowPaddingDense) {
                ForEach(columns, id: \.self) { column in
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        Text(column.value).typeStyle(Tokens.numberTile).foregroundStyle(column.tone.color)
                        Text(column.label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
