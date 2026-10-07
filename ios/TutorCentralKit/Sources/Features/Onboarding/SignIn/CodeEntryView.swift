import DesignSystem
import Domain
import SwiftUI

/// Code entry, to P2-Email-Code and its wrong-code state: six wells, the line that says what happened, Sign in, and
/// the resend line with its cooldown.
struct CodeEntryView: View {
    @Bindable var store: EmailSignInStore
    let boardState: Bool
    let onSignedIn: (AuthUser) async -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.groupGap) {
            navigation
            VStack(alignment: .leading, spacing: Tokens.inline) {
                Text("Check your email")
                    .typeStyle(Tokens.title1)
                    .foregroundStyle(Tokens.text.color)
                    .accessibilityAddTraits(.isHeader)
                Text(sentLine).typeStyle(Tokens.subhead).foregroundStyle(Tokens.text2.color)
            }
            VStack(alignment: .leading, spacing: Tokens.tileGap) {
                CodeField(
                    code: $store.code,
                    isWrong: store.codeError != nil,
                    showsFocus: boardState,
                    autofocus: !boardState
                )
                if let error = store.codeError {
                    FieldMessage(error)
                } else {
                    Text("The code fills in by itself from the email on this phone.")
                        .typeStyle(Tokens.footnote)
                        .foregroundStyle(Tokens.text3.color)
                }
            }
            Button("Sign in", action: verify)
                .buttonStyle(.primary(.sheet, loading: store.busy))
                .disabled(store.code.count < EmailSignInStore.codeLength)
            resendLine
            Spacer(minLength: 0)
        }
        .padding(.top, Tokens.pageTop)
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.rowPaddingHorizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Tokens.ground.color)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: store.code) { _, code in
            if code.count == EmailSignInStore.codeLength {
                verify()
            }
        }
        .task {
            guard !boardState else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                store.tick()
            }
        }
    }

    private var navigation: some View {
        ZStack {
            Text("Enter your code").typeStyle(Tokens.headline).foregroundStyle(Tokens.text.color)
            HStack {
                IconButton(symbol: "chevron.left", label: "Back", action: onBack)
                Spacer()
            }
        }
    }

    private var sentLine: AttributedString {
        var address = AttributedString(store.sentTo?.string ?? store.email)
        address.foregroundColor = Tokens.text.color
        address.font = Tokens.buttonSecondary.font
        return AttributedString("We sent a six-digit code to ") + address
            + AttributedString(". It works for 10 minutes.")
    }

    private var resendLine: some View {
        HStack(spacing: Tokens.fieldGap) {
            Text("Didn't get it?").foregroundStyle(Tokens.text2.color)
            if store.resendAvailableIn > 0 {
                Text("Resend in \(Self.countdown(store.resendAvailableIn))").foregroundStyle(Tokens.text3.color)
            } else {
                Button("Resend the code") { Task { await store.resend() } }.buttonStyle(.quiet)
            }
        }
        .typeStyle(Tokens.subhead)
        .frame(maxWidth: .infinity)
    }

    /// 24 → "0:24", 60 → "1:00".
    static func countdown(_ seconds: Int) -> String {
        "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }

    private func verify() {
        Task {
            if let user = await store.verify() {
                await onSignedIn(user)
            }
        }
    }
}
