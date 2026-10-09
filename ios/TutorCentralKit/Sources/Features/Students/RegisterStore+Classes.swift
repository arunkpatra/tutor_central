import Domain
import Foundation

/// The register's class writes: optimistic, each undoing only its own rows when it fails.
public extension RegisterStore {
    @discardableResult func addClass(_ draft: ClassroomDraft) async -> Classroom? {
        let placeholder = Classroom(
            id: UUID(), name: draft.trimmedName, subject: draft.trimmedSubject, monthlyFee: draft.fee,
            meetingDays: draft.meetingDays,
            startTime: draft.startTime, endTime: draft.endTime, archivedAt: nil
        )
        classes.append(placeholder)
        do {
            let made = try await classesRepository.create(draft, centre: workspace.centre.id)
            classes.removeAll { $0.id == placeholder.id }
            classes.append(made)
            classes.sort { $0.name < $1.name }
            succeeded()
            return made
        } catch {
            classes.removeAll { $0.id == placeholder.id }
            let text = "Couldn't save \(draft.trimmedName). Check your connection and try again."
            failed(text, .addClass, error: error) { [weak self] in
                await self?.addClass(draft)
            }
            return nil
        }
    }

    func updateClass(_ id: UUID, with draft: ClassroomDraft) async -> Bool {
        guard let before = classroom(id) else { return false }
        var optimistic = before
        optimistic.name = draft.trimmedName
        optimistic.subject = draft.trimmedSubject
        optimistic.monthlyFee = draft.fee
        optimistic.meetingDays = draft.meetingDays
        optimistic.startTime = draft.startTime
        optimistic.endTime = draft.endTime
        replaceClass(id, with: optimistic)
        do {
            // Looked up again by id after the save: the list may have changed while it was on its way.
            try await replaceClass(id, with: classesRepository.update(id: id, with: draft))
            succeeded()
            return true
        } catch {
            replaceClass(id, with: before)
            let text = "Couldn't save \(before.name). Check your connection and try again."
            failed(text, .editClass, error: error) { [weak self] in _ = await self?.updateClass(id, with: draft) }
            return false
        }
    }

    func archiveClass(_ id: UUID) async {
        guard let before = classroom(id) else { return }
        let members = students.filter { $0.classID == id }.map(\.id)
        var archived = before
        archived.archivedAt = now()
        replaceClass(id, with: archived)
        setClass(of: members) { _ in nil }
        do {
            try await classesRepository.archive(id: id)
            succeeded()
        } catch {
            // Undo this archive's rows only: the class, and the members it detached.
            replaceClass(id, with: before)
            setClass(of: members) { _ in id }
            let text = "Couldn't archive \(before.name). Check your connection and try again."
            failed(text, .editClass, error: error) { [weak self] in await self?.archiveClass(id) }
        }
    }

    internal func setClass(of ids: [UUID], to classID: (UUID) -> UUID?) {
        for id in ids {
            if var moved = student(id) {
                moved.classID = classID(id)
                replace(id, with: moved)
            }
        }
    }

    internal func replaceClass(_ id: UUID, with classroom: Classroom) {
        if let index = classes.firstIndex(where: { $0.id == id }) {
            classes[index] = classroom
        }
    }
}
