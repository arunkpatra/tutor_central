import SwiftUI

/// A wheel in a popover (P7-Reminders-DayPicker): the menu's glass 200 wide, an eyebrow, five visible rows 36 high;
/// the chosen one on surface2 in 700, the others text3. Scrolling or tapping a row chooses it, with the selection
/// haptic.
public struct WheelPopover<Value: Hashable>: View {
    let eyebrow: String
    let values: [Value]
    let label: (Value) -> String
    @Binding var selection: Value
    @State private var position: Value?
    static var width: CGFloat {
        200
    }

    static var rowHeight: CGFloat {
        36
    }

    static var visibleRows: CGFloat {
        5
    }

    public init(eyebrow: String, values: [Value], selection: Binding<Value>, label: @escaping (Value) -> String) {
        self.eyebrow = eyebrow
        self.values = values
        self.label = label
        _selection = selection
        _position = State(initialValue: selection.wrappedValue)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.inline) {
            Eyebrow(eyebrow)
            ScrollViewReader { reader in
                wheel(reader)
            }
        }
        .padding(.vertical, Tokens.tileGap)
        .padding(.horizontal, Tokens.rowPaddingDense)
        .frame(width: Self.width)
        .presentationCompactAdaptation(.popover)
    }

    /// Opens on the chosen row, centred (`scrollPosition` alone does not move before the first layout).
    private func wheel(_ reader: ScrollViewProxy) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(values, id: \.self) { value in
                    let chosen = value == position
                    Text(label(value))
                        .typeStyle(chosen ? Tokens.bodyStrong : Tokens.body)
                        .foregroundStyle((chosen ? Tokens.text : Tokens.text3).color)
                        .frame(maxWidth: .infinity, minHeight: Self.rowHeight)
                        .contentShape(.rect)
                        .onTapGesture { withAnimation { position = value } }
                        .accessibilityAddTraits(chosen ? .isSelected : [])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $position, anchor: .center)
        .contentMargins(.vertical, Self.rowHeight * 2, for: .scrollContent)
        .frame(height: Self.rowHeight * Self.visibleRows)
        .background {
            RoundedRectangle(cornerRadius: Tokens.radiusChip, style: .continuous)
                .fill(Tokens.surface2.color)
                .frame(height: Self.rowHeight)
        }
        .onChange(of: position) { _, value in
            guard let value, value != selection else { return }
            selection = value
            Haptic.play(.selection)
        }
        .onAppear { reader.scrollTo(selection, anchor: .center) }
    }
}

/// A picker as a row of a list card (Teacher reminders' "How long before", "Day of the month"): the label in body,
/// the value in accentText 600 with `chevron.up.chevron.down`; it opens a wheel in a popover.
public struct PickerListRow: View {
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
            AdaptiveRow {
                Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
                AdaptiveSpacer(minLength: Tokens.inline)
                PickerValue(value)
            }
            .padding(.vertical, Tokens.rowPaddingVertical)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .frame(minHeight: RowMetrics.minHeight)
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens a picker")
    }
}

#Preview {
    WheelPopover(eyebrow: "Day of the month", values: Array(1 ... 28), selection: .constant(5)) { "\($0)th" }
        .background(Tokens.surface1.color)
}
