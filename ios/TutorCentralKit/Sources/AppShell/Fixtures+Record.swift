import Data
import Domain
import Foundation

/// The fixtures of the record (Phase 11): the boards' schools and the message log.
extension Fixtures {
    /// P10-NewStudent-School's three schools.
    static let boardSchools = [
        FakeSchoolsRepository.vidya,
        School(
            id: UUID(uuidString: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60732") ?? UUID(),
            name: "National Public School",
            board: nil
        ),
        School(
            id: UUID(uuidString: "7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60733") ?? UUID(),
            name: "St Mary's School",
            board: .icse
        ),
    ]

    /// The message log: Hemanth's absence alert and the fee reminders the boards show.
    @MainActor static func messages(for state: LaunchState) -> FakeMessageLogRepository {
        // P10-Student-Consent-Waiting: Riya's parent asked today.
        let asked = state == .studentConsentWaiting
            ? [FakeStudentsRepository.riya: [riyaAsked(at: clock(for: state))]]
            : [:]
        return FakeMessageLogRepository(
            logs: FakeMessageLogRepository.seed, feeLogs: FakeMessageLogRepository.feeSeed, entries: asked,
            now: { clock(for: state) }
        )
    }

    static func riyaAsked(at date: Date) -> MessageEntry {
        MessageEntry(id: UUID(), kind: .consent, openedAt: date, language: nil)
    }
}
