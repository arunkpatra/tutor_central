import Data
import Domain
import Foundation
import Observation

/// Scan register (P6-Scan-*): one photo of a paper register read into a list the tutor checks row by row before
/// anything is saved. Edits, removals and their Undo stay on the device; Add writes the ticked rows in one insert and
/// its Undo deletes exactly those. The photo is kept only for Retry and never stored.
@MainActor @Observable public final class ScanStore {
    public enum Stage: Hashable, Sendable {
        case intro, reading, review, nothing
        case failed(String)
    }

    /// A row taken off the list, kept for the toast's Undo with the place it came from.
    public struct RemovedRow: Hashable, Sendable {
        public let row: ScanRow
        public let index: Int
    }

    public internal(set) var stage: Stage = .intro
    public internal(set) var photo: ImageUpload?
    public var rows: [ScanRow] = []
    /// "Add to": the first active class by default; nil is No class.
    public var classID: UUID?
    public internal(set) var generationID: UUID?
    public internal(set) var adding = false
    public internal(set) var removed: RemovedRow?
    public internal(set) var lastAdded: [UUID] = []
    /// A toast for the screen.
    public var message: String?
    public internal(set) var workspace: Workspace
    public var onWorkspaceChanged: ((Workspace) -> Void)?
    /// AppShell pops to the list and shows "7 students added from the register." with Undo.
    public var onAdded: ((Int) -> Void)?

    let register: RegisterStore
    let ai: any AIRepository
    let students: any StudentsRepository
    private let centres: any CentreRepository
    private let now: @Sendable () -> Date
    @ObservationIgnored var task: Task<Void, Never>?

    public init(
        workspace: Workspace, register: RegisterStore, ai: any AIRepository, students: any StudentsRepository,
        centres: any CentreRepository, now: @escaping @Sendable () -> Date
    ) {
        self.workspace = workspace
        self.register = register
        self.ai = ai
        self.students = students
        self.centres = centres
        self.now = now
        classID = register.activeClasses.first?.id
    }

    public var needsConsent: Bool {
        workspace.centre.aiConsentAt == nil
    }

    public var ticked: [ScanRow] {
        rows.filter(\.included)
    }

    public var title: String {
        ScanReview.title(found: rows.count)
    }

    public var addLabel: String {
        ScanReview.addLabel(ticked: ticked.count)
    }

    public var canAdd: Bool {
        !ticked.isEmpty && !adding
    }

    /// Back asks before a list with rows is left.
    public var hasRows: Bool {
        stage == .review && !rows.isEmpty
    }

    public var className: String? {
        register.classroom(classID)?.name
    }

    /// "I agree, continue": the centre's consent written and merged into the session's workspace.
    public func recordConsent() async -> Bool {
        let at = now()
        do {
            try await centres.recordAIConsent(id: workspace.centre.id, at: at)
        } catch {
            message = "Couldn't save your agreement. Check your connection and try again."
            return false
        }
        workspace.centre.aiConsentAt = at
        onWorkspaceChanged?(workspace)
        return true
    }

    /// Reading: the API, then the rows flagged against the register; nothing found and a failure have their stages.
    public func read(_ upload: ImageUpload) async {
        photo = upload
        stage = .reading
        rows = []
        if classID == nil || register.classroom(classID) == nil {
            classID = register.activeClasses.first?.id
        }
        do {
            let answer = try await ai.scanRegister(upload, centre: workspace.centre.id)
            guard !Task.isCancelled, stage == .reading else { return }
            generationID = answer.id
            let read = answer.rows.map { dto in
                ScanRow(
                    id: UUID(), name: dto.name, phone: dto.phone.flatMap(PhoneNumber.init(e164:)),
                    fee: dto.fee.map(Money.init(rupees:)), parentName: "", included: true, flag: nil
                )
            }
            rows = ScanReview.flag(read, against: register.activeStudents, classes: register.activeClasses)
            stage = rows.isEmpty ? .nothing : .review
        } catch {
            guard !Task.isCancelled, stage == .reading else { return }
            if error == .consent {
                workspace.centre.aiConsentAt = nil
                stage = .intro
            } else {
                stage = .failed(error.message)
            }
        }
    }

    /// The same photo again.
    public func retry() async {
        guard let photo else { return }
        await read(photo)
    }

    /// Back to the intro for another photo; a read in flight is abandoned (its row stays on the server).
    public func reset() {
        task?.cancel()
        task = nil
        stage = .intro
        photo = nil
        rows = []
    }

    /// From Fix this row: the row as edited, flagged again against the register.
    public func update(_ row: ScanRow) {
        guard let index = rows.firstIndex(where: { $0.id == row.id }) else { return }
        let flagged = ScanReview.flag([row], against: register.activeStudents, classes: register.activeClasses)[0]
        var kept = row
        kept.flag = flagged.flag
        rows[index] = kept
    }

    /// A row the tutor added by hand, ticked.
    public func addRow() -> ScanRow {
        let row = ScanRow(id: UUID(), name: "", phone: nil, fee: nil, parentName: "", included: true, flag: nil)
        rows.append(row)
        return row
    }

    public func remove(_ id: UUID) {
        guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
        removed = RemovedRow(row: rows.remove(at: index), index: index)
        message = "\(removed?.row.name ?? "The row") removed."
    }

    public func undoRemove() {
        guard let removed else { return }
        rows.insert(removed.row, at: min(removed.index, rows.count))
        self.removed = nil
    }
}
