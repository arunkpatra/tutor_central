import SwiftUI

/// Creating card (P6-Generating; P6-Scan-Reading, P6-Check-Checking): a card (padding 16, radiusCard). Without a
/// photo: the title (rowHeading) with a quiet Cancel, four skeleton bars breathing, a footnote in text3. With one: the
/// photo (120 × 90, radius 8) beside the title and its line (footnote text2), three bars under them, and Cancel is the
/// screen's, under the card. Without the bars it is the card of a read that found nothing or failed (P6-Scan-Nothing,
/// -Failed), the photo still beside it.
public struct CreatingCard: View {
    let title: String
    let line: String
    let thumbnail: UIImage?
    let working: Bool
    let cancel: (() -> Void)?
    /// The 10.2 variant (components.md "Creating card with a photo", P10-Textbook-Reading): a 56 × 72 photo on the
    /// left,
    /// the title with Cancel, the bars and the line beside it.
    let portrait: Bool
    @State private var dimmed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The bars' widths as fractions of the card: the board's 70, 90, 55 and 80 per cent; 65, 85 and 50 beside a photo.
    static var bars: [CGFloat] {
        [0.7, 0.9, 0.55, 0.8]
    }

    static var photoBars: [CGFloat] {
        [0.65, 0.85, 0.5]
    }

    static var barHeight: CGFloat {
        12
    }

    static var thumbnailSize: CGSize {
        CGSize(width: 120, height: 90)
    }

    static var thumbnailRadius: CGFloat {
        8
    }

    static var titleGap: CGFloat {
        4
    }

    static var portraitSize: CGSize {
        CGSize(width: 56, height: 72)
    }

    public init(title: String, line: String, thumbnail: UIImage? = nil, working: Bool = true, cancel: (() -> Void)?) {
        self.title = title
        self.line = line
        self.thumbnail = thumbnail
        portrait = false
        self.working = working
        self.cancel = cancel
    }

    /// A reading with its photo beside it, as P10-Textbook-Reading draws it.
    public init(title: String, line: String, portrait thumbnail: UIImage?, cancel: @escaping () -> Void) {
        self.title = title
        self.line = line
        self.thumbnail = thumbnail
        working = true
        self.cancel = cancel
        portrait = true
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Tokens.tileGap) {
            if portrait {
                portraitLayout
            } else if let thumbnail {
                HStack(spacing: Tokens.cardPaddingCompact) {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: Self.thumbnailSize.width, height: Self.thumbnailSize.height)
                        .clipShape(.rect(cornerRadius: Self.thumbnailRadius, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Self.titleGap) {
                        Text(title).typeStyle(Tokens.rowHeading).foregroundStyle(Tokens.text.color)
                        Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
                if working {
                    bars(Self.photoBars)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Tokens.rowPaddingDense) {
                    Text(title)
                        .typeStyle(Tokens.rowHeading)
                        .foregroundStyle(Tokens.text.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let cancel {
                        Button("Cancel", action: cancel).buttonStyle(.quiet)
                    }
                }
                if working {
                    bars(Self.bars)
                }
                Text(line)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Tokens.rowPaddingHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(radius: Tokens.radiusCard)
    }

    private func bars(_ widths: [CGFloat]) -> some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: Tokens.inline) {
                ForEach(widths.indices, id: \.self) { index in
                    Capsule().frame(width: geometry.size.width * widths[index], height: Self.barHeight)
                }
            }
        }
        .frame(height: CGFloat(widths.count) * Self.barHeight + CGFloat(widths.count - 1) * Tokens.inline)
        .foregroundStyle(Tokens.surface2.color)
        .opacity(dimmed && !reduceMotion ? Tokens.opacityStale : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: Tokens.breathe / 2).repeatForever(autoreverses: true)) { dimmed = true }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Tokens.sectionGap) {
        CreatingCard(
            title: "Writing 10 questions on Quadratic equations",
            line: "Usually under a minute. You can wait here or come back from History."
        ) {}
        CreatingCard(
            title: "Reading the register", line: "Usually under a minute.", thumbnail: UIImage(systemName: "doc"),
            cancel: nil
        )
        CreatingCard(
            title: "No names found",
            line: "Nothing on this photo read as a name.",
            working: false,
            cancel: nil
        )
    }
    .padding(Tokens.pageSide)
    .background(Tokens.ground.color)
}

extension CreatingCard {
    var portraitLayout: some View {
        HStack(alignment: .top, spacing: Tokens.cardPaddingCompact) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail).resizable().scaledToFill()
                } else {
                    Tokens.surface2.color
                }
            }
            .frame(width: Self.portraitSize.width, height: Self.portraitSize.height)
            .clipShape(.rect(cornerRadius: Self.thumbnailRadius, style: .continuous))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Tokens.tileGap) {
                HStack(alignment: .firstTextBaseline, spacing: Tokens.rowPaddingDense) {
                    Text(title)
                        .typeStyle(Tokens.rowHeading)
                        .foregroundStyle(Tokens.text.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let cancel {
                        Button("Cancel", action: cancel).buttonStyle(.quiet)
                    }
                }
                bars(Self.photoBars)
                Text(line)
                    .typeStyle(Tokens.footnote)
                    .foregroundStyle(Tokens.text3.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
