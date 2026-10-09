import Foundation
import Testing
@testable import DesignSystem

/// D49, U16: a toast never covers a footer. The footers on screen tell the centre their height; the toast lifts above
/// the newest one and comes back down when the last footer goes.
@MainActor struct ToastInsetTests {
    @Test func aToastSitsAboveAFooterWhileOneIsOnScreen() {
        #expect(ToastHost.bottom(base: Tokens.pageSide, footerInset: 0) == Tokens.pageSide)
        #expect(ToastHost.bottom(base: Tokens.pageSide, footerInset: 98) == Tokens.pageSide + 98 + Tokens.tileGap)
        #expect(ToastHost.bottom(base: 60, footerInset: 98) == 60 + 98 + Tokens.tileGap, "over a sheet's base as well")
    }

    @Test func theFooterInsetIsClearedWhenTheFooterGoes() {
        let toasts = ToastCenter()
        let footer = UUID()
        #expect(toasts.footerInset == 0)
        toasts.footerShown(footer, height: 98)
        #expect(toasts.footerInset == 98)
        toasts.footerGone(footer)
        #expect(toasts.footerInset == 0)
    }

    @Test func aPopLeavesTheRootsFooterInChargeWhicheverOrderTheEventsCome() {
        // Attendance's footer under a pushed screen with its own (Pending changes): popping back makes the root appear
        // and the pushed one disappear, in either order; the root's footer is the one on screen after.
        let toasts = ToastCenter()
        let root = UUID(), pushed = UUID()
        toasts.footerShown(root, height: 76)
        toasts.footerShown(pushed, height: 98)
        #expect(toasts.footerInset == 98)
        toasts.footerShown(root, height: 76)
        toasts.footerGone(pushed)
        #expect(toasts.footerInset == 76)
        toasts.footerShown(pushed, height: 98)
        toasts.footerGone(pushed)
        toasts.footerShown(root, height: 76)
        #expect(toasts.footerInset == 76)
        toasts.footerGone(root)
        #expect(toasts.footerInset == 0)
    }

    @Test func aToastOverASheetIsNotLiftedByAFooterTheSheetCovers() {
        // A FooterButton under a presented sheet never disappears, so it stays registered; the sheet's own host ignores
        // it (the sheet's own button is SheetToasts' aboveFooter) and the toast sits at its base.
        #expect(ToastHost.bottom(base: Tokens.pageSide, footerInset: 98, liftsOverFooters: false) == Tokens.pageSide)
        #expect(!SheetToasts.liftsOverFooters)
    }
}
