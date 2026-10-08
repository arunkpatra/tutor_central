import Data
import Domain
import Foundation
import Observation

@MainActor @Observable public final class RegisterStore {
    public internal(set) var students: [Student] = []
    public internal(set) var classes: [Classroom] = []
    public private(set) var loading = false
    public private(set) var refreshing = false
    public private(set) var error: String?
    public var message: String?
    public private(set) var canRetry = false
    /// When the last write succeeded: the view plays the success haptic on it (design-tokens.md, Haptics).
    public private(set) var lastSavedAt: Date?
    public var search = ""
    public var filter: StudentFilter = .all
    public var sort: StudentSort = .name

    let workspace: Workspace
    private let studentsRepository: any StudentsRepository
    let classesRepository: any ClassesRepository
    private let cache: RegisterCache?
    let now: @Sendable () -> Date
    private let calendar: Calendar
    private var loaded = false
    private var lastFailed: (@MainActor () async -> Void)?

    public init(
        workspace: Workspace, students: any StudentsRepository, classes: any ClassesRepository,
        cache: RegisterCache?, now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        studentsRepository = students
        classesRepository = classes
        self.cache = cache
        self.now = now
        self.calendar = calendar
    }

    public var period: Period {
        Period.containing(now(), in: calendar.timeZone)
    }

    public var today: Day {
        Day(now(), calendar: calendar)
    }

    /// The empty register's first screen: only once a read has said so, never while loading or after a failed first
    /// read (a new phone with no signal is not a centre with no students).
    public var showsEmptyRegister: Bool {
        students.isEmpty && loaded && !loading && error == nil
    }

    public var isSearching: Bool {
        !search.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public var activeStudents: [Student] {
        students.filter { !$0.isArchived }
    }

    public var activeClasses: [Classroom] {
        classes.filter { !$0.isArchived }
    }

    public var showsFilters: Bool {
        !activeClasses.isEmpty || students.contains(where: \.isArchived)
    }

    public var visible: [Student] {
        StudentQuery.apply(
            students,
            classes: classes,
            search: search,
            filter: filter,
            sort: sort
        )
    }

    public var unassigned: [Student] {
        StudentQuery.apply(
            students,
            classes: classes,
            search: "",
            filter: .unassigned,
            sort: .name
        )
    }

    public var countLine: String {
        let shown = visible.count
        if isSearching {
            return "\(shown) of \(students.count) match"
        }
        switch filter {
        case .all: return "\(shown) \(shown == 1 ? "student" : "students")"
        case let .classroom(id): return "\(shown) in \(classroom(id)?.name ?? "the class")"
        case .unassigned: return "\(shown) with no class"
        case .archived: return "\(shown) archived"
        }
    }

    public func classroom(_ id: UUID?) -> Classroom? {
        id.flatMap { id in classes.first { $0.id == id } }
    }

    public func student(_ id: UUID) -> Student? {
        students.first { $0.id == id }
    }

    public func members(of classID: UUID) -> [Student] {
        StudentQuery.apply(students, classes: classes, search: "", filter: .classroom(classID), sort: .name)
    }

    public func rowDetail(for student: Student) -> String {
        if let phone = student.parentPhone, activeClasses.isEmpty || (isSearching && StudentQuery.matchesPhone(
            student,
            search: search
        )) {
            return phone.display
        }
        return classroom(student.classID)?.name ?? "No class yet"
    }

    // MARK: Reads

    public func load() async {
        if !loaded, let snapshot = cache?.load() {
            classes = snapshot.classes
            students = snapshot.period == period ? snapshot.students : snapshot.students
                .map(Self.withoutFeeMark)
            loaded = true
        }
        if !loaded {
            loading = true
        } else {
            refreshing = true
        }
        defer { loading = false; refreshing = false }
        await fetch()
    }

    /// For a screen pushed over the list (a detail, a link): read only when nothing has been read or cached yet.
    public func loadIfNeeded() async {
        if !loaded {
            await load()
        }
    }

    public func refresh() async {
        refreshing = true
        defer { refreshing = false }
        await fetch()
    }

    private func fetch() async {
        do {
            async let read = studentsRepository.students(centre: workspace.centre.id, period: period)
            async let classRead = classesRepository.classes(centre: workspace.centre.id)
            (students, classes) = try await (read, classRead)
            error = nil
            loaded = true
            persist()
        } catch {
            self.error = "Couldn't refresh. Check your connection and try again."
        }
    }

    private func persist() {
        try? cache?.save(RegisterSnapshot(students: students, classes: classes, period: period))
    }

    func replace(_ id: UUID, with student: Student) {
        if let index = students.firstIndex(where: { $0.id == id }) {
            students[index] = student
        } else {
            students.append(student)
        }
    }

    func succeeded() {
        lastFailed = nil
        canRetry = false
        lastSavedAt = now()
        persist()
    }

    func failed(_ text: String, retry: @escaping @MainActor () async -> Void) {
        message = text
        lastFailed = retry
        canRetry = true
    }

    private func firstWord(_ name: String) -> String {
        name.split(whereSeparator: \.isWhitespace).first
            .map(String.init) ?? name
    }

    private static func withoutFeeMark(_ student: Student) -> Student {
        var kept = student
        kept.thisMonth = nil
        return kept
    }
}

// MARK: Writes: optimistic, rolled back with a toast that names the student or class and offers Retry.

public extension RegisterStore {
    @discardableResult func addStudent(_ draft: StudentDraft) async -> Student? {
        let placeholder = Student(
            id: UUID(), name: draft.trimmedName, classID: draft.classID, monthlyFee: draft.fee,
            parentName: draft.trimmedParentName,
            parentPhone: draft.parentPhone, dateOfBirth: draft.dateOfBirth, gender: draft.gender,
            notes: draft.trimmedNotes, archivedAt: nil, thisMonth: nil
        )
        students.append(placeholder)
        do {
            let made = try await studentsRepository.create(draft, centre: workspace.centre.id)
            replace(placeholder.id, with: made)
            succeeded()
            return made
        } catch {
            students.removeAll { $0.id == placeholder.id }
            let text = "Couldn't save \(firstWord(draft.trimmedName)). Check your connection and try again."
            failed(text) { [weak self] in
                await self?.addStudent(draft)
            }
            return nil
        }
    }

    func updateStudent(_ id: UUID, with draft: StudentDraft) async -> Bool {
        guard let before = student(id) else { return false }
        var optimistic = before
        optimistic.name = draft.trimmedName
        optimistic.classID = draft.classID
        optimistic.monthlyFee = draft.fee
        optimistic.parentName = draft.trimmedParentName
        optimistic.parentPhone = draft.parentPhone
        optimistic.dateOfBirth = draft.dateOfBirth
        optimistic.gender = draft.gender
        optimistic.notes = draft.trimmedNotes
        replace(id, with: optimistic)
        do {
            var saved = try await studentsRepository.update(id: id, with: draft)
            saved.thisMonth = before.thisMonth
            replace(id, with: saved)
            succeeded()
            return true
        } catch {
            replace(id, with: before)
            let text = "Couldn't save \(before.firstName). Check your connection and try again."
            failed(text) { [weak self] in
                _ = await self?.updateStudent(
                    id,
                    with: draft
                )
            }
            return false
        }
    }

    func setArchived(_ id: UUID, _ archived: Bool) async {
        guard let before = student(id) else { return }
        var optimistic = before
        optimistic.archivedAt = archived ? now() : nil
        replace(id, with: optimistic)
        do {
            try await studentsRepository.setArchived(id: id, archived)
            succeeded()
        } catch {
            replace(id, with: before)
            failed(
                "Couldn't \(archived ? "archive" : "restore") \(before.firstName). Check your connection and try again."
            ) { [weak self] in
                await self?.setArchived(
                    id,
                    archived
                )
            }
        }
    }

    /// Not optimistic: nothing can be shown after a cascade until the server has done it.
    func deleteStudent(_ id: UUID) async -> Bool {
        guard let before = student(id) else { return false }
        do {
            try await studentsRepository.delete(id: id)
            students.removeAll { $0.id == id }
            succeeded()
            return true
        } catch {
            let text = "Couldn't delete \(before.firstName). Check your connection and try again."
            failed(text) { [weak self] in
                _ = await self?.deleteStudent(id)
            }
            return false
        }
    }

    func assign(_ ids: [UUID], to classID: UUID?) async {
        // Each moved student's class before the move: a failure undoes these rows only, never another write.
        let previous = Dictionary(uniqueKeysWithValues: ids.compactMap { id in student(id).map { (id, $0.classID) } })
        let names = ids.count == 1 ? student(ids[0])?.firstName : nil
        setClass(of: ids) { _ in classID }
        do {
            try await studentsRepository.assign(studentIDs: ids, toClass: classID, centre: workspace.centre.id)
            succeeded()
        } catch {
            setClass(of: ids) { previous[$0] ?? nil }
            let text = "Couldn't move \(names ?? "the students"). Check your connection and try again."
            failed(text) { [weak self] in await self?.assign(ids, to: classID) }
        }
    }

    func retryLast() async {
        guard let retry = lastFailed else { return }
        lastFailed = nil
        canRetry = false
        message = nil
        await retry()
    }
}

extension RegisterStore: Register {}
