import DesignSystem
import SwiftUI

/// A food chain (P10-Figure-FoodChain): who eats whom, each link a box, the arrow pointing to the eater; "Producer →
/// consumers" under it.
struct FoodChainFigure: View {
    let links: [String]

    var body: some View {
        VStack(spacing: Tokens.tileGap) {
            Text("Who eats whom: the arrow points to the eater").typeStyle(Tokens.captionStrong)
                .foregroundStyle(Tokens.text.color).multilineTextAlignment(.center)
            // One row while it fits; else two, the arrow carried to the second.
            ViewThatFits(in: .horizontal) {
                row(Array(links.enumerated()))
                VStack(spacing: Tokens.inline) {
                    let half = (links.count + 1) / 2
                    row(Array(links.enumerated().prefix(half)))
                    row(Array(links.enumerated().dropFirst(half)), arrowFirst: true)
                }
            }
            Text("Producer → consumers").typeStyle(Tokens.caption).foregroundStyle(Tokens.text2.color)
        }
        .padding(.vertical, Tokens.inline)
        .frame(maxWidth: .infinity)
    }

    private func row(_ part: [(offset: Int, element: String)], arrowFirst: Bool = false) -> some View {
        HStack(spacing: Tokens.rowGapInner) {
            ForEach(part, id: \.offset) { index, link in
                if index > 0, arrowFirst || index != part.first?.offset {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(Tokens.caption.font).imageScale(.small)
                        .foregroundStyle(Tokens.accent.color)
                }
                Text(link).typeStyle(Tokens.caption).foregroundStyle(Tokens.text.color)
                    .lineLimit(1).fixedSize()
                    .padding(.horizontal, Tokens.inline)
                    .frame(minHeight: FigureMeasure.box / 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: FigureMeasure.corner, style: .continuous)
                            .stroke(Tokens.text2.color, lineWidth: FigureMeasure.stroke)
                    )
            }
        }
    }
}
