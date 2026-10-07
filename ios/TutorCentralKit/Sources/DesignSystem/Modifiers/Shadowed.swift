import SwiftUI

/// Draws a shadow token on a rounded shape of `radius`. Drop layers are drawn behind the shape and cut out of its
/// interior, as CSS draws a box-shadow, so translucent surfaces show no shadow through them. An inset layer with no
/// blur (the raised highlight) is a 1 pt stroke along the inside of the top edge (D25, components.md); an inset with a
/// blur (a well, a pressed button) is an inner shadow inside the shape.
struct Shadowed: ViewModifier {
    let token: ShadowToken
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let parsed = ShadowToken.parse(scheme == .dark ? token.dark : token.light)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content
            .background {
                ZStack {
                    // As CSS draws a box-shadow: the shape grown by the spread, filled with the colour, blurred,
                    // offset.
                    ForEach(Array(parsed.drops.enumerated()), id: \.offset) { _, layer in
                        shape
                            .fill(layer.color.swiftUI)
                            .padding(-layer.spread)
                            .blur(radius: layer.blur / 2)
                            .offset(x: layer.x, y: layer.y)
                    }
                }
                .mask {
                    Rectangle()
                        .padding(-Self.reach)
                        .overlay { shape.blendMode(.destinationOut) }
                        .compositingGroup()
                }
                .allowsHitTesting(false)
            }
            .overlay {
                if let inset = parsed.inset {
                    InsetLayer(layer: inset, shape: shape)
                }
            }
    }

    /// How far outside the shape a shadow may reach: the largest blur and offset in the document is 64 + 24.
    private static let reach: CGFloat = 100
}

private struct InsetLayer: View {
    let layer: ShadowLayer
    let shape: RoundedRectangle

    var body: some View {
        if layer.blur == 0 {
            // Inside the 1 pt border, as CSS draws an inset shadow inside the border box, fading out down the
            // corners.
            shape
                .inset(by: Tokens.hairline)
                .strokeBorder(layer.color.swiftUI, lineWidth: layer.y)
                .mask(alignment: .top) {
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: layer.y + shape.cornerSize.height)
                }
                .allowsHitTesting(false)
        } else {
            shape
                .stroke(layer.color.swiftUI, lineWidth: layer.blur * 2)
                .offset(x: layer.x, y: layer.y)
                .blur(radius: layer.blur / 2)
                .mask(shape)
                .allowsHitTesting(false)
        }
    }
}

extension RGBA {
    var swiftUI: Color {
        Color(uiColor: uiColor)
    }
}

public extension View {
    /// A shadow token on a rounded shape of `radius` (the shape of the view it is applied to).
    func shadowed(_ token: ShadowToken, radius: CGFloat) -> some View {
        modifier(Shadowed(token: token, radius: radius))
    }

    /// Several tokens at once, as CSS lists them (a well that is also focused: shadowWell and haloFocus).
    func shadowed(_ tokens: [ShadowToken], radius: CGFloat) -> some View {
        tokens.reduce(AnyView(self)) { view, token in AnyView(view.shadowed(token, radius: radius)) }
    }
}
