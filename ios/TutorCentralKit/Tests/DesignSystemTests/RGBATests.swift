import Testing
@testable import DesignSystem

struct RGBATests {
    @Test func parsesHex() throws {
        let c = try #require(RGBA(css: "#131110"))
        #expect(c == RGBA(red: 0x13, green: 0x11, blue: 0x10, alpha: 1))
    }

    @Test func parsesRGBAWithAFractionalAlpha() throws {
        let c = try #require(RGBA(css: "rgba(28,25,23,.74)"))
        #expect(c.red == 28 && c.green == 25 && c.blue == 23)
        #expect(abs(c.alpha - 0.74) < 0.001)
    }

    @Test func refusesAnythingElse() {
        #expect(RGBA(css: "text2") == nil)
        #expect(RGBA(css: "#12") == nil)
        #expect(RGBA(css: "rgb(1,2,3)") == nil)
    }

    @Test func writesItselfBackTheWayTheDocumentWritesIt() throws {
        #expect(try #require(RGBA(css: "#F8F4EE")).css == "#F8F4EE")
        #expect(try #require(RGBA(css: "rgba(255,171,56,.14)")).css == "rgba(255,171,56,.14)")
        #expect(try #require(RGBA(css: "rgba(8,6,5,.6)")).css == "rgba(8,6,5,.6)")
    }
}
