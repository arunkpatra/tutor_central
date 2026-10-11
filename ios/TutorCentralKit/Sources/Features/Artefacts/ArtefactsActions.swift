import Domain
import Foundation

/// Where an artefact's screen leads; AppShell supplies it (a feature never imports another). Back is the screen's own
/// dismiss, as History's.
public struct ArtefactsActions {
    let openArtefact: (UUID) -> Void
    /// A mock's Mark from a photo: Check a paper for the student with the mock's key.
    let markPaper: ((MockMark) -> Void)?
    /// A gap report's Change: Today at the batch's plan; Use this plan: the student's plan made again.
    let gapReport: GapReportActions
    let gapUsed: ((UUID) -> Void)?

    public init(
        openArtefact: @escaping (UUID) -> Void, markPaper: ((MockMark) -> Void)? = nil,
        gapReport: GapReportActions = GapReportActions(openToday: { _ in }), gapUsed: ((UUID) -> Void)? = nil
    ) {
        self.openArtefact = openArtefact
        self.markPaper = markPaper
        self.gapReport = gapReport
        self.gapUsed = gapUsed
    }
}
