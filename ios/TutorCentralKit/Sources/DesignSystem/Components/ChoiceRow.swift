import SwiftUI

/// A choice on a sheet (components.md "Choice row on a sheet"): a leading icon tile, the title and its count line, the
/// ring or the tick when chosen.
public struct ChoiceRow: View {
    let symbol: String
    let title: String
    let line: String?
    let chosen: Bool
    let action: () -> Void

    public init(symbol: String, title: String, line: String?, chosen: Bool, action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.line = line
        self.chosen = chosen
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            IconTile(symbol: symbol)
            RowTitles(title: title, subtitle: line)
            if chosen {
                Image(systemName: "checkmark").accessibilityHidden(true)
                    .font(.system(size: Tokens.iconSmall, weight: .bold))
                    .foregroundStyle(Tokens.accentText.color)
                    .frame(width: CheckMark.size, height: CheckMark.size)
            } else {
                Circle()
                    .strokeBorder(Tokens.lineStrong.color, lineWidth: CheckMark.ring)
                    .frame(width: CheckMark.size, height: CheckMark.size)
            }
        }
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }
}

/// The last row of a choice list: `plus` in `accentText` and a field (Add a school, Add a skill); Return adds.
public struct AddFieldRow: View {
    let placeholder: String
    @Binding var text: String
    let add: () -> Void

    public init(placeholder: String, text: Binding<String>, add: @escaping () -> Void) {
        self.placeholder = placeholder
        _text = text
        self.add = add
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Button(action: add) {
                Image(systemName: "plus")
                    .font(.system(size: Tokens.iconSmall, weight: .semibold))
                    .foregroundStyle(Tokens.accentText.color)
                    .frame(width: IconTile.rowSize, height: IconTile.rowSize)
            }
            .accessibilityLabel(placeholder)
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            TextField(placeholder, text: $text, prompt: Text(placeholder).foregroundStyle(Tokens.text3.color))
                .typeStyle(Tokens.rowTitle)
                .foregroundStyle(Tokens.text.color)
                .submitLabel(.done)
                .onSubmit(add)
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .frame(minHeight: RowMetrics.minHeight)
    }
}
