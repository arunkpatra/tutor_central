import DesignSystem
import Domain
import SwiftUI

/// What the boards set up on the page: a confirmation, the edit sheet, the consent sheets, the record or the end.
extension StudentDetailView {
    enum Anchor: Hashable {
        case record, end, marks, export
    }

    /// The scrolled boards: the record (its current chapter open) or the end.
    func scrollForBoard(_ reader: ScrollViewProxy) async {
        guard [.record, .end, .marks, .export].contains(boardState), store.recordLoaded else { return }
        if boardState == .record {
            store.openCurrentChapter()
        }
        try? await Task.sleep(for: .seconds(Tokens.panel))
        let anchor: Anchor = switch boardState {
        case .record: .record
        case .marks: .marks
        case .export: .export
        default: .end
        }
        // The export's boards end at Archive and Delete (P18-Export-*).
        reader.scrollTo(anchor, anchor: anchor == .export ? .bottom : .top)
    }

    func setUpBoardState() {
        switch boardState {
        case .archiveConfirm: confirming = .archive
        case .deleteConfirm: confirming = .delete
        case .edit: edit()
        case .consentAsk: asking = true
        case .consentRecord: recordingConsent = true
        case .consentWithdraw:
            // P18-Consent-Withdraw draws a withdrawal on a call.
            store.consent.withdrawSheet.how = .call
            withdrawingConsent = true
        case .nextStep: choosingStep = true
        case .tellParent: tellingParent = store.student.flatMap { student in makeTellParent?(student.id) }
        case .record, .end, .marks, .export, nil: break
        }
    }
}
