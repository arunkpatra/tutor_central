import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// The item's hero (P10-School-Item): who and the subject, the kind, the title, the day with its countdown, the
/// portions.
public struct ItemHeroModel: Hashable, Sendable {
    public let eyebrow: String
    public let kind: KindChipKind
    public let title: String
    public let dateLine: String
    public let portionsLine: String?
}

/// A student the item reaches, with their status word and the reason the record gives.
public struct WhoRow: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let initials: String
    public let name: String
    public let line: String
}

/// An item's page (P10-School-Item, its homework and holiday forms; plan/phase-13-plan.md decisions 7 and 22): the
/// hero,
/// Who (or, for a holiday, the batch days it covers), what the school sent, Edit and Delete. A change tells the plan
/// which students it reached (decision 16).
@MainActor @Observable public final class ItemStore {
    public enum State: Hashable, Sendable { case loading, shown, gone, failed }

    public private(set) var state: State = .loading
    public private(set) var item: SchoolItem?
    public private(set) var schools: [School] = []
    public private(set) var photoURL: URL?
    public var message: String?
    /// The students an added, changed or deleted item reached: Today makes an open plan again for them.
    public var onChanged: ((Set<UUID>) -> Void)?
    /// An exam's days from today to the test (P10-School-Item's Preparation); empty for any other item.
    public internal(set) var preparation: [PreparationRowModel] = []
    /// The batch whose plan Change opens on Today.
    public internal(set) var changeOpensToday: UUID?
    /// From the day before the exam: the sheet for the first of its students whose parent has a number.
    public internal(set) var testTomorrowAsk: TestTomorrowAsk?

    public let itemID: UUID
    let workspace: Workspace
    let register: any Register
    let repository: any SchoolItemsRepository
    private let schoolsRepository: any SchoolsRepository
    private let photos: any PhotoStore
    let textbooks: (any TextbooksRepository)?
    let plans: (any PlansRepository)?
    let record: (any RecordRepository)?
    /// From the mock day to the test, the page leads with them (P10-School-Exam-LastDays).
    public internal(set) var lastDays: LastDaysModel?
    /// The server's jobs (D106): the exam's job read for the page's rows, Try again asked of it; none in previews.
    @ObservationIgnored public var jobs: (any JobsRepository)?
    /// How often the page reads itself again while the mock is being made after Try again.
    @ObservationIgnored public var followEvery: Duration = .seconds(20)
    @ObservationIgnored var following: Task<Void, Never>?
    private let now: @Sendable () -> Date
    let calendar: Calendar
    private let online: @Sendable () async -> Bool

    public init(
        itemID: UUID, workspace: Workspace, items: any SchoolItemsRepository, register: any Register,
        schools: any SchoolsRepository, photos: any PhotoStore, now: @escaping @Sendable () -> Date, calendar: Calendar,
        online: @escaping @Sendable () async -> Bool, textbooks: (any TextbooksRepository)? = nil,
        plans: (any PlansRepository)? = nil, record: (any RecordRepository)? = nil
    ) {
        self.record = record
        self.itemID = itemID
        self.textbooks = textbooks
        self.plans = plans
        self.workspace = workspace
        repository = items
        self.register = register
        schoolsRepository = schools
        self.photos = photos
        self.now = now
        self.calendar = calendar
        self.online = online
    }

    public var today: Day {
        Day(now(), calendar: calendar)
    }

    public func load() async {
        await register.loadIfNeeded()
        if let read = try? await schoolsRepository.schools(centre: workspace.centre.id) {
            schools = read
        }
        do {
            guard let read = try await repository.item(id: itemID, centre: workspace.centre.id) else {
                state = .gone
                return
            }
            item = read
            state = .shown
            if let path = read.photoPath {
                photoURL = try? await photos.url(for: path)
            }
            await loadPreparation(read)
        } catch {
            state = item == nil ? .failed : .shown
        }
    }

    public var hero: ItemHeroModel? {
        guard let item else { return nil }
        return ItemHeroModel(
            eyebrow: eyebrow(item), kind: SchoolWords.kind(item.kind), title: item.title, dateLine: dateLine(item),
            portionsLine: lastDays == nil ? item.portions.map { "Portions: \($0)" } : nil
        )
    }

    /// The students the item reaches, by name, with their status and the record's first reason.
    public var who: [WhoRow] {
        // From the mock day the page leads with the last days, whose Marked names the students.
        guard let item, item.kind != .holiday, lastDays == nil else { return [] }
        return SchoolItemRules.students(for: item, in: register.activeStudents).map { student in
            let reason = student.trackReasons.first.map { " · \($0)" } ?? ""
            return WhoRow(
                id: student.id, initials: student.initials, name: student.name,
                line: "\(student.trackStatus.title)\(reason)"
            )
        }
    }

    /// A holiday: the days it covers of each batch its students are in.
    public var coveredLine: String? {
        guard let item, item.kind == .holiday else { return nil }
        let batches = register.activeClasses.filter { batch in
            register.members(of: batch.id).contains { SchoolItemRules.reaches(item, $0) }
        }
        let line = HolidayRules.coveredLine(item, batches: batches, calendar: calendar)
        return line.isEmpty ? nil : line
    }

    /// "Shared on Wed 7 Oct, 15:04".
    public var sourceLine: String {
        guard let item else { return "" }
        let how = switch item.source {
        case .sharedText, .sharedPhoto: "Shared on"
        case .photo: "From a photo on"
        case .pasted: "Pasted on"
        case .typed: "Added on"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEE d MMM, HH:mm"
        return "\(how) \(formatter.string(from: item.receivedAt))"
    }

    /// The form of the item for Edit.
    public func form() -> ItemFormStore? {
        item.map { ItemFormStore(item: $0, students: register.activeStudents, schools: schools, today: today) }
    }

    public func save(_ edited: SchoolItem) async -> Bool {
        guard await online() else {
            message = OfflineRefusal.words(for: .schoolItem)
            return false
        }
        let before = reached
        do {
            item = try await repository.update(edited, centre: workspace.centre.id)
            onChanged?(before.union(reached))
            if let item {
                await loadPreparation(item)
            }
            return true
        } catch {
            message = "That didn't go through. Check your connection and try again. Your changes are still here."
            return false
        }
    }

    public func delete() async -> Bool {
        guard let item else { return false }
        guard await online() else {
            message = OfflineRefusal.words(for: .schoolItem)
            return false
        }
        let students = reached
        do {
            try await repository.delete(id: item.id, centre: workspace.centre.id)
        } catch {
            message = "That didn't go through. Check your connection and try again. The item is still here."
            return false
        }
        // One photo serves each item read from it: it goes with the last of them.
        if let path = item.photoPath,
           let others = try? await repository.items(centre: workspace.centre.id),
           !others.contains(where: { $0.photoPath == path }) {
            try? await photos.remove(path: path)
        }
        self.item = nil
        state = .gone
        onChanged?(students)
        return true
    }

    private var reached: Set<UUID> {
        guard let item else { return [] }
        return Set(SchoolItemRules.students(for: item, in: register.activeStudents).map(\.id))
    }

    private func eyebrow(_ item: SchoolItem) -> String {
        let school = { (id: UUID) in self.schools.first { $0.id == id }?.name ?? "A school" }
        var parts: [String]
        switch item.audience {
        case let .schoolClass(id, level): parts = [school(id), level.title]
        case let .school(id): parts = ["\(school(id)) · every class"]
        case let .student(id):
            let student = register.student(id)
            parts = [student?.name ?? "A student", student?.schoolID.map(school)].compactMap(\.self)
        }
        if let subject = item.subject, !subject.isEmpty {
            parts.append(subject)
        }
        return parts.joined(separator: " · ")
    }

    private func dateLine(_ item: SchoolItem) -> String {
        switch item.kind {
        case .exam:
            return [item.date.weekdayLongText, SchoolItemRules.countdown(from: today, to: item.date)]
                .compactMap(\.self).joined(separator: " · ")
        case .homework:
            return "Due \(item.date.weekdayLongText)"
        case .holiday:
            guard let end = item.endDate, end > item.date else { return item.date.weekdayLongText }
            return "\(item.date.weekdayLongText) to \(end.weekdayLongText)"
        case .notice:
            return item.date.weekdayLongText
        }
    }
}
