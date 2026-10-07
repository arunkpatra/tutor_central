import AuthenticationServices
import Data
import DesignSystem
import Domain
import SwiftUI

/// The sign-in landing, to A-SignIn (dark) and P2-SignIn-Light: the logo and the promise, then Apple, Google and email,
/// and the legal line.
public struct SignInView: View {
    /// Where the legal line's two links go.
    public struct Legal: Sendable {
        let terms: URL
        let privacy: URL

        public init(terms: URL, privacy: URL) {
            self.terms = terms
            self.privacy = privacy
        }
    }

    private enum Route: Hashable {
        case code
    }

    @State private var store: SignInStore
    @State private var email: EmailSignInStore
    @State private var showsEmail: Bool
    @State private var path: [Route]
    @Environment(\.colorScheme) private var scheme
    private let boardState: Bool
    private let legal: Legal
    private let onSignedIn: (AuthUser) async -> Void
    private let onMessage: (String) -> Void
    static var logoSize: CGFloat {
        56
    }

    static var logoMark: CGFloat {
        30
    }

    static var leadWidth: CGFloat {
        320
    }

    public init(
        auth: any AuthRepository,
        legal: Legal,
        fixture: SignInFixture? = nil,
        onSignedIn: @escaping (AuthUser) async -> Void,
        onMessage: @escaping (String) -> Void
    ) {
        _store = State(initialValue: SignInStore(auth: auth))
        _email = State(initialValue: fixture
            .map { EmailSignInStore.fixture($0, auth: auth) } ?? EmailSignInStore(auth: auth))
        _showsEmail = State(initialValue: fixture == .email || fixture == .password)
        _path = State(initialValue: fixture == .code || fixture == .codeWrong ? [.code] : [])
        boardState = fixture != nil
        self.legal = legal
        self.onSignedIn = onSignedIn
        self.onMessage = onMessage
    }

    public var body: some View {
        NavigationStack(path: $path) {
            landing
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { _ in
                    CodeEntryView(store: email, boardState: boardState, onSignedIn: onSignedIn) {
                        path.removeAll()
                        email.useCode()
                    }
                }
        }
        .sheet(isPresented: $showsEmail) {
            EmailSignInSheet(store: email, boardState: boardState, onSignedIn: onSignedIn) { showsEmail = false }
        }
        .onChange(of: email.step) { _, step in
            if step == .code {
                showsEmail = false
                path = [.code]
            }
        }
    }

    private var landing: some View {
        VStack(alignment: .leading, spacing: 0) {
            logo
            promise.padding(.top, Tokens.heroLead)
            Spacer(minLength: Tokens.sectionGap)
            buttons
        }
        .padding(.top, Tokens.heroTop)
        .padding(.horizontal, Tokens.heroInset)
        .padding(.bottom, Tokens.pageSide)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { HeroGlow() }
        .background(Tokens.ground.color)
        .ignoresSafeArea(edges: .top)
        .onChange(of: store.message) { _, message in
            if let message {
                onMessage(message)
            }
        }
    }

    private var logo: some View {
        HStack(spacing: Tokens.cardPaddingCompact) {
            Image(systemName: "book")
                .font(.system(size: Self.logoMark, weight: .medium))
                .foregroundStyle(Tokens.textOnAccent.color)
                .frame(width: Self.logoSize, height: Self.logoSize)
                .background(Tokens.accent.color, in: .rect(cornerRadius: Tokens.radiusTile, style: .continuous))
                .shadowed(Tokens.shadowLogo, radius: Tokens.radiusTile)
                .accessibilityHidden(true)
            Text("Tutor Central").typeStyle(Tokens.wordmark).foregroundStyle(Tokens.text.color)
        }
    }

    private var promise: some View {
        VStack(alignment: .leading, spacing: Tokens.cardPaddingCompact) {
            Text("Teach more.\nChase less.")
                .typeStyle(Tokens.displayHero)
                .foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Text("Students, fees and attendance for your tuition centre, handled in a tap.")
                .typeStyle(Tokens.lead)
                .foregroundStyle(Tokens.text2.color)
                .frame(maxWidth: Self.leadWidth, alignment: .leading)
        }
    }

    private var buttons: some View {
        VStack(spacing: Tokens.tileGap) {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = store.startApple()
            } onCompletion: { result in
                Task {
                    if let user = await store.finishApple(result: result) {
                        await onSignedIn(user)
                    }
                }
            }
            .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
            .frame(height: ButtonSize.sheet.rawValue)
            .clipShape(.rect(cornerRadius: Tokens.radiusControl, style: .continuous))
            Button {
                Task {
                    if let user = await store.continueWithGoogle() {
                        await onSignedIn(user)
                    }
                }
            } label: {
                Label { Text("Continue with Google") } icon: { GoogleMark() }
            }
            .buttonStyle(.landing(loading: store.busy == .google))
            Button {
                showsEmail = true
            } label: {
                Label("Continue with email", systemImage: "envelope")
            }
            .buttonStyle(.landing())
            legalLine.padding(.top, Tokens.cardPaddingCompact)
        }
        .disabled(store.busy != nil)
    }

    private var legalLine: some View {
        Text(legalText)
            .typeStyle(Tokens.caption)
            .foregroundStyle(Tokens.text3.color)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .tint(Tokens.text2.color)
    }

    private var legalText: AttributedString {
        func link(_ words: String, _ url: URL) -> AttributedString {
            var part = AttributedString(words)
            part.link = url
            part.foregroundColor = Tokens.text2.color
            part.font = Tokens.captionStrong.font
            return part
        }
        return AttributedString("By continuing you agree to the ") + link("terms", legal.terms)
            + AttributedString(" and ") + link("privacy policy", legal.privacy) + AttributedString(".")
    }
}
