import SwiftUI

/// Setting: symbol 20 text2, label body, then a value in body text2 with a chevron, or a switch (`trailing`). The
/// whole row presses when it opens something. Padding `rowPadding`, at least 56 high, one accessibility element.
public struct SettingRow<Trailing: View>: View {
    let symbol: String?
    let label: String
    let action: (() -> Void)?
    let trailing: Trailing

    /// `trailing` comes before `action` so a trailing closure is the trailing view, never the action.
    public init(
        symbol: String? = nil,
        label: String,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        action: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.label = label
        self.action = action
        self.trailing = trailing()
    }

    public var body: some View {
        if let action {
            Button(action: action) { content }.pressable().accessibilityElement(children: .combine)
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    private var content: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: Tokens.iconButton))
                    .foregroundStyle(Tokens.text2.color)
                    .frame(width: Tokens.iconButton + Tokens.fieldGap)
            }
            Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
            Spacer(minLength: Tokens.inline)
            trailing
            if action != nil {
                Chevron()
            }
        }
        .padding(.vertical, Tokens.rowPaddingVertical)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(minHeight: RowMetrics.minHeight)
        .contentShape(.rect)
    }
}

/// A row is at least 56 high (components.md, Rows).
enum RowMetrics {
    static let minHeight: CGFloat = 56
}

/// `chevron.right` in text3, for a row that opens something.
public struct Chevron: View {
    public init() {}

    public var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: Tokens.iconInline, weight: .semibold))
            .foregroundStyle(Tokens.text3.color)
            .accessibilityHidden(true)
    }
}

/// The frame of a list row of people or classes: padding 12 × 16, 12 between columns, at least 56 high; pressed whole
/// when it opens something.
struct ListRow<Content: View>: View {
    let action: (() -> Void)?
    @ViewBuilder let content: Content

    var body: some View {
        let row = HStack(spacing: Tokens.rowPaddingDense) { content }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(minHeight: RowMetrics.minHeight)
            .contentShape(.rect)
        if let action {
            Button(action: action) { row }.pressable().accessibilityElement(children: .combine)
        } else {
            row.accessibilityElement(children: .combine)
        }
    }
}

/// The two lines in the middle of a row: title rowTitle, subtitle footnote text2. `titleMatch` colours the letters a
/// search matched in accentText.
struct RowTitles: View {
    let title: String
    var titleMatch: Range<String.Index>?
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
            Text(attributedTitle).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
            if let subtitle {
                Text(subtitle).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attributedTitle: AttributedString {
        var text = AttributedString(title)
        if let titleMatch,
           let lower = AttributedString.Index(titleMatch.lowerBound, within: text),
           let upper = AttributedString.Index(titleMatch.upperBound, within: text) {
            text[lower ..< upper].foregroundColor = Tokens.accentText.color
        }
        return text
    }
}

/// Student: avatar 40; name, then the class (or the parent's phone); the fee in numberRow and under it this month's
/// status in captionStrong in its colour (text2 when the status has no tone: Waived); chevron. No fee, nothing on the
/// right but the chevron; no status, the fee alone.
public struct StudentRow: View {
    let initials: String
    let name: String
    let nameMatch: Range<String.Index>?
    let detail: String
    let fee: String?
    let status: (tone: StatusTone?, text: String)?
    let action: (() -> Void)?

    /// `nameMatch` colours the letters a search matched in accentText. `status` is nil when the month has no invoice.
    public init(
        initials: String,
        name: String,
        nameMatch: Range<String.Index>? = nil,
        detail: String,
        fee: String?,
        status: (tone: StatusTone?, text: String)? = nil,
        action: (() -> Void)? = nil
    ) {
        self.initials = initials
        self.name = name
        self.nameMatch = nameMatch
        self.detail = detail
        self.fee = fee
        self.status = status
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            Avatar(initials: initials)
            RowTitles(title: name, titleMatch: nameMatch, subtitle: detail)
            if let fee {
                VStack(alignment: .trailing, spacing: Tokens.rowGapInner) {
                    Text(fee).typeStyle(Tokens.numberRow).foregroundStyle(Tokens.text.color)
                    if let status {
                        Text(status.text)
                            .typeStyle(Tokens.captionStrong)
                            .foregroundStyle((status.tone?.color ?? Tokens.text2).color)
                    }
                }
            }
            if action != nil {
                Chevron()
            }
        }
    }
}

/// Class: the icon tile; name and meeting summary; the member count in footnote text2; chevron.
public struct ClassRow: View {
    let name: String
    let summary: String
    let members: Int
    let action: (() -> Void)?

    public init(name: String, summary: String, members: Int, action: (() -> Void)? = nil) {
        self.name = name
        self.summary = summary
        self.members = members
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            IconTile(symbol: "book.closed")
            RowTitles(title: name, subtitle: summary)
            Text("\(members)").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            Chevron()
        }
    }
}

/// Fee: name and phone; the amount and a compact status chip; on a due row a second line of two buttons, Remind
/// (secondary, bell) and Mark paid (primary, checkmark.circle), 10 apart.
public struct FeeRow: View {
    let name: String
    let phone: String
    let amount: String
    let status: (StatusTone, String)
    let onRemind: (() -> Void)?
    let onMarkPaid: (() -> Void)?

    public init(
        name: String,
        phone: String,
        amount: String,
        status: (StatusTone, String),
        onRemind: (() -> Void)? = nil,
        onMarkPaid: (() -> Void)? = nil
    ) {
        self.name = name
        self.phone = phone
        self.amount = amount
        self.status = status
        self.onRemind = onRemind
        self.onMarkPaid = onMarkPaid
    }

    public var body: some View {
        VStack(spacing: Tokens.tileGap) {
            HStack(alignment: .top, spacing: Tokens.rowPaddingDense) {
                RowTitles(title: name, subtitle: phone)
                VStack(alignment: .trailing, spacing: Tokens.rowGapInner * 2) {
                    Text(amount).typeStyle(Tokens.numberRow).foregroundStyle(Tokens.text.color)
                    Chip(.status(status.0, status.1), compact: true)
                }
            }
            .accessibilityElement(children: .combine)
            if let onRemind, let onMarkPaid {
                HStack(spacing: Tokens.tileGap) {
                    Button(action: onRemind) { Label("Remind", systemImage: "bell") }.buttonStyle(.secondary(.row))
                    Button(action: onMarkPaid) { Label("Mark paid", systemImage: "checkmark.circle") }
                        .buttonStyle(.primary(.row))
                }
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
    }
}

/// Attendance: the name; two toggles 96 × 40, radius 13, 8 apart: Present (ok fill, okInk 700 when on) and Absent
/// (overdue fill, overdueInk 700 when on); off is a lineStrong outline in text2 600. Selection haptic.
public struct AttendanceRow: View {
    let name: String
    @Binding var present: Bool?
    static var toggleSize: CGSize {
        CGSize(width: 96, height: 40)
    }

    public init(name: String, present: Binding<Bool?>) {
        self.name = name
        _present = present
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Text(name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: Tokens.inline) {
                toggle("Present", on: present == true, tone: .ok) { present = true }
                toggle("Absent", on: present == false, tone: .overdue) { present = false }
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(minHeight: RowMetrics.minHeight)
    }

    private func toggle(_ title: String, on: Bool, tone: StatusTone, set: @escaping () -> Void) -> some View {
        Button {
            set()
            Haptic.play(.selection)
        } label: {
            Text(title)
                .typeStyle(on ? Tokens.segmentActive : Tokens.segment)
                .foregroundStyle((on ? tone.ink : Tokens.text2).color)
                .frame(width: Self.toggleSize.width, height: Self.toggleSize.height)
                .background(
                    on ? tone.color.color : Color.clear,
                    in: .rect(cornerRadius: Tokens.radiusSegmentTrack, style: .continuous)
                )
                .overlay {
                    if !on {
                        RoundedRectangle(cornerRadius: Tokens.radiusSegmentTrack, style: .continuous)
                            .strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline)
                    }
                }
        }
        .pressable()
        .accessibilityLabel("\(name) \(title.lowercased())")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
