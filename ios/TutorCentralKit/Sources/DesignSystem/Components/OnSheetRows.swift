import SwiftUI

/// A row of a list on a sheet (P5-Generate): the label 15 600 (700 when strong) on the left, a `numberRow` value on the
/// right, padding 12 16. The caller wraps the rows in `Card(.onSheet)` with `rowDivider()` between them.
public struct OnSheetRow: View {
    let label: String
    let value: String
    let strong: Bool

    public init(label: String, value: String, strong: Bool = false) {
        self.label = label
        self.value = value
        self.strong = strong
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Text(label)
                .typeStyle(strong ? Tokens.buttonStrong : Tokens.buttonSecondary)
                .foregroundStyle(Tokens.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value).typeStyle(Tokens.numberRow).monospacedDigit().foregroundStyle(Tokens.text.color)
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .accessibilityElement(children: .combine)
    }
}

/// A selectable card on a sheet (P5-Reports-Export): surface2, radius 18, padding 12 16; selected, the `accent` border
/// with `haloFocus` and a tick in `accentText`; otherwise a `line` border and the checkbox's empty ring.
public struct ChoiceCard: View {
    let title: String
    let line: String
    let selected: Bool
    let action: () -> Void

    public init(title: String, line: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.line = line
        self.selected = selected
        self.action = action
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.radiusCard, style: .continuous)
        Button(action: action) {
            HStack(spacing: Tokens.rowPaddingDense) {
                RowTitles(title: title, subtitle: line)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: Tokens.iconSmall, weight: .bold))
                        .foregroundStyle(Tokens.accentText.color)
                        .frame(width: CheckMark.size, height: CheckMark.size)
                } else {
                    Circle()
                        .strokeBorder(Tokens.lineStrong.color, lineWidth: CheckMark.ring)
                        .frame(width: CheckMark.size, height: CheckMark.size)
                }
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .background(Tokens.surface2.color, in: shape)
            .overlay(shape.strokeBorder((selected ? Tokens.accent : Tokens.line).color, lineWidth: Tokens.hairline))
            .shadowed(selected ? [Tokens.haloFocus] : [], radius: Tokens.radiusCard)
            .contentShape(shape)
        }
        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    VStack(spacing: Tokens.tileGap) {
        Card(.onSheet) {
            VStack(spacing: 0) {
                OnSheetRow(label: "Class 10 Maths · 6 students", value: "₹7,500").rowDivider()
                OnSheetRow(label: "No class · 1 student", value: "₹800").rowDivider()
                OnSheetRow(label: "Total", value: "₹11,300", strong: true)
            }
        }
        ChoiceCard(title: "Fees", line: "fees-2026-10.csv · Student, class, amount", selected: true) {}
        ChoiceCard(title: "Attendance", line: "attendance-2026-10.csv · Student, class", selected: false) {}
    }
    .padding(Tokens.pageSide)
    .background(Tokens.surface1.color)
}
