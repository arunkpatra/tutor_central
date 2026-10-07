/// The elevation table's CSS strings, verbatim. `blurChrome` is kept as its string and read by the chrome modifier.
public extension Tokens {
    static let shadowRaised = ShadowToken(
        "shadowRaised",
        dark: "inset 0 1px 0 rgba(255,255,255,.05), 0 1px 2px rgba(0,0,0,.35), 0 12px 32px rgba(0,0,0,.28)",
        light: "0 1px 2px rgba(40,30,20,.05), 0 10px 28px rgba(40,30,20,.07)"
    )
    static let shadowButton = ShadowToken(
        "shadowButton",
        dark: "inset 0 1px 0 rgba(255,255,255,.06), 0 1px 2px rgba(0,0,0,.4)",
        light: "0 1px 2px rgba(40,30,20,.08)"
    )
    static let shadowPrimary = ShadowToken(
        "shadowPrimary",
        dark: "inset 0 1px 0 rgba(255,255,255,.35), 0 8px 22px rgba(255,171,56,.28)",
        light: "inset 0 1px 0 rgba(255,255,255,.4), 0 8px 22px rgba(224,138,0,.26)"
    )
    static let shadowPrimaryPressed = ShadowToken(
        "shadowPrimaryPressed",
        dark: "inset 0 2px 4px rgba(0,0,0,.25)",
        light: "inset 0 2px 4px rgba(0,0,0,.15)"
    )
    static let shadowWell = ShadowToken("shadowWell", dark: "inset 0 1px 3px rgba(0,0,0,.6)", light: "none")
    static let shadowSegment = ShadowToken(
        "shadowSegment",
        dark: "inset 0 1px 0 rgba(255,255,255,.1), 0 1px 3px rgba(0,0,0,.55)",
        light: "0 1px 3px rgba(40,30,20,.14)"
    )
    static let shadowFloat = ShadowToken(
        "shadowFloat",
        dark: "0 10px 30px rgba(0,0,0,.35), inset 0 1px 0 rgba(255,255,255,.06)",
        light: "0 10px 30px rgba(40,30,20,.14), inset 0 1px 0 rgba(255,255,255,.6)"
    )
    static let shadowDialog = ShadowToken(
        "shadowDialog",
        dark: "0 24px 64px rgba(0,0,0,.55)",
        light: "0 24px 64px rgba(40,30,20,.2)"
    )
    static let haloFocus = ShadowToken(
        "haloFocus",
        dark: "0 0 0 3px rgba(255,171,56,.18)",
        light: "0 0 0 3px rgba(224,138,0,.16)"
    )
    static let shadowLogo = ShadowToken(
        "shadowLogo",
        dark: "0 10px 26px rgba(255,171,56,.3), inset 0 1px 0 rgba(255,255,255,.4)",
        light: "0 10px 26px rgba(255,171,56,.3), inset 0 1px 0 rgba(255,255,255,.4)"
    )
    static let shadowButtonLanding = ShadowToken(
        "shadowButtonLanding",
        dark: "inset 0 1px 0 rgba(255,255,255,.05), 0 1px 2px rgba(0,0,0,.35)",
        light: "0 1px 2px rgba(40,30,20,.08)"
    )
    static let blurChrome = ShadowToken("blurChrome", dark: "blur 22, saturate 1.3", light: "blur 22, saturate 1.3")

    static let shadows: [ShadowToken] = [
        shadowRaised, shadowButton, shadowPrimary, shadowPrimaryPressed, shadowWell, shadowSegment, shadowFloat,
        shadowDialog, haloFocus, shadowLogo, shadowButtonLanding, blurChrome,
    ]

    /// Disabled: opacity 0.45 and no shadow. Stale: 0.55 with a spinner beside it.
    static let opacityDisabled = 0.45
    static let opacityStale = 0.55
}
