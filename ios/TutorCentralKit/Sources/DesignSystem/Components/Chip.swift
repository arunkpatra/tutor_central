import SwiftUI

/// The states of money and attendance: paid and present are `ok`, due is `due`, overdue and absent are `overdue`.
public enum StatusTone: Sendable {
    case ok
    case due
    case overdue

    public var color: ColorToken {
        switch self {
        case .ok: Tokens.ok
        case .due: Tokens.due
        case .overdue: Tokens.overdue
        }
    }

    public var tint: ColorToken {
        switch self {
        case .ok: Tokens.okTint
        case .due: Tokens.dueTint
        case .overdue: Tokens.overdueTint
        }
    }

    /// The ink of text on a full fill of the status colour (the attendance toggles, a confirming delete).
    public var ink: ColorToken {
        switch self {
        case .ok: Tokens.okInk
        case .due: Tokens.textOnAccent
        case .overdue: Tokens.overdueInk
        }
    }
}

/// 28 high, radiusChip, padding 0 10, 13 700; status: tint fill, status text, an optional leading symbol (checkmark
/// paid, clock due, exclamationmark.circle overdue); neutral: surface2, text2 600. `compact` is the chip inside a fee
/// row: 24 high, padding 0 8, 12 700 (Kit-Surfaces board). The word is always there; colour never says it alone.
public struct Chip: View {
    public enum Kind: Sendable {
        case status(StatusTone, String, symbol: String? = nil)
        case neutral(String)
    }

    let kind: Kind
    let compact: Bool
    static var height: CGFloat {
        28
    }

    static var compactHeight: CGFloat {
        24
    }

    static var symbolSize: CGFloat {
        12
    }

    public init(_ kind: Kind, compact: Bool = false) {
        self.kind = kind
        self.compact = compact
    }

    public var body: some View {
        HStack(spacing: Tokens.fieldGap) {
            if case let .status(_, _, symbol?) = kind {
                Image(systemName: symbol).font(.system(size: Self.symbolSize, weight: .bold))
            }
            Text(title)
        }
        .typeStyle(type)
        .foregroundStyle(ink.color)
        .padding(.horizontal, compact ? Tokens.inline : Tokens.tileGap)
        .frame(height: compact ? Self.compactHeight : Self.height)
        .background(fill.color, in: .capsule)
    }

    private var title: String {
        switch kind {
        case let .status(_, text, _), let .neutral(text): text
        }
    }

    private var type: TypeToken {
        switch kind {
        case .status: compact ? Tokens.chipCompactLabel : Tokens.chipLabel
        case .neutral: Tokens.chipNeutralLabel
        }
    }

    private var ink: ColorToken {
        switch kind {
        case let .status(tone, _, _): tone.color
        case .neutral: Tokens.neutral
        }
    }

    private var fill: ColorToken {
        switch kind {
        case let .status(tone, _, _): tone.tint
        case .neutral: Tokens.surface2
        }
    }
}
