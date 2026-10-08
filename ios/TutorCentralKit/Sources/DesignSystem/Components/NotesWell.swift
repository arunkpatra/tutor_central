import SwiftUI

/// Notes on a form: a well at least 96 high holding a text editor, the placeholder in text3 while empty, and the
/// counter "47 of 2,000" in caption text3 at the bottom right; an error says itself under the well.
public struct NotesWell: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let limit: Int
    let error: String?
    @FocusState private var focused: Bool
    static var minHeight: CGFloat {
        96
    }

    /// Room under the text for the counter.
    static var counterInset: CGFloat {
        28
    }

    public init(label: String, text: Binding<String>, placeholder: String, limit: Int, error: String? = nil) {
        self.label = label
        _text = text
        self.placeholder = placeholder
        self.limit = limit
        self.error = error
    }

    public var body: some View {
        Well(label: label, error: error, focused: focused, height: nil) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .typeStyle(Tokens.body)
                        .foregroundStyle(Tokens.text3.color)
                        .padding(.top, Tokens.rowPaddingDense)
                        .accessibilityHidden(true)
                }
                TextEditor(text: $text)
                    .typeStyle(Tokens.body)
                    .foregroundStyle(Tokens.text.color)
                    .tint(Tokens.accent.color)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.horizontal, 0, for: .scrollContent)
                    .focused($focused)
                    .padding(.top, Tokens.rowPaddingDense - Tokens.inline)
                    .padding(.bottom, Self.counterInset)
                    .accessibilityLabel(label)
            }
            .frame(minHeight: Self.minHeight, alignment: .topLeading)
            .overlay(alignment: .bottomTrailing) {
                Text("\(text.count.formatted()) of \(limit.formatted())")
                    .typeStyle(Tokens.caption)
                    .foregroundStyle(Tokens.text3.color)
                    .padding(.bottom, Tokens.tileGap)
            }
        }
    }
}

#Preview {
    @Previewable @State var notes = "Board exam in March. Prefers the evening batch."
    NotesWell(label: "Notes", text: $notes, placeholder: "School, board, pickup, anything to remember", limit: 2000)
        .padding(Tokens.pageSide)
        .background(Tokens.surface1.color)
}
