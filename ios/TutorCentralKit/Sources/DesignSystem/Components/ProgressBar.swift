import SwiftUI

/// 4 high, lineStrong track, ok fill (or accent when it is not a status), radius 2; the value is said beside it by
/// the caller.
public struct ProgressBar: View {
    let fraction: Double
    let tone: StatusTone?
    static var height: CGFloat {
        4
    }

    public init(fraction: Double, tone: StatusTone? = .ok) {
        self.fraction = fraction
        self.tone = tone
    }

    public var body: some View {
        Capsule()
            .fill(Tokens.lineStrong.color)
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    Rectangle()
                        .fill((tone?.color ?? Tokens.accent).color)
                        .frame(width: geometry.size.width * min(max(fraction, 0), 1))
                }
            }
            .clipShape(.capsule)
            .frame(height: Self.height)
            .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}
