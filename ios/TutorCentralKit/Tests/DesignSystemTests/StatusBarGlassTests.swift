import Testing
@testable import DesignSystem

struct StatusBarGlassTests {
    @Test func theGlassShowsOnceTheContentHasScrolled() {
        #expect(StatusBarGlass.opacity(forOffset: 0) == 0 && StatusBarGlass.opacity(forOffset: -20) == 0)
        #expect(StatusBarGlass.opacity(forOffset: 1) == 1 && StatusBarGlass.opacity(forOffset: 300) == 1)
        #expect(StatusBarGlass.opacity(forOffset: 0.5) == 0.5, "a short fade between")
    }
}
