import SwiftUI

/// A skill's state as the Kit draws it (Domain's `SkillState`, kept apart: the Kit imports nothing).
public enum SkillMark: Sendable, CaseIterable {
    case secure, practising, taught, revisit, notStarted

    /// Secure `ok`, Practising `due`, Revisit `overdue`; Taught text2 and Not started text3 have none.
    public var tone: StatusTone? {
        switch self {
        case .secure: .ok
        case .practising: .due
        case .revisit: .overdue
        case .taught, .notStarted: nil
        }
    }

    public var symbol: String {
        switch self {
        case .secure: "checkmark.circle"
        case .practising: "clock"
        case .revisit: "exclamationmark.circle"
        case .taught, .notStarted: "circle"
        }
    }

    public var word: String {
        switch self {
        case .secure: "Secure"
        case .practising: "Practising"
        case .taught: "Taught"
        case .revisit: "Revisit"
        case .notStarted: "Not started"
        }
    }

    var color: ColorToken {
        tone?.color ?? (self == .taught ? Tokens.text2 : Tokens.text3)
    }
}

/// The state mark (components.md "State mark"): symbol 16 and the word in caption 600, in the state's colour.
public struct StateMark: View {
    let mark: SkillMark

    public init(_ mark: SkillMark) {
        self.mark = mark
    }

    public var body: some View {
        Label {
            Text(mark.word).typeStyle(Tokens.captionStrong)
        } icon: {
            Image(systemName: mark.symbol).font(.system(size: Tokens.iconInline))
        }
        .labelStyle(InlineLabelStyle())
        .foregroundStyle(mark.color.color)
        .fixedSize()
    }
}

/// The first row of a subject's card (components.md "Subject head"): the subject 15/700 over its line, a quiet action.
public struct SubjectHead: View {
    let title: String
    let line: String
    let action: (label: String, run: () -> Void)?

    public init(title: String, line: String, action: (label: String, run: () -> Void)? = nil) {
        self.title = title
        self.line = line
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Tokens.inline) {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(title).typeStyle(Tokens.buttonStrong).foregroundStyle(Tokens.text.color)
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let action {
                Button(action.label, action: action.run).buttonStyle(.quiet).fixedSize()
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
    }
}

/// A chapter (components.md "Chapter row"): the position in a 20 pt column (`time` text2), the name, its states' line,
/// chevron.down; open, on surface2 with chevron.up.
public struct ChapterRow: View {
    let position: Int
    let name: String
    let line: String
    let open: Bool
    let action: () -> Void
    static var positionWidth: CGFloat {
        20
    }

    public init(position: Int, name: String, line: String, open: Bool, action: @escaping () -> Void) {
        self.position = position
        self.name = name
        self.line = line
        self.open = open
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.rowPaddingDense) {
                Text("\(position)")
                    .typeStyle(Tokens.time)
                    .foregroundStyle(Tokens.text2.color)
                    .frame(width: Self.positionWidth, alignment: .leading)
                RowTitles(title: name, subtitle: line)
                Image(systemName: open ? "chevron.up" : "chevron.down")
                    .font(.system(size: Tokens.iconInline, weight: .semibold))
                    .foregroundStyle(Tokens.text3.color)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .background(open ? Tokens.surface2.color : .clear)
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityHint(open ? "Hides its skills" : "Shows its skills")
    }
}

/// A skill under its open chapter (components.md "Skill row"): indented, the skill subhead, an optional caption line,
/// the
/// state mark on the right.
public struct SkillRow: View {
    let name: String
    let line: String?
    let mark: SkillMark
    static var indent: CGFloat {
        44
    }

    public init(name: String, line: String?, mark: SkillMark) {
        self.name = name
        self.line = line
        self.mark = mark
    }

    public var body: some View {
        HStack(spacing: Tokens.inline) {
            VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                Text(name).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text.color)
                if let line {
                    Text(line).typeStyle(Tokens.caption).foregroundStyle(Tokens.text3.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StateMark(mark)
        }
        .padding(.vertical, Tokens.tileGap)
        .padding(.leading, Self.indent)
        .padding(.trailing, Tokens.rowPaddingHorizontal)
        .accessibilityElement(children: .combine)
    }
}
