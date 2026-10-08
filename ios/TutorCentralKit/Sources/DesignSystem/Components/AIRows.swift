import SwiftUI

/// Tool row (AI Assistant, P6-Assistant): the Class row's shape: the icon tile 40 of the tool, its title (rowTitle),
/// one footnote line in text2, a chevron.
public struct ToolRow: View {
    let symbol: String
    let title: String
    let line: String
    let action: () -> Void

    public init(symbol: String, title: String, line: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.line = line
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            IconTile(symbol: symbol)
            RowTitles(title: title, subtitle: line)
            Chevron()
        }
    }
}

/// Result row (AI Assistant's Recent and History; components.md, History row): the same row for a result: the icon tile
/// of its kind, the topic (or the student's name), and
/// "Question paper · Class 10 Maths · Tue 6 Oct". Kept apart from the tool row so the Kit names both.
public struct ResultRow: View {
    let symbol: String
    let title: String
    let line: String
    let action: () -> Void

    public init(symbol: String, title: String, line: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.line = line
        self.action = action
    }

    public var body: some View {
        ListRow(action: action) {
            IconTile(symbol: symbol)
            RowTitles(title: title, subtitle: line)
            Chevron()
        }
    }
}

/// Error row (P6-Generate-Failed): a list card's one row: exclamationmark.circle 24 in overdue, a rowHeading, a
/// rowLine in text2, a quiet Retry (700) on the right; no Retry when trying again cannot help (the day's limit).
public struct ErrorRow: View {
    let title: String
    let line: String
    let retry: (() -> Void)?
    static var symbolSize: CGFloat {
        24
    }

    public init(title: String, line: String, retry: (() -> Void)?) {
        self.title = title
        self.line = line
        self.retry = retry
    }

    public var body: some View {
        Card {
            HStack(spacing: Tokens.cardPaddingCompact) {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: Self.symbolSize))
                    .foregroundStyle(Tokens.overdue.color)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(title).typeStyle(Tokens.rowHeading).foregroundStyle(Tokens.text.color)
                    Text(line)
                        .typeStyle(Tokens.rowLine)
                        .foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                if let retry {
                    Button("Retry", action: retry).buttonStyle(.quiet(emphasised: true))
                }
            }
            .padding(Tokens.rowPaddingHorizontal)
        }
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        Card {
            VStack(spacing: 0) {
                ToolRow(symbol: "doc.text", title: "Question paper", line: "Questions with marks, by section") {}
                ResultRow(symbol: "text.bubble", title: "Hemanth Reddy", line: "Progress note · Mon 5 Oct") {}
            }
        }
        ErrorRow(title: "Couldn't create the paper.", line: "Check your connection and try again.") {}
        ErrorRow(
            title: "You've made today's 40. Try again tomorrow.",
            line: "The limit resets in 24 hours.",
            retry: nil
        )
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
