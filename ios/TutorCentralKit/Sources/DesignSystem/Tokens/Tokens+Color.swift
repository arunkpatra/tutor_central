public extension Tokens {
    static let ground = ColorToken("ground", dark: "#131110", light: "#F8F4EE")
    static let surface1 = ColorToken("surface1", dark: "#1C1917", light: "#FFFFFF")
    static let surface2 = ColorToken("surface2", dark: "#272220", light: "#F1EBE2")
    static let well = ColorToken("well", dark: "#0E0C0B", light: "#F3EEE6")
    static let chrome = ColorToken("chrome", dark: "rgba(28,25,23,.74)", light: "rgba(255,255,255,.74)")
    static let dim = ColorToken("dim", dark: "rgba(8,6,5,.6)", light: "rgba(40,30,20,.35)")
    static let line = ColorToken("line", dark: "#302A27", light: "#E8E0D5")
    static let lineStrong = ColorToken("lineStrong", dark: "#3D3632", light: "#D5CBBE")
    static let lineGlass = ColorToken("lineGlass", dark: "rgba(255,255,255,.08)", light: "rgba(0,0,0,.06)")
    static let text = ColorToken("text", dark: "#F6F1EA", light: "#1F1B17")
    static let text2 = ColorToken("text2", dark: "#B9AFA5", light: "#625A52")
    static let text3 = ColorToken("text3", dark: "#958B80", light: "#766D66")
    static let textOnAccent = ColorToken("textOnAccent", dark: "#221400", light: "#231500")
    static let accent = ColorToken("accent", dark: "#FFAB38", light: "#FFAB38")
    static let accentPressed = ColorToken("accentPressed", dark: "#E6952A", light: "#E6952A")
    static let accentText = ColorToken("accentText", dark: "#FFAB38", light: "#A35F00")
    static let accentTint = ColorToken("accentTint", dark: "rgba(255,171,56,.14)", light: "rgba(224,138,0,.14)")
    static let ok = ColorToken("ok", dark: "#56D9A6", light: "#0F7F59")
    static let okTint = ColorToken("okTint", dark: "rgba(86,217,166,.14)", light: "rgba(15,127,89,.12)")
    static let due = ColorToken("due", dark: "#FFB84D", light: "#A85F00")
    static let dueTint = ColorToken("dueTint", dark: "rgba(255,184,77,.14)", light: "rgba(168,95,0,.12)")
    static let overdue = ColorToken("overdue", dark: "#FF6F61", light: "#D13B2C")
    static let overdueTint = ColorToken("overdueTint", dark: "rgba(255,111,97,.14)", light: "rgba(209,59,44,.12)")
    /// The document writes `text2` for both; the alias keeps its own name so a chip says what it is.
    static let neutral = ColorToken("neutral", dark: "#B9AFA5", light: "#625A52")
    static let glowHero = ColorToken("glowHero", dark: "rgba(255,171,56,.18)", light: "rgba(255,171,56,.18)")
    static let glowHeroSoft = ColorToken("glowHeroSoft", dark: "rgba(255,171,56,.14)", light: "rgba(255,171,56,.14)")
    static let buttonFill = ColorToken("buttonFill", dark: "#272220", light: "#FFFFFF")
    static let okInk = ColorToken("okInk", dark: "#0B2A1D", light: "#0B2A1D")
    static let overdueInk = ColorToken("overdueInk", dark: "#2B0906", light: "#2B0906")
    static let onStatus = ColorToken("onStatus", dark: "#FFFFFF", light: "#FFFFFF")
    /// Continue with Google as Google's sign-in branding guidelines draw it (P7-SignIn-Google).
    static let googleFill = ColorToken("googleFill", dark: "#131314", light: "#FFFFFF")
    static let googleLine = ColorToken("googleLine", dark: "#8E918F", light: "#747775")
    static let googleInk = ColorToken("googleInk", dark: "#E3E3E3", light: "#1F1F1F")

    static let colors: [ColorToken] = [
        ground, surface1, surface2, well, chrome, dim, line, lineStrong, lineGlass, text, text2, text3, textOnAccent,
        accent, accentPressed, accentText, accentTint, ok, okTint, due, dueTint, overdue, overdueTint, neutral,
        glowHero, glowHeroSoft, buttonFill, okInk, overdueInk, onStatus, googleFill, googleLine,
        googleInk,
    ]
}
