import SwiftUI

/// Score hero, the gap report (components.md 10.4): the eyebrow, the score in `numberHero` with "of 25" `subhead`
/// `text2`, a 4 pt bar, a `footnote` line.
public struct ScoreHero: View {
    let eyebrow: String
    let score: Int
    let of: Int
    let line: String

    public init(eyebrow: String, score: Int, of: Int, line: String) {
        self.eyebrow = eyebrow
        self.score = score
        self.of = of
        self.line = line
    }

    public var body: some View {
        Card(.hero) {
            VStack(alignment: .leading, spacing: Tokens.tileGap) {
                Eyebrow(eyebrow)
                HStack(alignment: .firstTextBaseline, spacing: Tokens.inline) {
                    Text("\(score)").typeStyle(Tokens.numberHero).monospacedDigit().foregroundStyle(Tokens.text.color)
                    Text("of \(of)").typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                }
                ProgressBar(fraction: of > 0 ? Double(score) / Double(of) : 0, tone: nil)
                Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Skill bar row (components.md 10.4): the skill `rowTitle`, a 4 pt bar (`ok` at three quarters or more, `overdue`
/// under half, `due` between), the line `footnote` `text2`, "n of m" `numberRow` in the bar's colour.
public struct SkillBarRow: View {
    let skill: String
    let line: String
    let right: Int
    let of: Int

    public init(skill: String, line: String, right: Int, of: Int) {
        self.skill = skill
        self.line = line
        self.right = right
        self.of = of
    }

    /// The bar's tone by the share right.
    nonisolated static func tone(right: Int, of: Int) -> StatusTone {
        guard of > 0 else { return .overdue }
        let share = Double(right) / Double(of)
        if share >= 0.75 {
            return .ok
        }
        return share < 0.5 ? .overdue : .due
    }

    public var body: some View {
        let tone = Self.tone(right: right, of: of)
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            AdaptiveRow {
                Text(skill).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                AdaptiveSpacer()
                Text("\(right) of \(of)").typeStyle(Tokens.numberRow).monospacedDigit()
                    .foregroundStyle(tone.color.color)
            }
            ProgressBar(fraction: of > 0 ? Double(right) / Double(of) : 0, tone: tone)
            if !line.isEmpty {
                MathText(line, style: Tokens.footnote, color: Tokens.text2)
            }
        }
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        ScoreHero(eyebrow: "Dev Kumar · Science mock · marked Tue 6 Oct", score: 14, of: 25, line: "Two days left.")
        Card {
            SkillBarRow(skill: "Balancing equations", line: "Changed the formulas", right: 3, of: 10)
        }
    }
    .padding()
    .background(Tokens.ground.color)
}
