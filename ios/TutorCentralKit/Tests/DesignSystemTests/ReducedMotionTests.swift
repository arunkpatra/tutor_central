import SwiftUI
import Testing
@testable import DesignSystem

struct ReducedMotionTests {
    /// With Reduce Motion on, the app's own animations are none: the change lands at once.
    @Test func reducedMotionMeansNoAnimation() {
        #expect(ReducedMotion.animation(.default, reduce: true) == nil)
        #expect(ReducedMotion.animation(.easeOut, reduce: false) == .easeOut)
    }
}
