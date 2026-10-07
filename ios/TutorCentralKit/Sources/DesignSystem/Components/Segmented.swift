import SwiftUI

/// Track `well` with a line border and shadowWell (dark), radius 13, padding 3, items 2 apart; items 36 high, radius
/// 10, 14 600 text2; the active item buttonFill with shadowSegment and text 700. Selection haptic.
public struct Segmented<Option: Hashable>: View {
    let options: [(Option, String)]
    @Binding var selection: Option
    static var itemHeight: CGFloat {
        36
    }

    static var trackPadding: CGFloat {
        3
    }

    public init(options: [(Option, String)], selection: Binding<Option>) {
        self.options = options
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: Tokens.rowGapInner) {
            ForEach(options, id: \.0) { option, title in
                let active = option == selection
                Button {
                    guard !active else { return }
                    selection = option
                    Haptic.play(.selection)
                } label: {
                    Text(title)
                        .typeStyle(active ? Tokens.segmentActive : Tokens.segment)
                        .foregroundStyle((active ? Tokens.text : Tokens.text2).color)
                        .frame(maxWidth: .infinity, minHeight: Self.itemHeight)
                        .background {
                            if active {
                                RoundedRectangle(cornerRadius: Tokens.radiusSegment, style: .continuous)
                                    .fill(Tokens.buttonFill.color)
                                    .shadowed(Tokens.shadowSegment, radius: Tokens.radiusSegment)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(Self.trackPadding)
        .background(Tokens.well.color, in: .rect(cornerRadius: Tokens.radiusSegmentTrack, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Tokens.radiusSegmentTrack, style: .continuous)
                .strokeBorder(Tokens.line.color, lineWidth: Tokens.hairline)
        )
        .shadowed(Tokens.shadowWell, radius: Tokens.radiusSegmentTrack)
    }
}
