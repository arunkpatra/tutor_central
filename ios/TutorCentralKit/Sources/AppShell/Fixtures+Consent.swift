import Data
import Domain
import Foundation

/// Phase 18's consent boards over Hemanth's page on Monday 12 October: his parent agreed in person on Thursday 1
/// October (P18-Consent-Change, -Withdraw), then withdrew on a call that Monday (P18-Student-Withdrawn).
extension Fixtures {
    static let consentStates: Set<LaunchState> = [.studentConsentChange, .studentConsentWithdraw, .studentWithdrawn]
    static let consentClock = india(day: 12, hour: 10, minute: 0)
    static let hemanthAgreedAt = india(day: 1, hour: 18, minute: 0)

    /// Hemanth agreed, or with nothing recorded after the withdrawal.
    static func withConsent(_ students: [Student], for state: LaunchState) -> [Student] {
        guard consentStates.contains(state) else { return students }
        return students.map { student in
            guard student.id == FakeStudentsRepository.hemanth, state != .studentWithdrawn else { return student }
            var agreed = student
            agreed.consent = student.parentPhone.map { ConsentRecord(at: hemanthAgreedAt, phone: $0, how: .inPerson) }
            return agreed
        }
    }

    static func consentHistory(for state: LaunchState) -> FakeConsentHistoryRepository {
        guard consentStates.contains(state) else { return FakeConsentHistoryRepository() }
        let phone = FakeStudentsRepository.seed.first { $0.id == FakeStudentsRepository.hemanth }?.parentPhone
        var events = [ConsentEvent(kind: .given, how: .inPerson, at: hemanthAgreedAt, phone: phone)]
        if state == .studentWithdrawn {
            events.insert(ConsentEvent(kind: .withdrawn, how: .call, at: consentClock, phone: nil), at: 0)
        }
        return FakeConsentHistoryRepository(events: [FakeStudentsRepository.hemanth: events])
    }

    /// P18-Export-*: Hemanth's export on Monday 12 October at 16:05, asked at 16:02, made at 16:03 in five pages.
    static let exportStates: Set<LaunchState> = [
        .studentExport, .studentExportMaking, .studentExportReady, .studentExportFailed,
    ]
    static let exportClock = india(day: 12, hour: 16, minute: 5)

    static func exportJobs(for state: LaunchState) -> [UUID: JobStatus] {
        let asked = india(day: 12, hour: 16, minute: 2)
        let made = india(day: 12, hour: 16, minute: 3)
        let job: JobStatus? = switch state {
        case .studentExportMaking: JobStatus(id: UUID(), state: .running, createdAt: asked)
        case .studentExportReady:
            JobStatus(
                id: UUID(), state: .done, createdAt: asked, finishedAt: made,
                file: JobFile(path: "board/hemanth.pdf", pages: 5, madeAt: made)
            )
        case .studentExportFailed: JobStatus(id: UUID(), state: .failed, createdAt: asked, finishedAt: made)
        default: nil
        }
        return job.map { [FakeStudentsRepository.hemanth: $0] } ?? [:]
    }
}
