import Data

/// The sign-in states `bun shots` opens (AppShell maps its launch states here): the email sheet, code entry with and
/// without the wrong-code line, the password sheet.
public enum SignInFixture: Sendable {
    case email
    case code
    case codeWrong
    case password
}

extension EmailSignInStore {
    /// The store as each board draws it, with Meera's address.
    static func fixture(_ fixture: SignInFixture, auth: any AuthRepository) -> EmailSignInStore {
        let store = EmailSignInStore(auth: auth)
        store.email = "meera.nair@gmail.com"
        switch fixture {
        case .email: break
        case .code: store.preset(step: .code, code: "481", resendIn: 24, codeError: nil)
        case .codeWrong:
            store.preset(step: .code, code: "", resendIn: 0, codeError: EmailSignInStore.codeWords(.wrongCode))
        case .password:
            store.usePassword()
            store.password = "correcthorse"
        }
        return store
    }
}
