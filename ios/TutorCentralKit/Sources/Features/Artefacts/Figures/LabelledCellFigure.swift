import DesignSystem
import Domain
import SwiftUI

/// A labelled cell (P10-Figure-Cell): a plant cell (the wall, the membrane, the nucleus, the vacuole, chloroplasts) or
/// an animal cell (the membrane, the nucleus, the cytoplasm), with the chapter's names down the right, each joined to
/// its part by a line; a name the drawing has no part for points into the cytoplasm.
struct LabelledCellFigure: View {
    enum Part: CaseIterable {
        case wall, membrane, nucleus, vacuole, chloroplast, cytoplasm

        /// The part a chapter's name means, by its words.
        static func named(_ label: String) -> Part {
            let name = label.lowercased()
            let words: [(Part, [String])] = [
                (.wall, ["wall"]), (.membrane, ["membrane"]), (.nucleus, ["nucleus", "nuclei"]),
                (.vacuole, ["vacuole"]), (.chloroplast, ["chloroplast"]),
            ]
            return words.first { _, words in words.contains { name.contains($0) } }?.0 ?? .cytoplasm
        }
    }

    let kind: FigureSpec.CellKind
    let labels: [String]

    var body: some View {
        Canvas { context, size in draw(in: &context, size: size) }
            .aspectRatio(FigureMeasure.squarish, contentMode: .fit)
            .padding(.vertical, Tokens.inline)
    }

    private func cell(_ size: CGSize) -> CGRect {
        let side = Tokens.rowPaddingDense
        return CGRect(x: side, y: side * 2, width: size.width * 0.56, height: size.height - side * 4)
    }

    private func anchor(_ part: Part, in cell: CGRect) -> CGPoint {
        let at = { (x: CGFloat, y: CGFloat) in CGPoint(x: cell.minX + cell.width * x, y: cell.minY + cell.height * y) }
        return switch part {
        case .wall: at(kind == .plant ? 1 : 0.98, 0.18)
        case .membrane: at(kind == .plant ? 0.95 : 0.98, kind == .plant ? 0.3 : 0.5)
        case .nucleus: at(0.28, 0.32)
        case .vacuole: at(0.62, 0.5)
        case .chloroplast: at(0.4, 0.8)
        case .cytoplasm: at(0.5, 0.72)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let body = cell(size)
        let inset = body.insetBy(dx: FigureMeasure.tick, dy: FigureMeasure.tick)
        if kind == .plant {
            let corner = FigureMeasure.corner * 2
            context.stroke(
                Path(roundedRect: body, cornerRadius: corner), with: .color(Tokens.text2.color),
                lineWidth: FigureMeasure.strokeStrong * 2
            )
            context.stroke(
                Path(roundedRect: inset, cornerRadius: corner * 0.7), with: .color(Tokens.text2.color),
                lineWidth: FigureMeasure.stroke
            )
            let vacuole = CGRect(
                x: body.minX + body.width * 0.44, y: body.minY + body.height * 0.3,
                width: body.width * 0.4, height: body.height * 0.4
            )
            context.fill(Path(ellipseIn: vacuole), with: .color(Tokens.surface2.color))
            context.stroke(
                Path(ellipseIn: vacuole),
                with: .color(Tokens.lineStrong.color),
                lineWidth: FigureMeasure.stroke
            )
            for spot in [CGPoint(x: 0.3, y: 0.76), CGPoint(x: 0.5, y: 0.82)] {
                let plastid = CGRect(
                    x: body.minX + body.width * spot.x - body.width * 0.08,
                    y: body.minY + body.height * spot.y - FigureMeasure.box * 0.11,
                    width: body.width * 0.16, height: FigureMeasure.box * 0.22
                )
                context.fill(Path(ellipseIn: plastid), with: .color(Tokens.okTint.color))
                context.stroke(Path(ellipseIn: plastid), with: .color(Tokens.ok.color), lineWidth: FigureMeasure.stroke)
            }
        } else {
            context.stroke(
                Path(ellipseIn: body),
                with: .color(Tokens.text2.color),
                lineWidth: FigureMeasure.strokeStrong
            )
        }
        let centre = anchor(.nucleus, in: body)
        let half = FigureMeasure.box / 4
        let nucleus = CGRect(x: centre.x - half, y: centre.y - half, width: half * 2, height: half * 2)
        context.stroke(
            Path(ellipseIn: nucleus),
            with: .color(Tokens.accent.color),
            lineWidth: FigureMeasure.strokeStrong
        )
        context.fill(
            Path(ellipseIn: nucleus.insetBy(dx: half * 0.68, dy: half * 0.68)), with: .color(Tokens.accent.color)
        )
        names(in: &context, size: size, cell: body)
    }

    /// The names down the right, evenly, each with its line to its part.
    private func names(in context: inout GraphicsContext, size: CGSize, cell: CGRect) {
        let left = cell.maxX + Tokens.rowPaddingDense * 1.5
        let step = cell.height / CGFloat(max(labels.count, 1))
        // Ordered by how high each part sits, so the lines do not cross.
        let ordered = labels.sorted { anchor(Part.named($0), in: cell).y < anchor(Part.named($1), in: cell).y }
        for (index, label) in ordered.enumerated() {
            let at = CGPoint(x: left + Tokens.inline, y: cell.minY + step * (CGFloat(index) + 0.5))
            var leader = Path()
            leader.move(to: anchor(Part.named(label), in: cell))
            leader.addLine(to: CGPoint(x: left, y: at.y))
            context.stroke(leader, with: .color(Tokens.text3.color), lineWidth: FigureMeasure.stroke / 2)
            context.draw(
                Text(label).font(Tokens.caption.font).foregroundStyle(Tokens.text2.color),
                at: at,
                anchor: .leading
            )
        }
    }
}
