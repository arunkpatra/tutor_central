import SwiftUI

public extension Tokens {
    static let display = TypeToken("display", .largeTitle, size: 34, line: 41, weight: 700, tracking: -0.02)
    static let displayHero = TypeToken("displayHero", .largeTitle, size: 44, line: 48, weight: 800, tracking: -0.03)
    static let title1 = TypeToken("title1", .title, size: 28, line: 34, weight: 700, tracking: -0.02)
    static let title2 = TypeToken("title2", .title2, size: 22, line: 28, weight: 700, tracking: -0.015)
    static let title3 = TypeToken("title3", .title3, size: 20, line: 25, weight: 600, tracking: -0.01)
    static let headline = TypeToken("headline", .headline, size: 17, line: 22, weight: 700)
    static let body = TypeToken("body", .body, size: 17, line: 22, weight: 400)
    static let rowTitle = TypeToken("rowTitle", .callout, size: 16, line: 20, weight: 600)
    static let subhead = TypeToken("subhead", .subheadline, size: 15, line: 20, weight: 400)
    static let footnote = TypeToken("footnote", .footnote, size: 13, line: 18, weight: 400)
    static let caption = TypeToken("caption", .caption, size: 12, line: 16, weight: 400)
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
    static let avatar = TypeToken("avatar", .subheadline, size: 14, line: 18, weight: 700)

    static let types: [TypeToken] = [
        display, displayHero, title1, title2, title3, headline, body, rowTitle, subhead, footnote, caption, eyebrow,
        tabLabel, numberTile, numberHero, numberRow, time, button, buttonSecondary, avatar,
    ]
}
