import SwiftUI
import UIKit

/// Source well (components.md 10.5): what the school sent as it came, under its label: the text in a well at most
/// `collapsedHeight` high (`rowLine` `text2`), or the photo; on the item's page it is drawn expanded.
public struct SourceWell: View {
    let label: String
    let text: String?
    let image: UIImage?
    let collapsedHeight: CGFloat?
    let footnote: String?

    /// `collapsedHeight` nil draws the whole text (the item's page).
    public init(
        label: String,
        text: String?,
        image: UIImage?,
        collapsedHeight: CGFloat? = 96,
        footnote: String? = nil
    ) {
        self.label = label
        self.text = text
        self.image = image
        self.collapsedHeight = collapsedHeight
        self.footnote = footnote
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            VStack(alignment: .leading, spacing: Tokens.tileGap) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: collapsedHeight.map { $0 * 2 })
                        .clipShape(.rect(cornerRadius: Tokens.radiusControl, style: .continuous))
                        .accessibilityLabel("The photo the school sent")
                }
                if let text {
                    Text(text)
                        .typeStyle(Tokens.rowLine)
                        .foregroundStyle(Tokens.text2.color)
                        .frame(maxWidth: .infinity, maxHeight: collapsedHeight, alignment: .topLeading)
                        .clipped()
                        .textSelection(.enabled)
                }
                if let footnote {
                    Text(footnote).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
                }
            }
            .padding(Tokens.cardPaddingCompact)
            .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                    .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
            )
            .shadowed(Tokens.shadowWell, radius: Tokens.radiusControl)
        }
    }
}

#Preview {
    SourceWell(
        label: "What the school sent",
        text: "Dear Parents, Science Unit Test 3 for Class 8 will be held on Friday 16th Oct. Portions: Ch 1, Ch 2.",
        image: nil
    )
    .padding()
    .background(Tokens.ground.color)
}
