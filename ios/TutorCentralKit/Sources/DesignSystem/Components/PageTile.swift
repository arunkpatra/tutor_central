import SwiftUI

/// Page tile (P6-Check-Pages): a compact card (padding 10) with the page's thumbnail, "Page 1" in footnote text2,
/// and a 28 pt round remove mark (xmark) at its top right; two to a row.
public struct PageTile: View {
    let image: UIImage
    let number: Int
    let remove: () -> Void
    static var removeSize: CGFloat {
        28
    }

    static var removeSymbol: CGFloat {
        14
    }

    static var thumbnailHeight: CGFloat {
        96
    }

    public init(image: UIImage, number: Int, remove: @escaping () -> Void) {
        self.image = image
        self.number = number
        self.remove = remove
    }

    public var body: some View {
        VStack(spacing: Tokens.inline) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: Self.thumbnailHeight)
                .clipShape(.rect(cornerRadius: Tokens.radiusSegment, style: .continuous))
                .accessibilityHidden(true)
            Text("Page \(number)").typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
        }
        .padding(Tokens.tileGap)
        .surface(radius: Tokens.radiusTile)
        .overlay(alignment: .topTrailing) {
            Button(action: remove) {
                Image(systemName: "xmark")
                    .font(.system(size: Self.removeSymbol, weight: .semibold))
                    .foregroundStyle(Tokens.text2.color)
                    .frame(width: Self.removeSize, height: Self.removeSize)
                    .background(Tokens.surface2.color, in: .circle)
            }
            .pressable()
            .padding(Tokens.fieldGap)
            .accessibilityLabel("Remove page \(number)")
        }
    }
}

/// The Add a page tile: a dashed lineStrong border (radius 16), camera 22 and "Add a page" in accentText 600, at
/// least 150 high.
public struct AddPageTile: View {
    let action: () -> Void
    static var minHeight: CGFloat {
        150
    }

    static var dash: [CGFloat] {
        [4, 4]
    }

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: Tokens.inline) {
                Image(systemName: "camera").font(.system(size: Tokens.iconTab))
                Text("Add a page").typeStyle(Tokens.bodyStrong)
            }
            .foregroundStyle(Tokens.accentText.color)
            .frame(maxWidth: .infinity, minHeight: Self.minHeight)
            .overlay(
                RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                    .strokeBorder(
                        Tokens.lineStrong.color,
                        style: StrokeStyle(lineWidth: Tokens.hairline, dash: Self.dash)
                    )
            )
            .contentShape(.rect)
        }
        .pressable()
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Tokens.tileGap) {
        PageTile(image: UIImage(systemName: "doc.text") ?? UIImage(), number: 1) {}
        AddPageTile {}
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}
