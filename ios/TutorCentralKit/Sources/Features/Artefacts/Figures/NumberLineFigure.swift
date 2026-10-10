import DesignSystem
import SwiftUI

/// A number line (P10-Figure-NumberLine): "3 + 4 = 7" over the line, a tick per step, the start and the landing marked
/// in accent, an arc per jump; the ends, the start and the landing numbered.
struct NumberLineFigure: View {
    let from: Int
    let to: Int
    let step: Int
    let start: Int
    let jumps: [Int]

    /// "3 + 4 = 7"; jumps back, "9 − 4 = 5".
    nonisolated static func sum(start: Int, jumps: [Int]) -> String {
        let total = jumps.reduce(0, +)
        let sign = total < 0 ? "−" : "+"
        return "\(start) \(sign) \(abs(total)) = \(start + total)"
    }

    var body: some View {
        VStack(spacing: Tokens.inline) {
            Text(Self.sum(start: start, jumps: jumps)).typeStyle(Tokens.captionStrong)
                .foregroundStyle(Tokens.text.color)
            Canvas { context, size in draw(in: &context, size: size) }
                .aspectRatio(FigureMeasure.wide * 1.3, contentMode: .fit)
        }
        .padding(.vertical, Tokens.inline)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let side = Tokens.rowPaddingHorizontal
        let axis = size.height * 0.55
        let span = CGFloat(max(to - from, 1))
        let x = { (value: Int) in side + CGFloat(value - from) / span * (size.width - side * 2) }
        var line = Path()
        line.move(to: CGPoint(x: side, y: axis))
        line.addLine(to: CGPoint(x: size.width - side, y: axis))
        for value in stride(from: from, through: to, by: max(step, 1)) {
            line.move(to: CGPoint(x: x(value), y: axis - FigureMeasure.tick))
            line.addLine(to: CGPoint(x: x(value), y: axis + FigureMeasure.tick))
        }
        context.stroke(line, with: .color(Tokens.text2.color), lineWidth: FigureMeasure.stroke)
        var arcs = Path()
        var at = start
        for jump in jumps {
            let left = x(at), right = x(at + jump)
            arcs.move(to: CGPoint(x: left, y: axis))
            arcs.addQuadCurve(
                to: CGPoint(x: right, y: axis),
                control: CGPoint(x: (left + right) / 2, y: axis - size.height * 0.5)
            )
            at += jump
        }
        context.stroke(arcs, with: .color(Tokens.accent.color), lineWidth: FigureMeasure.strokeStrong)
        for value in [start, at] {
            let dot = CGRect(
                x: x(value) - FigureMeasure.dot, y: axis - FigureMeasure.dot,
                width: FigureMeasure.dot * 2, height: FigureMeasure.dot * 2
            )
            context.fill(Path(ellipseIn: dot), with: .color(Tokens.accent.color))
        }
        for value in Set([from, to, start, at]) {
            let label = Text("\(value)").font(Tokens.caption.font).foregroundStyle(Tokens.text2.color)
            context.draw(label, at: CGPoint(x: x(value), y: axis + FigureMeasure.tick * 2), anchor: .top)
        }
    }
}
