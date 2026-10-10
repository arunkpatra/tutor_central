import SwiftUI

/// A row of chips in a form (components.md "Chip row in a form"): the gender chips' row with a label above and an
/// optional helper under (the parent's message language).
public struct ChipRow<Option: Hashable>: View {
    let label: String
    let options: [(option: Option, title: String)]
    @Binding var selection: Option
    let helper: String?

    public init(
        label: String,
        options: [(option: Option, title: String)],
        selection: Binding<Option>,
        helper: String? = nil
    ) {
        self.label = label
        self.options = options
        _selection = selection
        self.helper = helper
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            FlowLayout(spacing: Tokens.inline) {
                ForEach(options, id: \.option) { item in
                    FilterChip(item.title, isOn: selection == item.option) { selection = item.option }
                }
            }
            if let helper {
                FieldHelper(helper)
            }
        }
    }
}
