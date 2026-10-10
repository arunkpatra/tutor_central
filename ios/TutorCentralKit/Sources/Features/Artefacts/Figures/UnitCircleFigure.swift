import DesignSystem
import Foundation
import SwiftUI

/// The unit circle (P10-Figure-UnitCircle): the axes, the circle, the radius to the point at the angle in accent, the
/// sine's drop to the axis in ok, the point's coordinates, and the two ratios beside it.
struct UnitCircleFigure: View {
    struct Ratios: Hashable {
        let sine: String
        let cosine: String
    }

    let angle: Int

    nonisolated static func ratios(_ angle: Int) -> Ratios {
        let radians = Double(angle) * .pi / 180
        return Ratios(sine: FigureNumbers.decimal(sin(radians)), cosine: FigureNumbers.decimal(cos(radians)))
    }

    var body: some View {
        Canvas { context, size in draw(in: &context, size: size) }
            .aspectRatio(FigureMeasure.squarish, contentMode: .fit)
            .padding(.vertical, Tokens.inline)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let radius = size.height * 0.36
        let centre = CGPoint(x: size.width * 0.36, y: size.height * 0.52)
        let radians = Double(angle) * .pi / 180
        let point = CGPoint(x: centre.x + radius * cos(radians), y: centre.y - radius * sin(radians))
        var axes = Path()
        axes.move(to: CGPoint(x: centre.x - radius * 1.25, y: centre.y))
        axes.addLine(to: CGPoint(x: centre.x + radius * 1.25, y: centre.y))
        axes.move(to: CGPoint(x: centre.x, y: centre.y - radius * 1.25))
        axes.addLine(to: CGPoint(x: centre.x, y: centre.y + radius * 1.25))
        context.stroke(axes, with: .color(Tokens.lineStrong.color), lineWidth: FigureMeasure.stroke)
        let circle = Path(ellipseIn: CGRect(
            x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2
        ))
        context.stroke(circle, with: .color(Tokens.text2.color), lineWidth: FigureMeasure.stroke)
        var drop = Path()
        drop.move(to: point)
        drop.addLine(to: CGPoint(x: point.x, y: centre.y))
        context.stroke(
            drop, with: .color(Tokens.ok.color),
            style: StrokeStyle(lineWidth: FigureMeasure.stroke, dash: FigureMeasure.dash)
        )
        var arm = Path()
        arm.move(to: centre)
        arm.addLine(to: point)
        arm.move(to: CGPoint(x: centre.x + radius * 0.22, y: centre.y))
        arm.addArc(
            center: centre, radius: radius * 0.22, startAngle: .zero, endAngle: .degrees(-Double(angle)),
            clockwise: true
        )
        context.stroke(arm, with: .color(Tokens.accent.color), lineWidth: FigureMeasure.strokeStrong)
        let dot = CGRect(
            x: point.x - FigureMeasure.dot, y: point.y - FigureMeasure.dot,
            width: FigureMeasure.dot * 2, height: FigureMeasure.dot * 2
        )
        context.fill(Path(ellipseIn: dot), with: .color(Tokens.accent.color))
        labels(in: &context, size: size, centre: centre, point: point, radius: radius)
    }

    private func labels(
        in context: inout GraphicsContext, size: CGSize, centre: CGPoint, point: CGPoint, radius: CGFloat
    ) {
        let ratios = Self.ratios(angle)
        let strong = { (text: String) in
            Text(text).font(Tokens.captionStrong.font).foregroundStyle(Tokens.text.color)
        }
        context.draw(
            strong("(\(ratios.cosine), \(ratios.sine))"),
            at: CGPoint(x: point.x + FigureMeasure.dot * 2, y: point.y - FigureMeasure.dot), anchor: .bottomLeading
        )
        let side = point.x >= centre.x
        context.draw(
            Text("sin \(angle)°").font(Tokens.caption.font).foregroundStyle(Tokens.ok.color),
            at: CGPoint(x: point.x + (side ? 1 : -1) * FigureMeasure.dot * 1.5, y: (point.y + centre.y) / 2),
            anchor: side ? .leading : .trailing
        )
        // The angle's degrees inside its arc, on the line halfway between the axis and the arm.
        let half = Double(angle) / 2 * .pi / 180
        context.draw(
            Text("\(angle)°").font(Tokens.caption.font).foregroundStyle(Tokens.text2.color),
            at: CGPoint(x: centre.x + radius * 0.55 * cos(half), y: centre.y - radius * 0.55 * sin(half))
        )
        let right = CGPoint(x: centre.x + radius * 1.4, y: centre.y)
        context.draw(strong("cos \(angle)° = \(ratios.cosine)"), at: right, anchor: .bottomLeading)
        context.draw(strong("sin \(angle)° = \(ratios.sine)"), at: right, anchor: .topLeading)
    }
}
