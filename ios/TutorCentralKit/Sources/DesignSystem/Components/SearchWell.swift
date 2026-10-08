import SwiftUI

/// The system search field as the boards draw it: a well 44 high, magnifyingglass 18 text3, the placeholder in text3,
/// the clear mark when there is text, and a quiet Cancel to the right while searching. `isSearching` turns on with
/// focus or typed text; the owner reads it to fold the large title.
public struct SearchWell: View {
    @Binding var text: String
    let placeholder: String
    @Binding var isSearching: Bool
    let showsFocus: Bool
    @FocusState private var focused: Bool
    static var height: CGFloat {
        44
    }

    public init(text: Binding<String>, placeholder: String, isSearching: Binding<Bool>, showsFocus: Bool = false) {
        _text = text
        self.placeholder = placeholder
        _isSearching = isSearching
        self.showsFocus = showsFocus
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            well
            if isSearching {
                Button("Cancel") {
                    text = ""
                    focused = false
                    isSearching = false
                }
                .buttonStyle(.quiet)
            }
        }
        .onChange(of: focused) { _, now in
            if now {
                isSearching = true
            }
        }
        .onChange(of: text) { _, now in
            if !now.isEmpty {
                isSearching = true
            }
        }
    }

    private var well: some View {
        let ringed = focused || showsFocus
        return HStack(spacing: Tokens.inline) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: Tokens.iconSmall))
                .foregroundStyle(Tokens.text3.color)
                .accessibilityHidden(true)
            TextField(text: $text, prompt: Text(placeholder).foregroundStyle(Tokens.text3.color)) {
                Text("Search students")
            }
            .typeStyle(Tokens.body)
            .foregroundStyle(Tokens.text.color)
            .tint(Tokens.accent.color)
            .submitLabel(.search)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focused)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: Tokens.iconInline))
                        .foregroundStyle(Tokens.text3.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, Tokens.cardPaddingCompact)
        .frame(height: Self.height)
        .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                .strokeBorder((ringed ? Tokens.accent : Tokens.line).color, lineWidth: Tokens.hairline)
        )
        .shadowed(ringed ? [Tokens.shadowWell, Tokens.haloFocus] : [Tokens.shadowWell], radius: Tokens.radiusControl)
    }
}

#Preview {
    @Previewable @State var text = "sh"
    @Previewable @State var searching = true
    VStack(spacing: Tokens.sectionGap) {
        SearchWell(text: .constant(""), placeholder: "Search by name or phone", isSearching: .constant(false))
        SearchWell(text: $text, placeholder: "Search by name or phone", isSearching: $searching, showsFocus: true)
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
