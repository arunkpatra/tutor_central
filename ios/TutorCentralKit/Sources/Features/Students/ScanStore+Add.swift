import Data
import Domain
import Foundation

/// Add and its Undo: the only writes a scan makes.
public extension ScanStore {
    /// One insert of the ticked rows as students of the chosen class (a fee read from the page is their own; none
    /// means the class fee); the register refreshed; the count, or nil with a toast.
    func add() async -> Int? {
        let drafts = ticked.map { $0.draft(classID: classID) }
        guard !drafts.isEmpty, !adding else { return nil }
        adding = true
        defer { adding = false }
        do {
            let made = try await students.createMany(drafts, centre: workspace.centre.id)
            lastAdded = made.map(\.id)
            rows = []
            await register.refresh()
            onAdded?(made.count)
            return made.count
        } catch {
            message = "Couldn't add them. Check your connection and try again."
            return nil
        }
    }

    /// The toast's Undo: those students deleted, nothing else; on failure the words to show where the tutor is.
    func undoAdd(ids: [UUID]) async -> String? {
        do {
            try await students.deleteMany(ids: ids)
            await register.refresh()
            return nil
        } catch {
            return "Couldn't undo. Check your connection and try again."
        }
    }
}
