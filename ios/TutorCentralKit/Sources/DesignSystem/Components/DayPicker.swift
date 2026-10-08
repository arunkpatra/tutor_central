import SwiftUI

/// Seven round toggles 40 spread across the content width. Off: surface2, lineStrong border, text2 600. On: accent
/// fill, textOnAccent 700. The caller passes the days: DesignSystem does not know Domain. Selection haptic.
public struct DayPicker: View {
    public struct Item: Identifiable, Hashable, Sendable {
        public let id: Int
        public let initial: String
        public let name: String

        public init(id: Int, initial: String, name: String) {
            self.id = id
            self.initial = initial
            self.name = name
        }
    }

    let items: [Item]
    @Binding var selection: Set<Int>
    static var size: CGFloat {
        40
    }

    public init(items: [Item], selection: Binding<Set<Int>>) {
        self.items = items
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Spacer(minLength: 0)
                }
                toggle(item)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func toggle(_ item: Item) -> some View {
        let on = selection.contains(item.id)
        return Button {
            if on {
                selection.remove(item.id)
            } else {
                selection.insert(item.id)
            }
            Haptic.play(.selection)
        } label: {
            Text(item.initial)
                .typeStyle(on ? Tokens.segmentActive : Tokens.segment)
                .foregroundStyle((on ? Tokens.textOnAccent : Tokens.text2).color)
                .frame(width: Self.size, height: Self.size)
                .background((on ? Tokens.accent : Tokens.surface2).color, in: .circle)
                .overlay {
                    if !on {
                        Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline)
                    }
                }
                .contentShape(.circle)
        }
        .pressable()
        .accessibilityLabel(item.name)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var days: Set = [2, 4, 6]
    let names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    DayPicker(
        items: names.enumerated().map { .init(id: $0 + 1, initial: String($1.prefix(1)), name: $1) },
        selection: $days
    )
    .padding(Tokens.pageSide)
    .background(Tokens.surface1.color)
}
