import SwiftUI
import Testing
@testable import AppShell

struct AppearanceTests {
    @Test func darkByDefault() {
        #expect(Appearance.resolve(arguments: [], stored: nil) == .dark)
        #expect(Appearance.resolve(arguments: [], stored: "sepia") == .dark)
    }

    @Test func aStoredChoiceWins() {
        #expect(Appearance.resolve(arguments: [], stored: "light") == .light)
        #expect(Appearance.resolve(arguments: [], stored: "system") == .system)
    }

    @Test func aLaunchArgumentWinsOverTheStoredChoice() {
        #expect(Appearance.resolve(arguments: ["app", "--appearance", "light"], stored: "dark") == .light)
        #expect(Appearance.resolve(arguments: ["app", "--appearance"], stored: "light") == .light)
    }

    @Test func colourSchemes() {
        #expect(Appearance.dark.colorScheme == .dark)
        #expect(Appearance.light.colorScheme == .light)
        #expect(Appearance.system.colorScheme == nil)
    }
}
