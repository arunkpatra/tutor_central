import Domain
import Foundation

/// The in-memory classes for tests, previews and `bun shots`: the two of `supabase/seed.sql`, a scripted error, a
/// record of every write.
@MainActor public final class FakeClassesRepository: ClassesRepository {
    public nonisolated static let maths = Classroom(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333331")!, name: "Class 10 Maths", subject: "Mathematics",
        monthlyFee: Money(rupees: 1200), meetingDays: [.monday, .wednesday, .friday],
        startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 0), archivedAt: nil
    )
    public nonisolated static let science = Classroom(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333332")!, name: "Class 8 Science", subject: "Science",
        monthlyFee: Money(rupees: 1000), meetingDays: [.tuesday, .thursday],
        startTime: TimeOfDay(hour: 16, minute: 30), endTime: TimeOfDay(hour: 17, minute: 30), archivedAt: nil
    )
    public nonisolated static let seed = [maths, science]

    public var classes: [Classroom]
    public var nextError: (any Error)?
    public private(set) var created: [ClassroomDraft] = []
    public private(set) var updated: [UUID] = []
    public private(set) var archived: [UUID] = []

    public init(classes: [Classroom] = []) {
        self.classes = classes
    }

    /// By name as the database orders text (`order("name")`), so "Class 10" comes before "Class 8".
    public func classes(centre _: UUID) async throws -> [Classroom] {
        try takeError()
        return classes.sorted { $0.name < $1.name }
    }

    public func create(_ draft: ClassroomDraft, centre _: UUID) async throws -> Classroom {
        try takeError()
        created.append(draft)
        let made = Self.apply(draft, to: Classroom(
            id: UUID(), name: "", subject: nil, monthlyFee: nil, meetingDays: [], startTime: nil, endTime: nil,
            archivedAt: nil
        ))
        classes.append(made)
        return made
    }

    public func update(id: UUID, with draft: ClassroomDraft) async throws -> Classroom {
        try takeError()
        guard let index = classes.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        updated.append(id)
        classes[index] = Self.apply(draft, to: classes[index])
        return classes[index]
    }

    /// Marks the class only; the store detaches its members, as `archive_class` does in the database.
    public func archive(id: UUID) async throws {
        try takeError()
        guard let index = classes.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        archived.append(id)
        classes[index].archivedAt = FakeCountsRepository.fixedNow
    }

    private static func apply(_ draft: ClassroomDraft, to classroom: Classroom) -> Classroom {
        var changed = classroom
        changed.name = draft.trimmedName
        changed.subject = draft.trimmedSubject
        changed.monthlyFee = draft.fee
        changed.meetingDays = draft.meetingDays
        changed.startTime = draft.startTime
        changed.endTime = draft.endTime
        return changed
    }

    private func takeError() throws {
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }
}
