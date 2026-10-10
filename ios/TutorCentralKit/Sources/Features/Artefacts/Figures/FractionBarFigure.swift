import DesignSystem
import SwiftUI

/// A fraction bar (P10-Figure-FractionBar): "3 of 4 parts shaded", the bar in equal parts, "3/4 = 0.75".
struct FractionBarFigure: View {
    let parts: Int
    let shaded: Int
    let label: String

    var body: some View {
        VStack(spacing: Tokens.tileGap) {
            Text("\(shaded) of \(parts) parts shaded").typeStyle(Tokens.captionStrong)
                .foregroundStyle(Tokens.text.color)
            HStack(spacing: 0) {
                ForEach(0 ..< parts, id: \.self) { part in
                    Rectangle()
                        .fill((part < shaded ? Tokens.accent : Tokens.ground).color)
                        .overlay(Rectangle().stroke(Tokens.text2.color, lineWidth: FigureMeasure.stroke / 2))
                }
            }
            .frame(height: FigureMeasure.barHeight)
            .overlay(Rectangle().stroke(Tokens.text2.color, lineWidth: FigureMeasure.stroke))
            .padding(.horizontal, Tokens.rowPaddingHorizontal + Tokens.inline)
            Text("\(label) = \(FigureNumbers.decimal(Double(shaded) / Double(max(parts, 1))))")
                .typeStyle(Tokens.caption).foregroundStyle(Tokens.text2.color)
        }
        .padding(.vertical, Tokens.inline)
        .frame(maxWidth: .infinity)
    }
}
