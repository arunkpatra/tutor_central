import SwiftUI

/// Creating card (P6-Generating, P6-Scan-Reading, P6-Check-Checking): a card (padding 16, radiusCard) with the title
/// (rowHeading) and a quiet Cancel, four skeleton bars breathing, and a footnote line in text3; with a photo, its
/// thumbnail on the left. Without the bars it is the card of a read that found nothing or failed (P6-Scan-Nothing,
/// -Failed), the photo still beside it.
public struct CreatingCard: View {
    let title: String
    let line: String
    let thumbnail: UIImage?
    let working: Bool
    let cancel: (() -> Void)?
    @State private var dimmed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The bars' widths as fractions of the card: the board's 70, 90, 55 and 80 per cent.
    static var bars: [CGFloat] {
        [0.7, 0.9, 0.55, 0.8]
    }

    static var barHeight: CGFloat {
        12
    }

    static var thumbnailWidth: CGFloat {
        64
    }

    public init(title: String, line: String, thumbnail: UIImage? = nil, working: Bool = true, cancel: (() -> Void)?) {
        self.title = title
        self.line = line
        self.thumbnail = thumbnail
        self.working = working
        self.cancel = cancel
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Tokens.rowPaddingDense) {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: Self.thumbnailWidth, height: Self.thumbnailWidth * 4 / 3)
                    .clipShape(.rect(cornerRadius: Tokens.radiusSegment, style: .continuous))
                    .accessibilityHidden(true)
            }
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
                if working {
                    bars
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

    private var bars: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: Tokens.inline) {
                ForEach(Self.bars.indices, id: \.self) { index in
                    Capsule().frame(width: geometry.size.width * Self.bars[index], height: Self.barHeight)
                }
            }
        }
        .frame(height: CGFloat(Self.bars.count) * Self.barHeight + CGFloat(Self.bars.count - 1) * Tokens.inline)
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
            title: "Reading the register", line: "Usually under a minute.", thumbnail: UIImage(systemName: "doc")
        ) {}
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
