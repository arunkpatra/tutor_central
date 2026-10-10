import SwiftUI

/// The close's checklist of a group's plan lines (components.md "Line checklist"): the count beside the title.
public enum LineChecklist {
    /// "2 of 5".
    public static func count(done: Int, total: Int) -> String {
        "\(done) of \(total)"
    }
}

/// One line of the checklist: the 24 pt checkbox (`ok` fill with the tick when done; `lineStrong` ring when not) and
/// the line's text `subhead`, `text2` once done. Selection haptic.
public struct PlanChecklistRow: View {
    @Binding var isOn: Bool
    let text: String

    public init(isOn: Binding<Bool>, text: String) {
        _isOn = isOn
        self.text = text
    }

    public var body: some View {
        Button {
            isOn.toggle()
            Haptic.play(.selection)
        } label: {
            HStack(spacing: Tokens.tileGap) {
                CheckMark(isOn: isOn)
                Text(text)
                    .typeStyle(Tokens.subhead)
                    .foregroundStyle((isOn ? Tokens.text2 : Tokens.text).color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
