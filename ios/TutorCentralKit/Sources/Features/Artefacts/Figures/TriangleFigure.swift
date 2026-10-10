import DesignSystem
import Foundation
import SwiftUI

/// A triangle (P10-Figure-Triangle): drawn to its angles, filled `accentTint` and edged in accent, the right angle
/// marked, each side named (`labels[i]` is the side opposite `angles[i]`), and Pythagoras beside it when the sides are
/// numbers that keep it.
struct TriangleFigure: View {
    let angles: [Int]
    let labels: [String]

    nonisolated static func rightAngleIndex(_ angles: [Int]) -> Int? {
        angles.firstIndex(of: 90)
    }

    /// "4² + 3² = 5²" and "16 + 9 = 25": only for a right angle whose three sides are whole numbers that keep the rule.
    nonisolated static func rule(angles: [Int], labels: [String]) -> [String]? {
        guard let right = rightAngleIndex(angles), labels.count == 3 else { return nil }
        let numbers = labels.compactMap(Int.init)
        guard numbers.count == 3 else { return nil }
        let legs = numbers.indices.filter { $0 != right }.map { numbers[$0] }
        let long = numbers[right]
        guard legs.map({ $0 * $0 }).reduce(0, +) == long * long else { return nil }
        return [
            legs.map { "\($0)²" }.joined(separator: " + ") + " = \(long)²",
            legs.map { "\($0 * $0)" }.joined(separator: " + ") + " = \(long * long)",
        ]
    }

    /// The corners in drawing order: the right angle (or the largest) first at the bottom left, the smaller of the
    /// others at the bottom right, so the base is the longer side under it.
    nonisolated static func order(_ angles: [Int]) -> [Int] {
        let first = rightAngleIndex(angles) ?? angles.indices.max { angles[$0] < angles[$1] } ?? 0
        let rest = angles.indices.filter { $0 != first }.sorted { angles[$0] < angles[$1] }
        return [first] + rest
    }

    var body: some View {
        Canvas { context, size in draw(in: &context, size: size) }
            .aspectRatio(FigureMeasure.squarish, contentMode: .fit)
            .padding(.vertical, Tokens.inline)
    }

    /// The corners on a unit base: the first at the origin, the second along the base, the third up at the first's
    /// angle; each side as long as the sine of the angle across from it.
    private func corners(_ order: [Int]) -> [CGPoint] {
        let sine = { (index: Int) in sin(Double(angles[index]) * .pi / 180) }
        let base = sine(order[2]), up = sine(order[1])
        let turn = Double(angles[order[0]]) * .pi / 180
        return [.zero, CGPoint(x: base, y: 0), CGPoint(x: up * cos(turn), y: -up * sin(turn))]
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let order = Self.order(angles)
        let rule = Self.rule(angles: angles, labels: labels)
        let raw = corners(order)
        let box = Tokens.rowPaddingHorizontal * 2
        let room = CGSize(width: size.width * (rule == nil ? 0.8 : 0.58) - box, height: size.height - box * 1.5)
        let minX = raw.map(\.x).min() ?? 0, maxX = raw.map(\.x).max() ?? 1, minY = raw.map(\.y).min() ?? -1
        let scale = min(room.width / max(maxX - minX, 0.01), room.height / max(-minY, 0.01))
        let origin = CGPoint(x: box - minX * scale + (rule == nil ? size.width * 0.1 : 0), y: size.height - box)
        let points = raw.map { CGPoint(x: origin.x + $0.x * scale, y: origin.y + $0.y * scale) }
        var shape = Path()
        shape.addLines(points)
        shape.closeSubpath()
        context.fill(shape, with: .color(Tokens.accentTint.color))
        context.stroke(shape, with: .color(Tokens.accent.color), lineWidth: FigureMeasure.strokeStrong)
        if angles[order[0]] == 90 {
            let mark = Path(CGRect(
                x: points[0].x, y: points[0].y - FigureMeasure.box / 5,
                width: FigureMeasure.box / 5, height: FigureMeasure.box / 5
            ))
            context.stroke(mark, with: .color(Tokens.text2.color), lineWidth: FigureMeasure.stroke)
        }
        sideLabels(in: &context, points: points, order: order)
        if let rule {
            let at = CGPoint(x: size.width * 0.66, y: size.height * 0.4)
            for (index, line) in rule.enumerated() {
                let text = Text(line).font(Tokens.caption.font).foregroundStyle(Tokens.text2.color)
                context.draw(
                    text,
                    at: CGPoint(x: at.x, y: at.y + Tokens.caption.line * CGFloat(index)),
                    anchor: .leading
                )
            }
        }
    }

    /// Each side's name outside its middle: the side across from corner k joins the other two.
    private func sideLabels(in context: inout GraphicsContext, points: [CGPoint], order: [Int]) {
        let middle = CGPoint(x: points.map(\.x).reduce(0, +) / 3, y: points.map(\.y).reduce(0, +) / 3)
        for corner in 0 ..< 3 {
            let one = points[(corner + 1) % 3], two = points[(corner + 2) % 3]
            let mid = CGPoint(x: (one.x + two.x) / 2, y: (one.y + two.y) / 2)
            let away = CGPoint(x: mid.x - middle.x, y: mid.y - middle.y)
            let length = max(hypot(away.x, away.y), 0.01)
            let gap = Tokens.rowPaddingDense
            let at = CGPoint(x: mid.x + away.x / length * gap, y: mid.y + away.y / length * gap)
            let label = labels.indices.contains(order[corner]) ? labels[order[corner]] : ""
            context.draw(Text(label).font(Tokens.captionStrong.font).foregroundStyle(Tokens.text.color), at: at)
        }
    }
}
