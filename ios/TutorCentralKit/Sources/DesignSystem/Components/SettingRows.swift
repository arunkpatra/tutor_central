import SwiftUI

/// A setting's value on the right of its row: subhead in text2, or a status colour ("Connected" in ok).
public struct RowValue: View {
    let text: String
    let tone: ColorToken

    public init(_ text: String, tone: ColorToken = Tokens.text2) {
        self.text = text
        self.tone = tone
    }

    public var body: some View {
        Text(text).typeStyle(Tokens.subhead).foregroundStyle(tone.color).lineLimit(1).monospacedDigit()
    }
}

/// The Segmented row (Appearance, P7-Settings): the Setting row's symbol and label over a segmented control in the
/// same row; padding 14 16, 12 between.
public struct SegmentedRow<Option: Hashable>: View {
    let symbol: String
    let label: String
    let options: [(Option, String)]
    @Binding var selection: Option

    public init(symbol: String, label: String, options: [(Option, String)], selection: Binding<Option>) {
        self.symbol = symbol
        self.label = label
        self.options = options
        _selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingDense) {
            HStack(spacing: Tokens.rowPaddingDense) {
                RowSymbol(symbol)
                Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
            }
            Segmented(options: options, selection: $selection)
        }
        .padding(.vertical, Tokens.rowPaddingVertical)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
    }
}

/// A sign-in method on Account (P7-Account): the provider's symbol, its name and its value ("Connected" in ok, "On",
/// "Not set" or "Set" with a chevron when it opens the password sheet).
public struct MethodRow: View {
    let symbol: String
    let label: String
    let value: String
    let tone: ColorToken
    let action: (() -> Void)?

    public init(
        symbol: String,
        label: String,
        value: String,
        tone: ColorToken = Tokens.text2,
        action: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.label = label
        self.value = value
        self.tone = tone
        self.action = action
    }

    public var body: some View {
        SettingRow(symbol: symbol, label: label, trailing: { RowValue(value, tone: tone) }, action: action)
    }
}

/// A destructive row of a list card (Sign out, Delete account permanently): the symbol and the words in overdue 600,
/// a chevron when it opens a screen.
public struct DestructiveRow: View {
    let symbol: String
    let label: String
    let chevron: Bool
    let action: () -> Void

    public init(symbol: String, label: String, chevron: Bool = false, action: @escaping () -> Void) {
        self.symbol = symbol
        self.label = label
        self.chevron = chevron
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.rowPaddingDense) {
                Image(systemName: symbol).font(.system(size: Tokens.iconButton)).accessibilityHidden(true)
                Text(label).typeStyle(Tokens.bodyStrong)
                Spacer(minLength: Tokens.inline)
                if chevron {
                    Chevron()
                }
            }
            .foregroundStyle(Tokens.overdue.color)
            .padding(.vertical, Tokens.rowPaddingVertical)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(minHeight: RowMetrics.minHeight)
            .contentShape(.rect)
        }
        .pressable()
    }
}

/// Account's hero (P7-Account): the avatar 56 beside the name and the email, 14 apart.
public struct AccountHero: View {
    let initials: String
    let name: String
    let email: String
    static var avatarSize: CGFloat {
        56
    }

    public init(initials: String, name: String, email: String) {
        self.initials = initials
        self.name = name
        self.email = email
    }

    public var body: some View {
        HStack(spacing: Tokens.cardPaddingCompact) {
            Avatar(initials: initials, size: Self.avatarSize)
            VStack(alignment: .leading, spacing: SettingRowMetrics.lineGap) {
                Text(name).typeStyle(Tokens.emptyTitle).foregroundStyle(Tokens.text.color)
                Text(email).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A row's leading symbol: 20 in text2, in a column as wide as the Setting row's.
struct RowSymbol: View {
    let symbol: String

    init(_ symbol: String) {
        self.symbol = symbol
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: Tokens.iconButton))
            .foregroundStyle(Tokens.text2.color)
            .frame(width: Tokens.iconButton + Tokens.fieldGap)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        AccountHero(initials: "MN", name: "Meera Nair", email: "meera.nair@gmail.com")
        Card {
            VStack(spacing: 0) {
                MethodRow(symbol: "apple.logo", label: "Apple", value: "Connected", tone: Tokens.ok).rowDivider()
                MethodRow(symbol: "envelope", label: "Email code", value: "On").rowDivider()
                MethodRow(symbol: "key", label: "Password", value: "Not set") {}
            }
        }
        Card {
            VStack(spacing: 0) {
                SettingRow(
                    symbol: "message", label: "Parent messages",
                    line: "Reminders, receipts, alerts and notes open WhatsApp with the message ready.",
                    trailing: { RowValue("WhatsApp") }
                )
                .rowDivider()
                SegmentedRow(
                    symbol: "moon", label: "Appearance",
                    options: AppearanceChoice.allCases.map { ($0, $0.label) }, selection: .constant(.dark)
                )
            }
        }
        Card { DestructiveRow(symbol: "trash", label: "Delete account permanently", chevron: true) {} }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
