import SwiftUI

/// Member (class detail): avatar 40; name and the parent's phone; "Class fee" in footnote text2, or the student's own
/// fee in numberRow; chevron.
public struct MemberRow: View {
    let initials: String
    let name: String
    let phone: String
    let fee: String?
    let action: () -> Void

    /// `fee` nil: the student pays the class fee.
    public init(initials: String, name: String, phone: String, fee: String?, action: @escaping () -> Void) {
        self.initials = initials
        self.name = name
        self.phone = phone
        self.fee = fee
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            Avatar(initials: initials)
            RowTitles(title: name, subtitle: phone)
            if let fee {
                Text(fee).typeStyle(Tokens.numberRow).foregroundStyle(Tokens.text.color)
            } else {
                Text("Class fee").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            Chevron()
        }
    }
}

/// Meeting (class detail): the day in time text2 at width 46, the date in rowTitle, the time range in footnote text2.
/// Today's row sits on surface2 with its day in accentText 700.
public struct MeetingRow: View {
    let day: String
    let title: String
    let time: String?
    let isToday: Bool
    static var dayWidth: CGFloat {
        46
    }

    public init(day: String, title: String, time: String?, isToday: Bool) {
        self.day = day
        self.title = title
        self.time = time
        self.isToday = isToday
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Text(day)
                .typeStyle(isToday ? Tokens.segmentActive : Tokens.time)
                .foregroundStyle((isToday ? Tokens.accentText : Tokens.text2).color)
                .frame(width: Self.dayWidth, alignment: .leading)
            Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let time {
                Text(time).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .background(isToday ? Tokens.surface2.color : Color.clear)
        .accessibilityElement(children: .combine)
    }
}

/// Checklist (add students): avatar 40; name and its line; a checkbox 24 on the right; the whole row toggles it.
public struct ChecklistRow: View {
    let initials: String
    let name: String
    let detail: String
    @Binding var isOn: Bool

    public init(initials: String, name: String, detail: String, isOn: Binding<Bool>) {
        self.initials = initials
        self.name = name
        self.detail = detail
        _isOn = isOn
    }

    public var body: some View {
        Button {
            isOn.toggle()
            Haptic.play(.selection)
        } label: {
            HStack(spacing: Tokens.rowPaddingDense) {
                Avatar(initials: initials)
                RowTitles(title: name, subtitle: detail)
                CheckMark(isOn: isOn)
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(minHeight: RowMetrics.minHeight)
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
