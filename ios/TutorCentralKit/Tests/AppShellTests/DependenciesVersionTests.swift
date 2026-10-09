import Testing
@testable import AppShell

struct DependenciesVersionTests {
    /// What Settings' About and Help show: the marketing version and the build, "1.0.0 (14)".
    @Test func theVersionIsTheMarketingVersionAndTheBuild() {
        #expect(Dependencies.version(from: ["CFBundleShortVersionString": "1.0.0", "CFBundleVersion": "14"])
            == "1.0.0 (14)")
        #expect(Dependencies.version(from: [:]) == "0 (0)")
    }
}
