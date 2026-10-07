import SwiftUI

/// The heights of components.md: 46 in a row of buttons and in forms, 50 the primary on a card, 52 sign-in and sheet
/// footers; 44 inside a list row (Kit-Surfaces board).
public enum ButtonSize: CGFloat, Sendable {
    var radius: CGFloat {
        self == .row ? Tokens.radiusChip : Tokens.radiusControl
    }

    /// Inside a row (a fee row's Remind and Mark paid) and quiet sheet actions: 44, radius 14, label 15.
    case row = 44
    case form = 46
    case card = 50
    case sheet = 52
}

/// Primary: accent fill, textOnAccent, shadowPrimary; pressed accentPressed and shadowPrimaryPressed; disabled 0.45 and
/// no shadow; loading keeps the width and shows a spinner in the label colour.
public struct PrimaryButtonStyle: ButtonStyle {
    let size: ButtonSize
    let loading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.showsPressed) private var showsPressed

    public init(size: ButtonSize = .form, loading: Bool = false) {
        self.size = size
        self.loading = loading
    }

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed || showsPressed
        return ButtonFace(label: configuration.label, size: size, loading: loading, ink: Tokens.textOnAccent)
            .typeStyle(size == .row ? Tokens.buttonStrong : Tokens.button)
            .background(
                (pressed ? Tokens.accentPressed : Tokens.accent).color,
                in: .rect(cornerRadius: size.radius, style: .continuous)
            )
            .shadowed(
                isEnabled ? [pressed ? Tokens.shadowPrimaryPressed : Tokens.shadowPrimary] : [],
                radius: size.radius
            )
            .opacity(isEnabled ? 1 : Tokens.opacityDisabled)
            .pressEffect(pressed)
    }
}

/// Secondary: surface2 (dark) / surface1 (light), text 15 600, lineStrong border, shadowButton; pressed: the well
/// fill with the pressed inset (Kit-Controls board).
public struct SecondaryButtonStyle: ButtonStyle {
    let size: ButtonSize
    let loading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.showsPressed) private var showsPressed

    public init(size: ButtonSize = .form, loading: Bool = false) {
        self.size = size
        self.loading = loading
    }

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed || showsPressed
        return ButtonFace(label: configuration.label, size: size, loading: loading, ink: Tokens.text)
            .typeStyle(Tokens.buttonSecondary)
            .background(
                (pressed ? Tokens.well : Tokens.buttonFill).color,
                in: .rect(cornerRadius: size.radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                    .strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline)
            )
            .shadowed(
                isEnabled ? [pressed ? Tokens.shadowPrimaryPressed : Tokens.shadowButton] : [],
                radius: size.radius
            )
            .opacity(isEnabled ? 1 : Tokens.opacityDisabled)
            .pressEffect(pressed)
    }
}

/// Quiet: accentText 15 600, no fill, no border. Inline in headers and rows; `size` gives it a button's height.
public struct QuietButtonStyle: ButtonStyle {
    let size: ButtonSize?
    let emphasised: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(size: ButtonSize? = nil, emphasised: Bool = false) {
        self.size = size
        self.emphasised = emphasised
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .typeStyle(emphasised ? Tokens.buttonStrong : Tokens.buttonSecondary)
            .foregroundStyle(Tokens.accentText.color)
            .frame(minHeight: size?.rawValue)
            .padding(.horizontal, size == nil ? 0 : Tokens.rowPaddingHorizontal)
            .contentShape(.rect)
            .opacity(isEnabled ? (configuration.isPressed ? Tokens.opacityStale : 1) : Tokens.opacityDisabled)
    }
}

/// Destructive: overdueTint fill, overdue text 15 600; always followed by a confirmation. `solid` is the confirming
/// action inside that confirmation: overdue fill, overdueInk 700 (Kit-Surfaces board).
public struct DestructiveButtonStyle: ButtonStyle {
    let size: ButtonSize
    let solid: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(size: ButtonSize = .form, solid: Bool = false) {
        self.size = size
        self.solid = solid
    }

    public func makeBody(configuration: Configuration) -> some View {
        ButtonFace(
            label: configuration.label,
            size: size,
            loading: false,
            ink: solid ? Tokens.overdueInk : Tokens.overdue
        )
        .typeStyle(solid ? Tokens.buttonStrong : Tokens.buttonSecondary)
        .background(
            (solid ? Tokens.overdue : Tokens.overdueTint).color,
            in: .rect(cornerRadius: size.radius, style: .continuous)
        )
        .opacity(isEnabled ? 1 : Tokens.opacityDisabled)
        .pressEffect(configuration.isPressed)
    }
}

/// The label of a filled button: the ink colour, the height, the side padding, and the spinner while loading.
private struct ButtonFace<Label: View>: View {
    let label: Label
    let size: ButtonSize
    let loading: Bool
    let ink: ColorToken

    var body: some View {
        label
            .labelStyle(ButtonLabelStyle())
            .opacity(loading ? 0 : 1)
            .overlay {
                if loading {
                    ProgressView().tint(ink.color).accessibilityLabel("Working")
                }
            }
            .foregroundStyle(ink.color)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: size.rawValue, maxHeight: size.rawValue)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .contentShape(.rect)
    }
}

/// An icon leads the label at 20 pt with the `inline` gap.
struct ButtonLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Tokens.inline) {
            configuration.icon.font(.system(size: Tokens.iconButton))
            configuration.title
        }
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static func primary(_ size: ButtonSize = .form, loading: Bool = false) -> Self {
        .init(size: size, loading: loading)
    }
}

public extension ButtonStyle where Self == SecondaryButtonStyle {
    static func secondary(_ size: ButtonSize = .form, loading: Bool = false) -> Self {
        .init(size: size, loading: loading)
    }
}

public extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: Self {
        .init()
    }

    static func quiet(_ size: ButtonSize? = nil, emphasised: Bool = false) -> Self {
        .init(size: size, emphasised: emphasised)
    }
}

public extension ButtonStyle where Self == DestructiveButtonStyle {
    static func destructive(_ size: ButtonSize = .form, solid: Bool = false) -> Self {
        .init(size: size, solid: solid)
    }
}

/// The landing's Google and email buttons (A-SignIn, P2-SignIn-Light): 52 high, surface1, lineStrong border,
/// shadowButtonLanding, label 17 600, the icon 10 from it.
public struct LandingButtonStyle: ButtonStyle {
    let loading: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(loading: Bool = false) {
        self.loading = loading
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Tokens.tileGap) {
            configuration.label
        }
        .labelStyle(LandingLabelStyle())
        .typeStyle(Tokens.bodyStrong)
        .foregroundStyle(Tokens.text.color)
        .opacity(loading ? 0 : 1)
        .overlay {
            if loading {
                ProgressView().tint(Tokens.text.color).accessibilityLabel("Working")
            }
        }
        .frame(maxWidth: .infinity, minHeight: ButtonSize.sheet.rawValue, maxHeight: ButtonSize.sheet.rawValue)
        .contentShape(.rect)
        .background(
            (configuration.isPressed ? Tokens.well : Tokens.surface1).color,
            in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                .strokeBorder(Tokens.lineStrong.color, lineWidth: Tokens.hairline)
        )
        .shadowed(isEnabled ? [Tokens.shadowButtonLanding] : [], radius: Tokens.radiusControl)
        .opacity(isEnabled ? 1 : Tokens.opacityDisabled)
        .pressEffect(configuration.isPressed)
    }
}

private struct LandingLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Tokens.tileGap) {
            configuration.icon.font(.system(size: Tokens.iconButton))
            configuration.title
        }
    }
}

public extension ButtonStyle where Self == LandingButtonStyle {
    static func landing(loading: Bool = false) -> Self {
        .init(loading: loading)
    }
}
