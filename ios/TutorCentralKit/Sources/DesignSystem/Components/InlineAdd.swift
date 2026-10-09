import SwiftUI

/// Inline add (tasks): a well 46 with `plus` in text3 and the placeholder; focused it takes the focus ring and shows a
/// row of chips (the due date as a filter chip with `calendar`, "No date" neutral) and a quiet Add (700) on the right
/// (components.md, Inline add). At the top of the Tasks screen and, on Today, the first row of the Tasks card.
public struct InlineAdd: View {
    /// One due-date choice under the field.
    public struct DueChip {
        let label: String
        let symbol: String?
        let isOn: Bool
        let pick: () -> Void

        public init(_ label: String, symbol: String? = nil, isOn: Bool, pick: @escaping () -> Void) {
            self.label = label
            self.symbol = symbol
            self.isOn = isOn
            self.pick = pick
        }
    }

    @Binding var text: String
    let placeholder: String
    let showsFocus: Bool
    let autofocus: Bool
    let dueChips: [DueChip]
    let canAdd: Bool
    let add: () -> Void
    @FocusState private var focused: Bool
    static var chipSymbol: CGFloat {
        14
    }

    /// `showsFocus` draws the focused state without the keyboard (boards, screenshots); `autofocus` raises the keyboard
    /// once the field has arrived.
    public init(
        text: Binding<String>, placeholder: String, showsFocus: Bool = false, autofocus: Bool = false,
        dueChips: [DueChip], canAdd: Bool, add: @escaping () -> Void
    ) {
        _text = text
        self.placeholder = placeholder
        self.showsFocus = showsFocus
        self.autofocus = autofocus
        self.dueChips = dueChips
        self.canAdd = canAdd
        self.add = add
    }

    private var isFocused: Bool {
        focused || showsFocus
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.tileGap) {
            field
            if isFocused {
                HStack(spacing: Tokens.inline) {
                    ForEach(dueChips.indices, id: \.self) { index in
                        chip(dueChips[index])
                    }
                    Spacer(minLength: Tokens.inline)
                    Button("Add") { commit() }
                        .buttonStyle(.quiet(emphasised: true))
                        .disabled(!canAdd)
                }
            }
        }
    }

    private var field: some View {
        HStack(spacing: Tokens.inline) {
            if text.isEmpty {
                Image(systemName: "plus")
                    .font(.system(size: Tokens.iconSmall))
                    .foregroundStyle(Tokens.text3.color)
                    .accessibilityHidden(true)
            }
            TextField(text: $text, prompt: Text(placeholder).foregroundStyle(Tokens.text3.color)) {
                Text(placeholder)
            }
            .typeStyle(Tokens.body)
            .foregroundStyle(Tokens.text.color)
            .tint(Tokens.accent.color)
            .textInputAutocapitalization(.sentences)
            .submitLabel(.done)
            .focused($focused)
            .onSubmit(commit)
            .task {
                if autofocus {
                    focused = await Self.settled()
                }
            }
        }
        .frame(height: Well<EmptyView>.height)
        .padding(.horizontal, Tokens.cardPaddingCompact)
        .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                .strokeBorder((isFocused ? Tokens.accent : Tokens.line).color, lineWidth: Tokens.hairline)
        )
        .shadowed(isFocused ? [Tokens.shadowWell, Tokens.haloFocus] : [Tokens.shadowWell], radius: Tokens.radiusControl)
    }

    private func chip(_ due: DueChip) -> some View {
        Button {
            due.pick()
            Haptic.play(.selection)
        } label: {
            HStack(spacing: Tokens.fieldGap) {
                if let symbol = due.symbol {
                    Image(systemName: symbol).accessibilityHidden(true).font(.system(size: Self.chipSymbol))
                }
                Text(due.label)
            }
            .typeStyle(due.isOn ? Tokens.chipLabel : Tokens.chipNeutralLabel)
            .foregroundStyle((due.isOn ? Tokens.accentText : Tokens.text2).color)
            .padding(.horizontal, FilterChip.padding)
            .frame(height: Chip.height)
            .background((due.isOn ? Tokens.accentTint : Tokens.surface2).color, in: .capsule)
            .contentShape(.capsule)
        }
        .pressable()
        .accessibilityAddTraits(due.isOn ? .isSelected : [])
    }

    private func commit() {
        guard canAdd else { return }
        add()
    }
}

#Preview {
    @Previewable @State var text = "Print worksheets for Class 8"
    VStack(spacing: Tokens.sectionGap) {
        InlineAdd(text: .constant(""), placeholder: "Add a task", dueChips: [], canAdd: false) {}
        InlineAdd(
            text: $text, placeholder: "Add a task", showsFocus: true,
            dueChips: [.init("Fri 9 Oct", symbol: "calendar", isOn: true) {}, .init("No date", isOn: false) {}],
            canAdd: true
        ) {}
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
