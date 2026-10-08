import SwiftUI

/// The six wells of the code board: 56 high, radiusChip, numberTile digits, 8 apart, one hidden text field with
/// `.oneTimeCode` so the code fills from the email on this phone. The well the next digit goes in carries the accent
/// border and halo; a wrong code paints every border overdue.
public struct CodeField: View {
    @Binding var code: String
    let length: Int
    let isWrong: Bool
    let showsFocus: Bool
    let autofocus: Bool
    @FocusState private var focused: Bool
    static var wellHeight: CGFloat {
        56
    }

    /// `showsFocus` draws the active well even before the keyboard is up (the board, and the screenshots).
    public init(
        code: Binding<String>,
        length: Int = 6,
        isWrong: Bool = false,
        showsFocus: Bool = false,
        autofocus: Bool = true
    ) {
        _code = code
        self.length = length
        self.isWrong = isWrong
        self.showsFocus = showsFocus
        self.autofocus = autofocus
    }

    public var body: some View {
        ZStack {
            TextField(
                "",
                text: Binding(
                    get: { code },
                    set: { code = String($0.filter { $0.isASCII && $0.isNumber }.prefix(length)) }
                )
            )
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($focused)
            .opacity(0.02) // present for the keyboard and autofill, not seen
            .accessibilityLabel("Six-digit code")
            HStack(spacing: Tokens.inline) {
                ForEach(0 ..< length, id: \.self) { i in
                    digitWell(at: i)
                }
            }
            .contentShape(.rect)
            .onTapGesture { focused = true }
        }
        .task {
            if autofocus {
                focused = await Self.settled()
            }
        }
    }

    private func digitWell(at index: Int) -> some View {
        let digit = index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""
        let active = (focused || showsFocus) && !isWrong && index == min(code.count, length - 1)
        let border = isWrong ? Tokens.overdue : active ? Tokens.accent : Tokens.line
        return Text(digit)
            .typeStyle(Tokens.numberTile)
            .foregroundStyle(Tokens.text.color)
            .frame(maxWidth: .infinity)
            .frame(height: Self.wellHeight)
            .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusChip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radiusChip, style: .continuous)
                    .strokeBorder(border.color, lineWidth: Tokens.hairline)
            )
            .shadowed(active ? [Tokens.shadowWell, Tokens.haloFocus] : [Tokens.shadowWell], radius: Tokens.radiusChip)
            .accessibilityHidden(true)
    }
}
