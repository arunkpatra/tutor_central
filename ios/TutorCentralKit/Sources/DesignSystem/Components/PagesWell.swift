import SwiftUI
import UIKit

/// The pages of a photo under its label (P14-Marks-Reading, -Confirm): a well with the first page's thumbnail, what was
/// taken ("1 page · a report card is one page, …", "1 page read") and Add a page while another is allowed.
public struct PagesWell: View {
    let label: String
    let image: UIImage?
    let line: String
    let addPage: (() -> Void)?
    static var thumbnail: CGSize {
        CGSize(width: 56, height: 72)
    }

    public init(label: String, image: UIImage?, line: String, addPage: (() -> Void)?) {
        self.label = label
        self.image = image
        self.line = line
        self.addPage = addPage
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.fieldGap) {
            Text(label).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
            HStack(alignment: .center, spacing: Tokens.rowPaddingDense) {
                thumbnail
                VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                    Text(line).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
                        .fixedSize(horizontal: false, vertical: true)
                    if let addPage {
                        Button("Add a page", action: addPage).buttonStyle(.quiet(emphasised: true))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(Tokens.cardPaddingCompact)
            .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusControl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radiusControl, style: .continuous)
                    .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
            )
        }
    }

    @ViewBuilder private var thumbnail: some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.radiusSegment / 2, style: .continuous)
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                VStack(alignment: .leading, spacing: Tokens.rowGapInner * 2) {
                    ForEach([0.8, 0.6, 0.8, 0.7, 0.8, 0.5], id: \.self) { width in
                        Capsule().fill(Tokens.lineStrong.color)
                            .frame(width: Self.thumbnail.width * 0.7 * width, height: Tokens.hairline * 3)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Tokens.surface2.color)
            }
        }
        .frame(width: Self.thumbnail.width, height: Self.thumbnail.height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline))
        .accessibilityLabel("The photo")
    }
}
