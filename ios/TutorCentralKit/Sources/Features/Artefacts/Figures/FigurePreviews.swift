import Data
import DesignSystem
import Domain
import SwiftUI

/// The seven figure templates as the Kit shows them (P10-Kit's "Figure templates"; spec section 9: a figure kind needs
/// its validator and a preview in the Kit): the samples' specs, each drawn by `FigureView` at a card's full width, so
/// its labels keep the size the app draws them at.
public enum FigurePreviews {
    /// One spec per template, in the templates' order, each passing its rule.
    public static let specs: [FigureSpec] = FigureSpec.Kind.allCases.map { AISamples.figure($0).figure }

    @MainActor public static var grid: some View {
        VStack(spacing: Tokens.tileGap) {
            ForEach(Array(specs.enumerated()), id: \.offset) { _, spec in
                Card {
                    VStack(spacing: Tokens.inline) {
                        FigureView(spec: spec)
                        Text(FigureView.title(spec.kind)).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    }
                    .padding(Tokens.cardPaddingCompact)
                }
            }
        }
    }
}
