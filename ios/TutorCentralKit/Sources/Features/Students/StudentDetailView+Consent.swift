import DesignSystem
import SwiftUI

/// Consent on the student's page: its section, the ask, the record sheet and the withdrawal (P10-Consent-*,
/// P18-Consent-Change, -Withdraw, P18-Student-Withdrawn).
extension StudentDetailView {
    /// Consent waits under the parent while it asks something of the tutor (P10-Student-NotKnown, -Consent-Waiting,
    /// P18-Student-Withdrawn); agreed, it sits after the messages (P10-Student-End).
    var consentAgreed: Bool {
        if case .agreed = store.consent.state {
            true
        } else {
            false
        }
    }

    var consentSection: some View {
        ConsentSection(store: store.consent, ask: { asking = true }, agreed: { recordingConsent = true })
    }

    /// One sheet after the other: Parent withdrew closes the record sheet, then the withdrawal comes up.
    func openWithdrawalNext() {
        if withdrawNext {
            withdrawNext = false
            withdrawingConsent = true
        }
    }

    func consentSheets(_ content: some View) -> some View {
        content
            .sheet(isPresented: $asking) {
                ConsentAskSheet(store: store.consent) { asking = false }
                    .boardDetents(MessageSheet.boardFraction)
            }
            // One sheet after the other: Parent withdrew closes the record sheet, then the withdrawal comes up.
            .sheet(isPresented: $recordingConsent, onDismiss: openWithdrawalNext) {
                ConsentRecordSheet(
                    store: store.consent, close: { recordingConsent = false },
                    withdrew: {
                        withdrawNext = true
                        recordingConsent = false
                    }
                )
            }
            .sheet(isPresented: $withdrawingConsent) {
                ConsentWithdrawSheet(store: store.consent) { withdrawingConsent = false }
            }
            .onChange(of: store.consent.failure) { _, failure in
                guard let failure else { return }
                onMessage(failure)
                store.consent.failure = nil
            }
    }
}
