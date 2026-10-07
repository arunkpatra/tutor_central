import SwiftUI

/// Draws shadow tokens on a rounded shape of `radius`. Drop layers are drawn behind the shape and cut out of its
/// interior, as CSS draws a box-shadow, so translucent surfaces show no shadow through them. An inset layer with no
/// blur (the raised highlight) is a 1 pt stroke along the inside of the top edge (D25, components.md); an inset with a
/// blur (a well, a pressed button) is an inner shadow inside the border. Any number of tokens draw through one fixed
/// structure, so a view that gains a token (a well that takes focus) keeps its identity and its text field.
struct Shadowed: ViewModifier {
    let tokens: [ShadowToken]
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let parsed = tokens.map { ShadowToken.parse(scheme == .dark ? $0.dark : $0.light) }
        let drops = parsed.flatMap(\.drops)
        let insets = parsed.compactMap(\.inset)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content
            .background {
                // As CSS draws a box-shadow: the shape grown by the spread, filled with the colour, blurred, offset.
                ZStack {
                    ForEach(Array(drops.enumerated()), id: \.offset) { _, layer in
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
                ZStack {
                    ForEach(Array(insets.enumerated()), id: \.offset) { _, layer in
                        InsetLayer(layer: layer, shape: shape)
                    }
                }
                .allowsHitTesting(false)
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
                .inset(by: Tokens.hairline)
                .stroke(layer.color.swiftUI, lineWidth: layer.blur * 2)
                .offset(x: layer.x, y: layer.y)
                .blur(radius: layer.blur / 2)
                .mask(shape.inset(by: Tokens.hairline))
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
        modifier(Shadowed(tokens: [token], radius: radius))
    }

    /// Several tokens at once, as CSS lists them (a well that is also focused: shadowWell and haloFocus), or none.
    func shadowed(_ tokens: [ShadowToken], radius: CGFloat) -> some View {
        modifier(Shadowed(tokens: tokens, radius: radius))
    }
}
