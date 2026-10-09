import DesignSystem
import Domain
import SwiftUI

/// The email sheet, to P2-Email-Request and P2-Email-Password: request a code, or sign in with a password. A code sent
/// closes the sheet and the landing pushes code entry (P2-Email-Code is a full screen).
struct EmailSignInSheet: View {
    @Bindable var store: EmailSignInStore
    let boardState: Bool
    let onSignedIn: (AuthUser) async -> Void
    let onClose: () -> Void
    var body: some View {
        FittedSheet(spacing: Tokens.sectionGap, bottom: Tokens.rowPaddingHorizontal) {
            SheetHeader(
                title: store.step == .password ? "Sign in with password" : "Sign in with email",
                cancel: ("Cancel", onClose)
            )
        } content: {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                if store.step == .password {
                    password
                } else {
                    request
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Tokens.radiusSheet)
        .presentationBackground(Tokens.surface1.color)
    }

    @ViewBuilder
    private var request: some View {
        Text("We'll email you a six-digit code. No password to remember.")
            .typeStyle(Tokens.subhead)
            .foregroundStyle(Tokens.text2.color)
            .fixedSize(horizontal: false, vertical: true)
        emailField
        Button {
            Task { await store.requestCode() }
        } label: {
            Label("Email me a code", systemImage: "envelope")
        }
        .buttonStyle(.primary(.sheet, loading: store.busy))
        Button("Use my password instead") { store.usePassword() }
            .buttonStyle(.quiet(.row))
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var password: some View {
        Text("For an account that set a password in Settings. Otherwise a code is quicker.")
            .typeStyle(Tokens.subhead)
            .foregroundStyle(Tokens.text2.color)
            .fixedSize(horizontal: false, vertical: true)
        emailField
        SecureWell(
            label: "Password",
            text: $store.password,
            error: store.passwordError,
            showsFocus: boardState,
            autofocus: !boardState,
            onCommit: signInWithPassword
        )
        Button("Sign in", action: signInWithPassword).buttonStyle(.primary(.sheet, loading: store.busy))
        Button("Email me a code instead") { store.useCode() }
            .buttonStyle(.quiet(.row))
            .frame(maxWidth: .infinity)
    }

    private var emailField: some View {
        let requesting = store.step != .password
        return TextWell(
            label: "Email address",
            text: $store.email,
            error: store.emailError,
            keyboard: .emailAddress,
            content: requesting ? .emailAddress : .username,
            capitalisation: .never,
            showsFocus: boardState && requesting,
            autofocus: !boardState && requesting,
            onCommit: {
                if requesting {
                    Task { await store.requestCode() }
                }
            }
        )
    }

    private func signInWithPassword() {
        Task {
            if let user = await store.signInWithPassword() {
                await onSignedIn(user)
            }
        }
    }
}
