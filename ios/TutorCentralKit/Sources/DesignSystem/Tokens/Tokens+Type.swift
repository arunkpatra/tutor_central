import SwiftUI

public extension Tokens {
    static let display = TypeToken("display", .largeTitle, size: 34, line: 41, weight: 700, tracking: -0.02)
    static let displayHero = TypeToken("displayHero", .largeTitle, size: 44, line: 48, weight: 800, tracking: -0.03)
    static let displayCompact = TypeToken(
        "displayCompact", .largeTitle, size: 32, line: 36, weight: 700, tracking: -0.02
    )
    static let title1 = TypeToken("title1", .title, size: 28, line: 34, weight: 700, tracking: -0.02)
    static let title2 = TypeToken("title2", .title2, size: 22, line: 28, weight: 700, tracking: -0.015)
    static let title3 = TypeToken("title3", .title3, size: 20, line: 25, weight: 600, tracking: -0.01)
    static let headline = TypeToken("headline", .headline, size: 17, line: 22, weight: 700)
    static let body = TypeToken("body", .body, size: 17, line: 22, weight: 400)
    static let bodyStrong = TypeToken("bodyStrong", .body, size: 17, line: 22, weight: 600)
    static let rowTitle = TypeToken("rowTitle", .callout, size: 16, line: 20, weight: 600)
    static let subhead = TypeToken("subhead", .subheadline, size: 15, line: 20, weight: 400)
    static let footnote = TypeToken("footnote", .footnote, size: 13, line: 18, weight: 400)
    static let caption = TypeToken("caption", .caption, size: 12, line: 16, weight: 400)
    static let captionStrong = TypeToken("captionStrong", .caption, size: 12, line: 16, weight: 600)
    static let eyebrow = TypeToken(
        "eyebrow",
        .caption,
        size: 12,
        line: 16,
        weight: 600,
        tracking: 0.08,
        uppercase: true
    )
    static let tabLabel = TypeToken("tabLabel", .caption2, size: 10, line: 12, weight: 600, tracking: 0.01)
    static let numberTile = TypeToken("numberTile", .title, size: 26, line: 30, weight: 700, tracking: -0.02)
    static let numberHero = TypeToken("numberHero", .largeTitle, size: 40, line: 44, weight: 700, tracking: -0.02)
    static let numberRow = TypeToken("numberRow", .callout, size: 16, line: 20, weight: 700)
    static let time = TypeToken("time", .subheadline, size: 14, line: 18, weight: 600)
    static let button = TypeToken("button", .callout, size: 16, line: 20, weight: 700)
    static let buttonSecondary = TypeToken("buttonSecondary", .subheadline, size: 15, line: 20, weight: 600)
    static let buttonStrong = TypeToken("buttonStrong", .subheadline, size: 15, line: 20, weight: 700)
    static let segment = TypeToken("segment", .subheadline, size: 14, line: 18, weight: 600)
    static let segmentActive = TypeToken("segmentActive", .subheadline, size: 14, line: 18, weight: 700)
    static let chipLabel = TypeToken("chipLabel", .footnote, size: 13, line: 18, weight: 700)
    static let chipCompactLabel = TypeToken("chipCompactLabel", .caption, size: 12, line: 16, weight: 700)
    static let chipNeutralLabel = TypeToken("chipNeutralLabel", .footnote, size: 13, line: 18, weight: 600)
    static let day = TypeToken("day", .subheadline, size: 15, line: 20, weight: 600)
    static let dayToday = TypeToken("dayToday", .subheadline, size: 15, line: 20, weight: 700)
    static let avatar = TypeToken("avatar", .subheadline, size: 14, line: 18, weight: 700)
    static let avatarSmall = TypeToken("avatarSmall", .footnote, size: 13, line: 18, weight: 700)
    static let avatarLarge = TypeToken("avatarLarge", .title3, size: 20, line: 25, weight: 700)

    static let types: [TypeToken] = [
        display, displayHero, displayCompact, title1, title2, title3, headline, body, bodyStrong, rowTitle, subhead,
        footnote, caption, captionStrong, eyebrow, tabLabel, numberTile, numberHero, numberRow, time, button,
        buttonSecondary, buttonStrong, segment, segmentActive, chipLabel, chipCompactLabel, chipNeutralLabel, day,
        dayToday, avatar, avatarSmall, avatarLarge,
    ]
}
