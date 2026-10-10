import Domain
import Foundation

/// The in-memory register for tests, previews and `bun shots`: the ten students of `supabase/seed.sql` with fixed
/// ids and this month's invoices (six paid on 4 October 2026), a scripted error, a delay, a record of every write.
@MainActor public final class FakeStudentsRepository: StudentsRepository {
    public nonisolated static let akshita = id(1)
    public nonisolated static let dev = id(4)
    public nonisolated static let hemanth = id(5)
    public nonisolated static let meher = id(7)
    public nonisolated static let nikhil = id(8)
    public nonisolated static let riya = id(9)
    public nonisolated static let sahil = id(10)

    public nonisolated static let seed: [Student] = {
        let maths = FakeClassesRepository.maths.id
        let science = FakeClassesRepository.science.id
        let rows = [
            SeedRow(
                name: "Akshita Rao",
                classID: maths,
                ownFee: nil,
                parent: "Priya Rao",
                phone: "+919799113211",
                month: paid(1200)
            ),
            SeedRow(
                name: "Ananya Iyer",
                classID: maths,
                ownFee: nil,
                parent: "Suresh Iyer",
                phone: "+917903092566",
                month: paid(1200)
            ),
            SeedRow(
                name: "Bir Bikram Singh", classID: maths, ownFee: nil, parent: "Harjeet Singh", phone: "+917899487677",
                month: paid(1200)
            ),
            SeedRow(
                name: "Dev Kumar",
                classID: science,
                ownFee: 1000,
                parent: "Ramesh Kumar",
                phone: "+919884843831",
                month: due(1000)
            ),
            SeedRow(
                name: "Hemanth Reddy", classID: maths, ownFee: nil, parent: "Lakshmi Reddy", phone: "+919380260871",
                month: due(1200)
            ),
            SeedRow(
                name: "Lakshmi Menon",
                classID: maths,
                ownFee: nil,
                parent: "Anil Menon",
                phone: "+919972873953",
                month: paid(1200)
            ),
            SeedRow(
                name: "Meher Shah",
                classID: science,
                ownFee: nil,
                parent: "Kavita Shah",
                phone: "+919176590665",
                month: paid(1000)
            ),
            SeedRow(
                name: "Nikhil Das",
                classID: science,
                ownFee: nil,
                parent: "Arup Das",
                phone: "+919830012345",
                month: due(1000)
            ),
            SeedRow(
                name: "Riya Sharma",
                classID: maths,
                ownFee: 1500,
                parent: "Neha Sharma",
                phone: "+919811122233",
                month: paid(1500)
            ),
            SeedRow(
                name: "Sahil Verma",
                classID: nil,
                ownFee: 800,
                parent: "Deepak Verma",
                phone: "+919900011122",
                month: due(800)
            ),
        ]
        return rows.enumerated().map { withRecord($1.student(id: id($0 + 1))) }
    }()

    /// Dev, Riya and Sahil with their own fees, before any class or invoice exists (`students-few`).
    /// The seed with the Evening batch's five in it (the 10.3 boards): Dev, Meher, Nikhil, Riya and Sahil.
    public nonisolated static let eveningSeed: [Student] = seed.map { student in
        var moved = student
        if [dev, meher, nikhil, riya, sahil].contains(student.id) {
            moved.classID = FakeClassesRepository.evening.id
        }
        return moved
    }

    public nonisolated static let few: [Student] = seed.filter { [4, 9, 10].map(id).contains($0.id) }.map {
        var student = $0
        student.classID = nil
        student.thisMonth = nil
        return student
    }

    public var students: [Student]
    public var nextError: (any Error)?
    /// Every call waits this long first: lets a store show its loading and optimistic states.
    public var delay: Duration?
    public private(set) var created: [StudentDraft] = []
    public private(set) var updated: [UUID] = []
    public private(set) var archivedCalls: [(UUID, Bool)] = []
    public private(set) var deleted: [UUID] = []
    public private(set) var assigned: [([UUID], UUID?)] = []
    public private(set) var createdMany: [[StudentDraft]] = []
    public private(set) var deletedMany: [[UUID]] = []
    public private(set) var notesUpdates: [NotesUpdate] = []
    public private(set) var consentCalls: [(UUID, ConsentRecord?)] = []

    /// One notes write: the student and the whole text sent.
    public struct NotesUpdate: Hashable, Sendable {
        public let id: UUID
        public let notes: String?
    }

    public init(students: [Student] = []) {
        self.students = students
    }

    public func students(centre _: UUID, period _: Period) async throws -> [Student] {
        try await begin()
        return students
    }

    public func create(_ draft: StudentDraft, centre _: UUID) async throws -> Student {
        try await begin()
        created.append(draft)
        let made = Self.apply(draft, to: Student(
            id: UUID(), name: "", classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil, dateOfBirth: nil,
            gender: nil, notes: nil, archivedAt: nil, thisMonth: nil
        ))
        students.append(made)
        return made
    }

    public func update(id: UUID, with draft: StudentDraft) async throws -> Student {
        try await begin()
        let index = try index(of: id)
        updated.append(id)
        students[index] = Self.apply(draft, to: students[index])
        return students[index]
    }

    public func setArchived(id: UUID, _ archived: Bool) async throws {
        try await begin()
        let index = try index(of: id)
        archivedCalls.append((id, archived))
        students[index].archivedAt = archived ? FakeCountsRepository.fixedNow : nil
    }

    public func delete(id: UUID) async throws {
        try await begin()
        let index = try index(of: id)
        deleted.append(id)
        students.remove(at: index)
    }

    public func assign(studentIDs: [UUID], toClass classID: UUID?, centre _: UUID) async throws {
        try await begin()
        assigned.append((studentIDs, classID))
        for index in students.indices where studentIDs.contains(students[index].id) {
            students[index].classID = classID
        }
    }

    public func createMany(_ drafts: [StudentDraft], centre _: UUID) async throws -> [Student] {
        try await begin()
        createdMany.append(drafts)
        let made = drafts.map { draft in
            Self.apply(draft, to: Student(
                id: UUID(), name: "", classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil,
                dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil
            ))
        }
        students.append(contentsOf: made)
        return made
    }

    public func deleteMany(ids: [UUID]) async throws {
        try await begin()
        deletedMany.append(ids)
        students.removeAll { ids.contains($0.id) }
    }

    public func updateNotes(id: UUID, notes: String?) async throws -> Student {
        try await begin()
        let index = try index(of: id)
        notesUpdates.append(NotesUpdate(id: id, notes: notes))
        students[index].notes = notes
        return students[index]
    }

    public func setConsent(id: UUID, _ consent: ConsentRecord?) async throws -> Student {
        try await begin()
        let index = try index(of: id)
        consentCalls.append((id, consent))
        students[index].consent = consent
        return students[index]
    }

    private func begin() async throws {
        if let delay {
            try? await Task.sleep(for: delay)
        }
        guard let error = nextError else { return }
        nextError = nil
        throw error
    }

    private func index(of id: UUID) throws -> Int {
        guard let index = students.firstIndex(where: { $0.id == id }) else { throw URLError(.fileDoesNotExist) }
        return index
    }

    private static func apply(_ draft: StudentDraft, to student: Student) -> Student {
        var changed = student
        changed.name = draft.trimmedName
        changed.classID = draft.classID
        changed.monthlyFee = draft.fee
        changed.parentName = draft.trimmedParentName
        changed.parentPhone = draft.parentPhone
        changed.dateOfBirth = draft.dateOfBirth
        changed.gender = draft.gender
        changed.notes = draft.trimmedNotes
        changed.classLevel = draft.classLevel
        changed.schoolID = draft.schoolID
        changed.board = draft.classLevel?.expectsBoard == true ? draft.board : nil
        changed.messageLanguage = draft.messageLanguage
        return changed
    }

    public nonisolated static func id(_ number: Int) -> UUID {
        UUID(uuidString: String(format: "aaaaaaaa-0000-0000-0000-%012d", number))!
    }

    private nonisolated static func paid(_ rupees: Int) -> MonthFee {
        MonthFee(
            amount: Money(rupees: rupees),
            status: .paid,
            paidOn: Day(year: 2026, month: 10, day: 4),
            paidMethod: .upi
        )
    }

    private nonisolated static func due(_ rupees: Int) -> MonthFee {
        MonthFee(amount: Money(rupees: rupees), status: .due, paidOn: nil)
    }

    /// One line of `seed.sql`'s students with this month's invoice.
    private struct SeedRow {
        let name: String
        let classID: UUID?
        let ownFee: Int?
        let parent: String
        let phone: String
        let month: MonthFee

        func student(id: UUID) -> Student {
            Student(
                id: id, name: name, classID: classID, monthlyFee: ownFee.map(Money.init(rupees:)), parentName: parent,
                parentPhone: PhoneNumber(e164: phone), dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil,
                thisMonth: month
            )
        }
    }
}
