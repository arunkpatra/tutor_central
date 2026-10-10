import SwiftUI

/// Setting: symbol 20 text2, label body, then a value in body text2 with a chevron, or a switch (`trailing`). The
/// whole row presses when it opens something. Padding `rowPadding`, at least 56 high, one accessibility element.
public struct SettingRow<Trailing: View>: View {
    let symbol: String?
    let label: String
    let line: String?
    let action: (() -> Void)?
    let trailing: Trailing

    /// `trailing` comes before `action` so a trailing closure is the trailing view, never the action. `line` is the
    /// footnote under the label (Parent messages, P7-Settings).
    public init(
        symbol: String? = nil,
        label: String,
        line: String? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        action: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.label = label
        self.line = line
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
                Image(systemName: symbol).accessibilityHidden(true)
                    .font(.system(size: Tokens.iconButton))
                    .foregroundStyle(Tokens.text2.color)
                    .frame(width: Tokens.iconButton + Tokens.fieldGap)
            }
            AdaptiveRow {
                VStack(alignment: .leading, spacing: SettingRowMetrics.lineGap) {
                    Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                    if let line {
                        Text(line)
                            .typeStyle(Tokens.footnote)
                            .foregroundStyle(Tokens.text2.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                AdaptiveSpacer(minLength: Tokens.inline)
                trailing
            }
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

/// Setting, later (P4-More, P2-Settings): a setting row whose feature arrives with a later phase, at the Later opacity,
/// the phase named in captionStrong text3 instead of a chevron; not tappable.
public struct LaterRow: View {
    let symbol: String
    let label: String
    let phase: String

    public init(symbol: String, label: String, phase: String) {
        self.symbol = symbol
        self.label = label
        self.phase = phase
    }

    public var body: some View {
        SettingRow(symbol: symbol, label: label) {
            Text(phase).typeStyle(Tokens.captionStrong).foregroundStyle(Tokens.text3.color)
        }
        .opacity(Tokens.opacityLater)
        .accessibilityHint("Arrives in \(phase)")
    }
}

/// The gap between a setting's label and its line (P7-Settings: 2).
enum SettingRowMetrics {
    static let lineGap: CGFloat = 2
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

/// Student: avatar 40; name, then the status word in its colour (V2, P10-Students-List) and the batch (or the parent's
/// phone); the fee in numberRow and under it this month's
/// status in captionStrong in its colour (text2 when the status has no tone: Waived); chevron. No fee, nothing on the
/// right but the chevron; no status, the fee alone.
public struct StudentRow: View {
    let initials: String
    let name: String
    let nameMatch: Range<String.Index>?
    let detail: String
    let fee: String?
    let status: (tone: StatusTone?, text: String)?
    let lead: (word: String, kind: TrackKind)?
    let action: (() -> Void)?

    /// `lead` is the tracking status word that starts the second line. `nameMatch` colours the letters a search matched
    /// in accentText. `status` is nil when the month has no invoice.
    public init(
        initials: String,
        name: String,
        nameMatch: Range<String.Index>? = nil,
        detail: String,
        fee: String?,
        status: (tone: StatusTone?, text: String)? = nil,
        lead: (word: String, kind: TrackKind)? = nil,
        action: (() -> Void)? = nil
    ) {
        self.lead = lead
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
            AdaptiveRow {
                if let lead {
                    VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                        RowTitles(title: name, titleMatch: nameMatch, subtitle: nil)
                        (Text(lead.word).foregroundStyle(lead.kind.color.color).fontWeight(.semibold)
                            + Text(" · \(detail)").foregroundStyle(Tokens.text2.color))
                            .typeStyle(Tokens.footnote)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    RowTitles(title: name, titleMatch: nameMatch, subtitle: detail)
                }
                if let fee {
                    TrailingColumn {
                        Text(fee).typeStyle(Tokens.numberRow).foregroundStyle(Tokens.text.color)
                        if let status {
                            Text(status.text)
                                .typeStyle(Tokens.captionStrong)
                                .foregroundStyle((status.tone?.color ?? Tokens.text2).color)
                        }
                    }
                }
            }
            if action != nil {
                Chevron()
            }
        }
    }
}

/// Class: the icon tile; name and meeting summary; the member count in footnote text2 (none for a row that only
/// leads somewhere, such as "Not in a class"); chevron.
public struct ClassRow: View {
    let symbol: String
    let name: String
    let summary: String
    let members: Int?
    let action: (() -> Void)?

    public init(
        symbol: String = "book.closed",
        name: String,
        summary: String,
        members: Int?,
        action: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.name = name
        self.summary = summary
        self.members = members
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            IconTile(symbol: symbol)
            RowTitles(title: name, subtitle: summary)
            if let members {
                Text("\(members)").typeStyle(Tokens.footnote).monospacedDigit().foregroundStyle(Tokens.text2.color)
            }
            Chevron()
        }
    }
}

/// Attendance (Phase 4): the whole row toggles and one pill says the state, Present (ok fill, okInk) or Absent
/// (overdue fill, overdueInk), 96 × 40, radius 13, segmentActive. Selection haptic. The step 0.2 row's two toggles
/// left too little room for a name (components.md, Rows).
public struct AttendanceRow: View {
    let name: String
    let present: Bool
    let toggle: () -> Void

    public init(name: String, present: Bool, toggle: @escaping () -> Void) {
        self.name = name
        self.present = present
        self.toggle = toggle
    }

    public var body: some View {
        Button {
            toggle()
            Haptic.play(.selection)
        } label: {
            AdaptiveRow {
                Text(name).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                AttendancePill(present: present)
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(minHeight: RowMetrics.minHeight)
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityLabel(name)
        .accessibilityValue(present ? "Present" : "Absent")
        .accessibilityHint(present ? "Marks absent" : "Marks present")
        .accessibilityAddTraits(.isToggle)
    }
}

/// The attendance pill: Present (ok fill, okInk) or Absent (overdue fill, overdueInk), at least 96 × 40, radius 13,
/// segmentActive. Attendance's row and the close's student card (10.3) both wear it.
public struct AttendancePill: View {
    let present: Bool
    static var size: CGSize {
        CGSize(width: 96, height: 40)
    }

    public init(present: Bool) {
        self.present = present
    }

    public var body: some View {
        Text(present ? "Present" : "Absent")
            .typeStyle(Tokens.segmentActive)
            .foregroundStyle((present ? Tokens.okInk : Tokens.overdueInk).color)
            .lineLimit(1)
            // At least the board's 96 × 40; wider and taller with the text at the larger sizes.
            .padding(.horizontal, Tokens.rowPaddingDense)
            .frame(minWidth: Self.size.width, minHeight: Self.size.height)
            .background(
                (present ? Tokens.ok : Tokens.overdue).color,
                in: .rect(cornerRadius: Tokens.radiusSegmentTrack, style: .continuous)
            )
    }
}
