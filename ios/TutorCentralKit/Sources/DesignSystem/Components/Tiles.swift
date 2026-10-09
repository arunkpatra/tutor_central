import SwiftUI

/// A tile on a sheet (`surface1`): surface2 fill, line border, no shadow, radiusControl, 46 high, padding 0 14; the
/// label on the left (body in text, or the time tiles' subhead in text2), `trailing` on the right.
public struct TileRow<Trailing: View>: View {
    let label: String
    let labelType: TypeToken
    let labelTone: ColorToken
    let trailing: Trailing

    public init(
        label: String,
        labelType: TypeToken = Tokens.body,
        labelTone: ColorToken = Tokens.text,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.label = label
        self.labelType = labelType
        self.labelTone = labelTone
        self.trailing = trailing()
    }

    public var body: some View {
        AdaptiveRow(spacing: Tokens.inline) {
            Text(label).typeStyle(labelType).foregroundStyle(labelTone.color)
            AdaptiveSpacer(minLength: Tokens.inline)
            trailing
        }
        .padding(.horizontal, Tokens.cardPaddingCompact)
        // 46 high as drawn; taller at the accessibility sizes.
        .growsWithText()
        .frame(minHeight: Well<EmptyView>.height)
        .background(Tokens.surface2.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
        )
    }
}

/// The picker tile: a tile whose value sits on the right in accentText bodyStrong with chevron.up.chevron.down. Inside
/// a `Menu` label the menu owns the tap; pass an empty action.
public struct PickerTile: View {
    let label: String
    let value: String
    let action: () -> Void

    public init(label: String, value: String, action: @escaping () -> Void) {
        self.label = label
        self.value = value
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            TileRow(label: label) {
                PickerValue(value)
            }
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityValue(value)
    }
}

/// A picker's value: accentText bodyStrong with chevron.up.chevron.down at 16.
public struct PickerValue: View {
    let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var body: some View {
        HStack(spacing: Tokens.fieldGap) {
            Text(value).typeStyle(Tokens.bodyStrong)
            Image(systemName: "chevron.up.chevron.down").accessibilityHidden(true)
                .font(.system(size: Tokens.iconInline))
        }
        .foregroundStyle(Tokens.accentText.color)
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        PickerTile(label: "Class", value: "Class 10 Maths") {}
        HStack(spacing: Tokens.tileGap) {
            TileRow(label: "Starts", labelType: Tokens.subhead, labelTone: Tokens.text2) {
                Text("18:00").typeStyle(Tokens.bodyStrong).foregroundStyle(Tokens.accentText.color)
            }
            TileRow(label: "Ends", labelType: Tokens.subhead, labelTone: Tokens.text2) {
                Text("19:30").typeStyle(Tokens.bodyStrong).foregroundStyle(Tokens.accentText.color)
            }
        }
    }
    .padding(Tokens.pageSide)
    .background(Tokens.surface1.color)
}
