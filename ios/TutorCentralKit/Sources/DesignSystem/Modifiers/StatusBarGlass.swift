import SwiftUI

/// U1: a tab root with a hidden navigation bar draws the system's glass under the status bar once its content has
/// scrolled, so content never runs bare under the clock (components.md, "Status bar on a scrolled root").
public enum StatusBarGlass {
    /// 0 at rest, 1 once the content has moved a point; a short fade between.
    public static func opacity(forOffset offset: CGFloat) -> Double {
        Double(min(max(offset, 0), 1))
    }
}

private struct StatusBarGlassModifier: ViewModifier {
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, now in
                offset = now
            }
            .overlay(alignment: .top) {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.bar)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Tokens.lineGlass.color).frame(height: Tokens.hairline)
                        }
                        .frame(height: geometry.safeAreaInsets.top)
                        .ignoresSafeArea(edges: .top)
                        .opacity(StatusBarGlass.opacity(forOffset: offset))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }
}

public extension View {
    /// On the `ScrollView` of a tab root whose navigation bar is hidden (Today, Students, Attendance, More).
    func statusBarGlass() -> some View {
        modifier(StatusBarGlassModifier())
    }
}
