import SwiftMath
import UIKit

/// A formula drawn into an image (D102). The one place DesignSystem reaches into UIKit for drawing (D8's rule is
/// SwiftUI only): SwiftMath lays out LaTeX with Core Text and draws into a `UIGraphicsImageRenderer`; SwiftUI then
/// shows the image inline (`MathText`). The face is XITS Math (SwiftMath's bundled OFL font), the family of the PDF's
/// STIX Two Math. A formula that does not parse draws nothing (nil), so the text is shown as written.
public enum MathRenderer {
    /// The image and how far it hangs under the baseline, to sit on the text's line.
    public struct Rendered: @unchecked Sendable {
        public let image: UIImage
        public let descent: CGFloat
    }

    @MainActor public static func image(latex: String, pointSize: CGFloat, color: UIColor, display: Bool) -> UIImage? {
        rendered(latex: latex, pointSize: pointSize, color: color, display: display)?.image
    }

    @MainActor public static func rendered(
        latex: String,
        pointSize: CGFloat,
        color: UIColor,
        display: Bool
    ) -> Rendered? {
        var math = MathImage(
            latex: latex,
            fontSize: pointSize,
            textColor: color,
            labelMode: display ? .display : .text,
            textAlignment: .left
        )
        math.font = .xitsFont
        let (error, image, layout) = math.asImage()
        guard error == nil, let image, image.size.width > 0 else { return nil }
        return Rendered(image: image, descent: layout?.descent ?? 0)
    }

    /// The formula at `pointSize`, drawn smaller when it is wider than `width`, so at the largest text sizes it fits
    /// its line instead of being cut off.
    @MainActor public static func rendered(
        latex: String,
        pointSize: CGFloat,
        color: UIColor,
        display: Bool,
        fitting width: CGFloat
    ) -> Rendered? {
        guard let drawn = rendered(latex: latex, pointSize: pointSize, color: color, display: display) else {
            return nil
        }
        guard width.isFinite, width > 0, drawn.image.size.width > width else { return drawn }
        var size = pointSize * width / drawn.image.size.width
        while size > 1, let smaller = rendered(latex: latex, pointSize: size, color: color, display: display) {
            if smaller.image.size.width <= width {
                return smaller
            }
            size *= 0.95
        }
        return drawn
    }
}
