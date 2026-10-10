import SwiftUI

/// The shape of a list row while nothing is cached: a 40 circle, two bars and a trailing bar in surface2, breathing
/// from 1 to 0.55 over `breathe`, ease-in-out, repeating (still under reduced motion). `widths` are the two bars'
/// fractions of the middle column.
public struct SkeletonRow: View {
    let widths: (CGFloat, CGFloat)
    @State private var dimmed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    static var bar: CGFloat {
        14
    }

    static var thinBar: CGFloat {
        10
    }

    static var trailing: CGFloat {
        56
    }

    public init(widths: (CGFloat, CGFloat) = (0.55, 0.75)) {
        self.widths = widths
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Circle().frame(width: IconButton.size, height: IconButton.size)
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                    Capsule().frame(width: geometry.size.width * widths.0, height: Self.bar)
                    Capsule().frame(width: geometry.size.width * widths.1, height: Self.thinBar)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: IconButton.size)
            Capsule().frame(width: Self.trailing, height: Self.bar)
        }
        .foregroundStyle(Tokens.surface2.color)
        .padding(.vertical, Tokens.rowPaddingDense)
        .padding(.horizontal, Tokens.rowPaddingHorizontal)
        .opacity(dimmed && !reduceMotion ? Tokens.opacityStale : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: Tokens.breathe / 2).repeatForever(autoreverses: true)) { dimmed = true }
        }
        .accessibilityHidden(true)
    }
}

/// A value being refreshed: stale at 0.55 with a 16 pt spinner beside the section title (the caller places it).
public struct RefreshSpinner: View {
    public init() {}

    public var body: some View {
        ProgressView()
            .controlSize(.small)
            .tint(Tokens.accentText.color)
            .frame(width: Tokens.iconInline, height: Tokens.iconInline)
            .accessibilityLabel("Refreshing")
    }
}

/// The close card's wait (P12-Close-Cards): a 16 pt ring in `lineStrong` with a quarter arc in `text3` turning once a
/// `breathe`; still under Reduce Motion.
public struct RingSpinner: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var turning = false

    public init() {}

    public var body: some View {
        ZStack {
            Circle().stroke(Tokens.lineStrong.color, lineWidth: Tokens.hairline * 2)
            Circle().trim(from: 0, to: 0.25)
                .stroke(Tokens.text3.color, style: StrokeStyle(lineWidth: Tokens.hairline * 2, lineCap: .round))
                .rotationEffect(.degrees(turning ? 360 : 0))
        }
        .frame(width: Tokens.iconInline, height: Tokens.iconInline)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: Tokens.breathe / 2).repeatForever(autoreverses: false)) { turning = true }
        }
        .accessibilityHidden(true)
    }
}
