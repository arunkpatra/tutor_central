import SwiftUI

/// A student's month (components.md, Percentage hero): a hero card with the month as eyebrow, the percentage in
/// numberHero with "present" in subhead text2 beside it, the progress bar, then "1 of 3 classes · 2 absences". With
/// nothing marked the percentage reads "No classes marked yet" in title2, never 0%.
public struct PercentHero: View {
    let eyebrow: String
    let percent: String?
    let fraction: Double
    let line: String

    public init(eyebrow: String, percent: String?, fraction: Double, line: String) {
        self.eyebrow = eyebrow
        self.percent = percent
        self.fraction = fraction
        self.line = line
    }

    public var body: some View {
        Card(.hero) {
            VStack(alignment: .leading, spacing: Tokens.tileGap) {
                Eyebrow(eyebrow)
                if let percent {
                    HStack(alignment: .firstTextBaseline, spacing: Tokens.inline) {
                        Text(percent).typeStyle(Tokens.numberHero).monospacedDigit()
                            .foregroundStyle(Tokens.text.color)
                        Text("present").typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                    }
                } else {
                    Text("No classes marked yet").typeStyle(Tokens.title2).foregroundStyle(Tokens.text.color)
                }
                ProgressBar(fraction: fraction)
                Text(line).typeStyle(Tokens.footnote).monospacedDigit().foregroundStyle(Tokens.text2.color)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        PercentHero(eyebrow: "October 2026", percent: "33%", fraction: 1.0 / 3, line: "1 of 3 classes · 2 absences")
        PercentHero(eyebrow: "November 2026", percent: nil, fraction: 0, line: "Nothing marked this month")
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
