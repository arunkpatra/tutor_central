import DesignSystem
import Domain
import SwiftUI

/// What the boards set up on the page: a confirmation, the edit sheet, the consent sheets, the record or the end.
extension StudentDetailView {
    enum Anchor: Hashable {
        case record, end
    }

    /// The scrolled boards: the record (its current chapter open) or the end.
    func scrollForBoard(_ reader: ScrollViewProxy) async {
        guard boardState == .record || boardState == .end, store.recordLoaded else { return }
        if boardState == .record {
            store.openCurrentChapter()
        }
        try? await Task.sleep(for: .seconds(Tokens.panel))
        reader.scrollTo(boardState == .record ? Anchor.record : Anchor.end, anchor: .top)
    }

    func setUpBoardState() {
        switch boardState {
        case .archiveConfirm: confirming = .archive
        case .deleteConfirm: confirming = .delete
        case .edit: edit()
        case .consentAsk: asking = true
        case .consentRecord: recordingConsent = true
        case .record, .end, nil: break
        }
    }
}
