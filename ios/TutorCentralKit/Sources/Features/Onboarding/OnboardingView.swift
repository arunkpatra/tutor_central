import Data
import DesignSystem
import Domain
import SwiftUI

/// Onboarding, to P2-Onboarding-Dark and -Light: your name, centre name, WhatsApp number (optional), then "Open my
/// centre", which makes the centre in one call.
public struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store: OnboardingStore
    @State private var topInset: CGFloat = 0
    private static let phoneField = "phone"
    private let boardState: Bool
    private let onCreated: (Workspace) -> Void
    private let onMessage: (String) -> Void

    /// `boardState` fills the board's sample and draws the centre field focused without the keyboard.
    public init(
        user: AuthUser,
        auth: any AuthRepository,
        centres: any CentreRepository,
        boardState: Bool = false,
        onCreated: @escaping (Workspace) -> Void,
        onMessage: @escaping (String) -> Void
    ) {
        let store = OnboardingStore(user: user, auth: auth, centres: centres)
        if boardState {
            store.centreName = "Bright Minds Tuition"
        }
        _store = State(initialValue: store)
        self.boardState = boardState
        self.onCreated = onCreated
        self.onMessage = onMessage
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Tokens.groupGap) {
                    heading
                    fields
                }
                .padding(.top, max(0, Tokens.heroTop - topInset))
                .padding(.horizontal, Tokens.pageSide)
            }
            .scrollDismissesKeyboard(.interactively)
            // Clipped to the safe area, so the form never scrolls under the clock.
            .clipped()
            .safeAreaInset(edge: .bottom) { footer }
            .onChange(of: store.phoneError) { _, error in
                // The refusal is said in words under the field; bring it above the footer and keyboard.
                if error != nil {
                    withAnimation(ReducedMotion.animation(.default, reduce: reduceMotion)) {
                        proxy.scrollTo(Self.phoneField, anchor: .center)
                    }
                }
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .background { HeroGlow(soft: true) }
        .background(Tokens.ground.color)
        .onChange(of: store.message) { _, message in
            if let message {
                onMessage(message)
            }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: Tokens.tileGap) {
            Eyebrow("Welcome", accent: true)
            Text("Tell us about your centre")
                .typeStyle(Tokens.display)
                .foregroundStyle(Tokens.text.color)
                .accessibilityAddTraits(.isHeader)
            Text("Three things, and you're in. Everything can be changed later in Settings.")
                .typeStyle(Tokens.intro)
                .foregroundStyle(Tokens.text2.color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: Tokens.rowPaddingHorizontal) {
            TextWell(label: "Your name", text: $store.displayName, content: .name)
            TextWell(
                label: "Centre name",
                text: $store.centreName,
                helper: "Parents see this name on receipts and reminders.",
                content: .organizationName,
                showsFocus: boardState
            )
            PhoneWell(
                label: "Your WhatsApp number",
                digits: $store.digits,
                optional: true,
                helper: "So a parent can reply to you. You can add your UPI id for fees later.",
                error: store.phoneError
            )
            .id(Self.phoneField)
        }
    }

    private var footer: some View {
        VStack(spacing: Tokens.rowPaddingDense) {
            Button("Open my centre", action: submit)
                .buttonStyle(.primary(.sheet, loading: store.busy))
                .disabled(!store.canSubmit)
            HStack(spacing: 0) {
                Text("Signed in as \(store.signedInAs) · ")
                    .foregroundStyle(Tokens.text3.color)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button("Not you?") { Task { await store.notYou() } }
                    .buttonStyle(.plain)
                    .foregroundStyle(Tokens.text2.color)
                    .typeStyle(Tokens.captionStrong)
            }
            .typeStyle(Tokens.caption)
        }
        .padding(.horizontal, Tokens.pageSide)
        .padding(.bottom, Tokens.rowPaddingHorizontal)
    }

    private func submit() {
        Task {
            if let workspace = await store.submit() {
                onCreated(workspace)
            }
        }
    }
}
