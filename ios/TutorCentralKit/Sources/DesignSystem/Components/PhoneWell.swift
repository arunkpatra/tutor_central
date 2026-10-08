import SwiftUI

/// "+91" in text2 600, then the national digits in 600 monospaced, grouped as typed (98765 43210). The binding holds
/// the digits only.
public struct PhoneWell: View {
    let label: String
    @Binding var digits: String
    let optional: Bool
    let helper: String?
    let error: String?
    let showsFocus: Bool
    let onCommit: () -> Void
    @FocusState private var focused: Bool
    /// What the field shows: always the grouped digits, so letters from a hardware keyboard never appear.
    @State private var shown = ""

    public init(
        label: String,
        digits: Binding<String>,
        optional: Bool = false,
        helper: String? = nil,
        error: String? = nil,
        showsFocus: Bool = false,
        onCommit: @escaping () -> Void = {}
    ) {
        self.label = label
        _digits = digits
        self.optional = optional
        self.helper = helper
        self.error = error
        self.showsFocus = showsFocus
        self.onCommit = onCommit
    }

    public var body: some View {
        Well(label: label, optional: optional, helper: helper, error: error, focused: focused || showsFocus) {
            HStack(spacing: Tokens.inline) {
                Text("+91").typeStyle(Tokens.bodyStrong).foregroundStyle(Tokens.text2.color)
                TextField(text: $shown, prompt: Text("98765 43210").foregroundStyle(Tokens.text3.color)) {
                    Text(label)
                }
                .typeStyle(Tokens.bodyStrong)
                .foregroundStyle(Tokens.text.color)
                .tint(Tokens.accent.color)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .focused($focused)
                .onAppear { shown = Self.grouped(digits) }
                .onChange(of: shown) { _, typed in
                    let next = Self.typed(typed)
                    if next.shown != typed {
                        shown = next.shown
                    }
                    if next.digits != digits {
                        digits = next.digits
                    }
                }
                .onChange(of: digits) { _, now in
                    if Self.typed(shown).digits != now {
                        shown = Self.grouped(now)
                    }
                }
                .onChange(of: focused) { _, now in
                    if !now {
                        onCommit()
                    }
                }
            }
        }
    }

    /// "9876543210" → "98765 43210".
    public nonisolated static func grouped(_ digits: String) -> String {
        digits.count > 5 ? "\(digits.prefix(5)) \(digits.dropFirst(5))" : digits
    }

    /// What was typed or pasted, as the field shows it and as the ten national digits: only 0 to 9 count, and a
    /// pasted +91, 0091, 91 or leading 0 in front of ten digits is dropped.
    /// Nonisolated: a pure rule, called off the main actor by tests (a closure in a view's static would inherit the
    /// main actor and trap there).
    nonisolated static func typed(_ text: String) -> (shown: String, digits: String) {
        var digits = Substring(text.filter { $0.isASCII && $0.isNumber })
        if text.trimmingCharacters(in: .whitespaces).hasPrefix("+91") {
            digits = digits.dropFirst(2)
        } else if digits.hasPrefix("0091") {
            digits = digits.dropFirst(4)
        } else if digits.count > 10, digits.hasPrefix("91") {
            digits = digits.dropFirst(2)
        } else if digits.count > 10, digits.hasPrefix("0") {
            digits = digits.dropFirst()
        }
        let national = String(digits.prefix(10))
        return (grouped(national), national)
    }
}
