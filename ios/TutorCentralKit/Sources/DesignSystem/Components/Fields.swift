import SwiftUI

/// A form field: label footnote text2 above (fieldGap), "(optional)" in text3 beside it; the well 46 high, well fill,
/// line border, shadowWell (dark), radiusControl, padding 0 14; focus: accent border and haloFocus; error: overdue
/// border and a footnote overdue line with its symbol under the well, never colour alone; helper: footnote text3.
public struct Well<Content: View>: View {
    let label: String
    let optional: Bool
    let helper: String?
    let error: String?
    let focused: Bool
    let height: CGFloat?
    let content: Content
    public static var height: CGFloat {
        46
    }

    @Environment(\.isEnabled) private var isEnabled

    public init(
        label: String,
        optional: Bool = false,
        helper: String? = nil,
        error: String? = nil,
        focused: Bool,
        height: CGFloat? = Self.height,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.optional = optional
        self.helper = helper
        self.error = error
        self.focused = focused
        self.height = height
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            HStack(spacing: Tokens.rowGapInner * 2) {
                Text(label).foregroundStyle(Tokens.text2.color)
                if optional {
                    Text("(optional)").foregroundStyle(Tokens.text3.color)
                }
            }
            .typeStyle(Tokens.footnote)
            content
                .frame(height: height)
                .padding(.horizontal, Tokens.cardPaddingCompact)
                .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                        .strokeBorder(borderColor.color, lineWidth: Tokens.hairline)
                )
                .shadowed(
                    focused && error == nil ? [Tokens.shadowWell, Tokens.haloFocus] : [Tokens.shadowWell],
                    radius: Tokens.radiusControl
                )
            if let error {
                FieldMessage(error)
            } else if let helper {
                Text(helper).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
            }
        }
        .opacity(isEnabled ? 1 : Tokens.opacityDisabled)
    }

    private var borderColor: ColorToken {
        if error != nil {
            return Tokens.overdue
        }
        return focused ? Tokens.accent : Tokens.line
    }
}

/// An error said in words under a field: the symbol and the line in overdue, footnote.
public struct FieldMessage: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Tokens.fieldGap) {
            Image(systemName: "exclamationmark.circle").font(.system(size: Tokens.iconInline))
            Text(text)
        }
        .typeStyle(Tokens.footnote)
        .foregroundStyle(Tokens.overdue.color)
        .accessibilityElement(children: .combine)
    }
}

/// A text field in a well. `keyboard`, `content` and `capitalisation` set the keyboard and the autofill kind; a prefix
/// (₹) in text2 and a suffix (per month) in footnote text3 sit beside the value; `numeric` sets the value in 600
/// monospaced digits.
public struct TextWell: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let optional: Bool
    let helper: String?
    let error: String?
    let prefix: String?
    let suffix: String?
    let numeric: Bool
    let keyboard: UIKeyboardType
    let content: UITextContentType?
    let capitalisation: TextInputAutocapitalization
    let showsFocus: Bool
    let autofocus: Bool
    let onCommit: () -> Void
    @FocusState private var focused: Bool

    /// `showsFocus` draws the focus ring without the keyboard (boards, screenshots); `autofocus` raises the keyboard
    /// once the field has arrived.
    public init(
        label: String,
        text: Binding<String>,
        placeholder: String = "",
        optional: Bool = false,
        helper: String? = nil,
        error: String? = nil,
        prefix: String? = nil,
        suffix: String? = nil,
        numeric: Bool = false,
        keyboard: UIKeyboardType = .default,
        content: UITextContentType? = nil,
        capitalisation: TextInputAutocapitalization = .words,
        showsFocus: Bool = false,
        autofocus: Bool = false,
        onCommit: @escaping () -> Void = {}
    ) {
        self.label = label
        _text = text
        self.placeholder = placeholder
        self.optional = optional
        self.helper = helper
        self.error = error
        self.prefix = prefix
        self.suffix = suffix
        self.numeric = numeric
        self.keyboard = keyboard
        self.content = content
        self.capitalisation = capitalisation
        self.showsFocus = showsFocus
        self.autofocus = autofocus
        self.onCommit = onCommit
    }

    public var body: some View {
        Well(label: label, optional: optional, helper: helper, error: error, focused: focused || showsFocus) {
            HStack(spacing: Tokens.inline) {
                if let prefix {
                    Text(prefix).typeStyle(Tokens.body).foregroundStyle(Tokens.text2.color)
                }
                TextField(text: $text, prompt: Text(placeholder).foregroundStyle(Tokens.text3.color)) {
                    Text(label)
                }
                .typeStyle(numeric ? Tokens.bodyStrong : Tokens.body)
                .foregroundStyle(Tokens.text.color)
                .tint(Tokens.accent.color)
                .keyboardType(keyboard)
                .textContentType(content)
                .textInputAutocapitalization(capitalisation)
                .autocorrectionDisabled(content != nil)
                .focused($focused)
                .onSubmit(onCommit)
                .task {
                    if autofocus {
                        focused = await Self.settled()
                    }
                }
                .onChange(of: focused) { _, now in
                    if !now {
                        onCommit()
                    }
                }
                if let suffix {
                    Text(suffix).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                }
            }
        }
    }
}

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
    public static func grouped(_ digits: String) -> String {
        digits.count > 5 ? "\(digits.prefix(5)) \(digits.dropFirst(5))" : digits
    }

    /// What was typed or pasted, as the field shows it and as digits; a pasted "+91" or leading 0 is left for the
    /// domain to read.
    static func typed(_ text: String) -> (shown: String, digits: String) {
        let digits = String(text.filter(\.isNumber).prefix(12))
        return (grouped(digits), digits)
    }
}

/// A secure field in a well (the password state).
public struct SecureWell: View {
    let label: String
    @Binding var text: String
    let error: String?
    let showsFocus: Bool
    let autofocus: Bool
    let onCommit: () -> Void
    @FocusState private var focused: Bool

    public init(
        label: String,
        text: Binding<String>,
        error: String? = nil,
        showsFocus: Bool = false,
        autofocus: Bool = false,
        onCommit: @escaping () -> Void = {}
    ) {
        self.label = label
        _text = text
        self.error = error
        self.showsFocus = showsFocus
        self.autofocus = autofocus
        self.onCommit = onCommit
    }

    public var body: some View {
        Well(label: label, error: error, focused: focused || showsFocus) {
            SecureField(text: $text) { Text(label) }
                .typeStyle(Tokens.body)
                .foregroundStyle(Tokens.text.color)
                .tint(Tokens.accent.color)
                .textContentType(.password)
                .focused($focused)
                .onSubmit(onCommit)
                .task {
                    if autofocus {
                        focused = await Self.settled()
                    }
                }
        }
    }
}

/// Notes: at least 96 high, padding 12 14, the counter caption text3 at the bottom right.
public struct MultilineWell: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    let limit: Int
    @FocusState private var focused: Bool
    static var minHeight: CGFloat {
        96
    }

    public init(label: String, text: Binding<String>, placeholder: String, limit: Int) {
        self.label = label
        _text = text
        self.placeholder = placeholder
        self.limit = limit
    }

    public var body: some View {
        Well(label: label, focused: focused, height: nil) {
            TextField(
                text: $text,
                prompt: Text(placeholder).foregroundStyle(Tokens.text3.color),
                axis: .vertical
            ) { Text(label) }
                .typeStyle(Tokens.body)
                .foregroundStyle(Tokens.text.color)
                .lineLimit(3 ... 8)
                .focused($focused)
                .padding(.vertical, Tokens.rowPaddingDense)
                .padding(.bottom, Tokens.sectionGap)
                .frame(minHeight: Self.minHeight, alignment: .top)
                .overlay(alignment: .bottomTrailing) {
                    Text("\(text.count) of \(limit.formatted())")
                        .typeStyle(Tokens.caption)
                        .foregroundStyle(Tokens.text3.color)
                        .padding(.bottom, Tokens.tileGap)
                }
        }
    }
}

/// A picker row: label body left, value right in accentText 600 with chevron.up.chevron.down, on a raised surface;
/// opens a menu.
public struct PickerRow<Option: Hashable>: View {
    let label: String
    let options: [(Option, String)]
    @Binding var selection: Option

    public init(label: String, options: [(Option, String)], selection: Binding<Option>) {
        self.label = label
        self.options = options
        _selection = selection
    }

    public var body: some View {
        HStack {
            Text(label).typeStyle(Tokens.body).foregroundStyle(Tokens.text.color)
            Spacer(minLength: Tokens.inline)
            Menu {
                Picker(label, selection: $selection) {
                    ForEach(options, id: \.0) { option, title in
                        Text(title).tag(option)
                    }
                }
            } label: {
                HStack(spacing: Tokens.rowGapInner * 2) {
                    Text(options.first { $0.0 == selection }?.1 ?? "").typeStyle(Tokens.bodyStrong)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: Tokens.iconInline))
                }
                .foregroundStyle(Tokens.accentText.color)
            }
        }
        .frame(height: Well<EmptyView>.height)
        .padding(.horizontal, Tokens.cardPaddingCompact)
        .surface(radius: Tokens.radiusControl)
    }
}

extension View {
    /// Focus asked for while a sheet or a push is still arriving is dropped; wait for it (`panel`), then focus.
    static func settled() async -> Bool {
        try? await Task.sleep(for: .seconds(Tokens.panel))
        return !Task.isCancelled
    }
}
