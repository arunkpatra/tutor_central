import DesignSystem
import Testing
@testable import AppShell

@MainActor struct ToastCenterTests {
    @Test func oneAtATimeTheNewerWins() {
        let toasts = ToastCenter()
        toasts.show("first")
        toasts.show("second")
        #expect(toasts.current?.message == "second")
        toasts.dismiss()
        #expect(toasts.current == nil)
    }

    @Test func aToastWithUndoStaysLonger() {
        #expect(ToastCenter.stay(hasAction: false) == .seconds(Tokens.toastStay))
        #expect(ToastCenter.stay(hasAction: true) == .seconds(Tokens.toastStayUndo))
    }
}
