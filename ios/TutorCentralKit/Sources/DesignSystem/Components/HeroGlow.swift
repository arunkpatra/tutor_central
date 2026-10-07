import SwiftUI

/// The radial glow of the landing boards, as CSS draws `radial-gradient(460px 380px at 90% -8%, glow, transparent
/// 70%)`: an ellipse with radii 460 × 380 centred 90% across and 8% above the top of the screen, glowHero (glowHeroSoft
/// behind onboarding) at its centre fading to nothing at 70% of its radii.
public struct HeroGlow: View {
    let soft: Bool
    static var radii: CGSize {
        CGSize(width: 460, height: 380)
    }

    static var centre: UnitPoint {
        UnitPoint(x: 0.9, y: -0.08)
    }

    static var fade: CGFloat {
        0.7
    }

    public init(soft: Bool = false) {
        self.soft = soft
    }

    public var body: some View {
        GeometryReader { geometry in
            let colour = (soft ? Tokens.glowHeroSoft : Tokens.glowHero).color
            // A circle of the horizontal radius, squashed to the vertical one: an ellipse 460 × 380.
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [colour, colour.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: Self.radii.width * Self.fade
                    )
                )
                .frame(width: Self.radii.width * 2, height: Self.radii.width * 2)
                .scaleEffect(x: 1, y: Self.radii.height / Self.radii.width)
                .position(x: geometry.size.width * Self.centre.x, y: geometry.size.height * Self.centre.y)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
