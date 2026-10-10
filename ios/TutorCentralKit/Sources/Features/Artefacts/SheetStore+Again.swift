import Data
import Domain
import Foundation

/// Make it again (plan decision 12): one tap and a reason; the new sheet replaces this one on screen and in the plan
/// (`keep_artefact` relinks the lines), the old stays in the record; offline it is refused in words; a failure keeps
/// the old one and says so.
extension SheetStore {
    static let againFailed = "Couldn't make it again. The sheet you have is still here."

    public func makeAgain(_ reason: RegenerateReason) async {
        guard again == .idle, let artefact, let sheet else { return }
        guard await online() else {
            message = OfflineRefusal.words(for: .regenerate)
            return
        }
        guard let link = link() else {
            message = Self.againFailed
            return
        }
        again = .making(reason)
        defer { again = .idle }
        do {
            let request = SheetRequest(
                classLevel: classLevel, subject: group?.subject ?? "", skills: [group?.skill ?? sheet.title],
                questions: max(sheet.questions.count, 3), forHomework: sheet.forHomework, reason: reason.words
            )
            let made = try await ai.makeSheet(request, centre: centre)
            guard !Task.isCancelled else { return }
            let kept = try await plans.keep(
                NewArtefact(
                    kind: .sheet, source: .made, title: artefact.title, content: .sheet(made.content), photoPath: nil,
                    generationID: made.generationID, regeneratedFrom: artefact.id
                ),
                to: link, centre: centre
            )
            await reload(kept)
        } catch {
            message = Self.againFailed
        }
    }

    /// "An easier sheet is on its way. This one stays until it arrives." (P10-Sheet-Regenerating).
    public var regeneratingLine: String {
        guard case let .making(reason) = again else { return "" }
        let what = switch reason {
        case .easier: "An easier sheet"
        case .harder: "A harder sheet"
        case .shorter: "A shorter sheet"
        case .moreSums: "A sheet with more sums"
        case .differentNumbers: "A sheet with different numbers"
        case .own: "A new sheet"
        }
        return "\(what) is on its way. This one stays until it arrives."
    }

    /// Where a new sheet goes: the lines this one serves (the group's set or homework, or one student's).
    func link() -> ArtefactLink? {
        guard let plan, let first = items.first else { return nil }
        return ArtefactLink(
            plan: plan.id, group: first.groupNo, student: artefact?.studentID, itemKind: first.kind
        )
    }

    /// The group's class for the model: the highest among its members; class 8 when none has one.
    var classLevel: ClassLevel {
        group?.memberIDs.compactMap { register.student($0)?.classLevel }.max() ?? .eight
    }
}
