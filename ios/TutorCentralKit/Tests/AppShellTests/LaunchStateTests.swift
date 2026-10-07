import Testing
@testable import AppShell

struct LaunchStateTests {
    @Test func readsTheStateArgument() {
        #expect(LaunchState.fromArguments(["app", "--state", "kit"]) == .kit)
        #expect(LaunchState.fromArguments(["app", "--state", "kit-surfaces"]) == .kitSurfaces)
        #expect(LaunchState.fromArguments(["app"]) == nil)
        #expect(LaunchState.fromArguments(["app", "--state"]) == nil)
    }

    @Test func everyStateHasAKebabCaseNameForTheShotsTool() {
        for state in LaunchState.allCases {
            #expect(state.rawValue.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "-" }, "\(state.rawValue)")
        }
    }
}
