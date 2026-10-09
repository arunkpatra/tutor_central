import DesignSystem
import SwiftUI

/// Set a password (P7-Account-Password, -Failed): a floating sheet (D28) with one secure field, the helper, and Set
/// password, disabled until 8 characters. A failed write shows its words under the field and the button tries again.
/// The store is the caller's, kept in `@State` there, so a re-render never loses what was typed.
struct PasswordSheet: View {
    @Bindable var store: PasswordStore
    /// A board draws the focus ring without a keyboard; real use raises the keyboard.
    let showsFocus: Bool
    let autofocus: Bool
    let done: () -> Void
    let close: () -> Void
    /// The board's sheet starts 512 pt down an 852 pt screen.
    static let boardFraction = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.sectionGap) {
            SheetHeader(title: store.title, cancel: ("Cancel", close))
            SecureWell(
                label: "New password", text: $store.password, placeholder: "8 characters or more",
                helper: "At least 8 characters. You can still sign in with a code; the password is another way in.",
                error: store.error, showsFocus: showsFocus, autofocus: autofocus,
                onCommit: submit
            )
            Spacer(minLength: 0)
            Button("Set password", action: submit)
                .buttonStyle(.primary(.sheet, loading: store.busy))
                .disabled(!store.canSubmit)
        }
        .padding(.top, Tokens.inline)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.groupGap)
        .boardDetents(Self.boardFraction)
        .onChange(of: store.error) { _, error in
            if error != nil {
                Haptic.play(.error)
            }
        }
    }

    private func submit() {
        Task {
            Keyboard.dismiss()
            if await store.submit() {
                done()
            }
        }
    }
}
