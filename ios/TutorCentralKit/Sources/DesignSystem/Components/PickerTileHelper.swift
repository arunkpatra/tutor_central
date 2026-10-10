import SwiftUI

/// The tile picker with a helper (components.md "Picker tile with a helper"): the Phase 3 tile, its placeholder in
/// `text3` until a value is chosen, and a `footnote` `text3` line under it.
public struct PickerField: View {
    let label: String
    let value: String?
    let placeholder: String
    let helper: String?
    let action: () -> Void

    public init(
        label: String,
        value: String?,
        placeholder: String,
        helper: String? = nil,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.value = value
        self.placeholder = placeholder
        self.helper = helper
        self.action = action
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Button(action: action) {
                PickerTileLabel(label: label, value: value, placeholder: placeholder)
            }
            .pressable()
            .accessibilityValue(value ?? placeholder)
            if let helper {
                FieldHelper(helper)
            }
        }
    }
}

/// The tile's face alone, for a `Menu` or a popover's anchor: the label and the value or its placeholder.
public struct PickerTileLabel: View {
    let label: String
    let value: String?
    let placeholder: String

    public init(label: String, value: String?, placeholder: String) {
        self.label = label
        self.value = value
        self.placeholder = placeholder
    }

    public var body: some View {
        TileRow(label: label) {
            PickerValue(value, placeholder: placeholder)
        }
        .contentShape(.rect)
    }
}

/// A form's quiet line under a field: footnote `text3`.
public struct FieldHelper: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .typeStyle(Tokens.footnote)
            .foregroundStyle(Tokens.text3.color)
            .fixedSize(horizontal: false, vertical: true)
    }
}
