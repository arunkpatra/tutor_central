import Data
import DesignSystem
import Domain
import Foundation
import Observation

/// One row of the list or the chosen day (P10-School-List): the day column, the title, the line, the kind.
public struct SchoolRowModel: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let day: String
    public let date: String
    public let title: String
    public let line: String
    public let kind: KindChipKind
}

/// The School tab (docs/spec-v2.md section 4; plan/phase-13-plan.md decision 4): the items from today on by week, the
/// calendar with a dot per kind, the chosen day's items; the copy on this iPhone offline (D39).
@MainActor @Observable public final class SchoolStore {
    public enum State: Hashable, Sendable { case loading, empty, items, offline, failed }
    public enum Segment: Hashable, Sendable, CaseIterable { case list, calendar }

    public private(set) var state: State = .loading
    public var segment: Segment = .list
    public var selectedDay: Day?
    /// The calendar's month (today's at first).
    public var month: Period
    public private(set) var items: [SchoolItem] = []
    public private(set) var schools: [School] = []
    /// The copy's time, for the status line (D39).
    public private(set) var savedAt: Date?
    public private(set) var offlineRead = false
    /// The tab filtered to one student (U42, P14-School-Student): what reaches them, until Show all, a link or the tab
    /// bar clears it.
    public var filter: UUID?

    let workspace: Workspace
    private let repository: any SchoolItemsRepository
    private let register: any Register
    private let schoolsRepository: any SchoolsRepository
    private let cache: SchoolCache?
    private let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        workspace: Workspace, items: any SchoolItemsRepository, register: any Register,
        schools: any SchoolsRepository, cache: SchoolCache?, now: @escaping @Sendable () -> Date, calendar: Calendar
    ) {
        self.workspace = workspace
        repository = items
        self.register = register
        schoolsRepository = schools
        self.cache = cache
        self.now = now
        self.calendar = calendar
        month = Day(now(), calendar: calendar).period
    }

    public func previousMonth() {
        month = month.previous
    }

    public func nextMonth() {
        month = month.next
    }

    public var today: Day {
        Day(now(), calendar: calendar)
    }

    /// The list from today on: This week, Next week, Later.
    public var buckets: [(title: String, rows: [SchoolRowModel])] {
        SchoolItemRules.buckets(shown, today: today, calendar: calendar).map { ($0.title, $0.items.map(row)) }
    }

    /// Each day an item stands on, with its kinds (a holiday on each of its days).
    public var dots: [Day: [CalendarDot]] {
        var dots: [Day: [CalendarDot]] = [:]
        for item in shown {
            let span = max(0, item.date.days(to: item.lastDay))
            for offset in 0 ... span {
                let day = item.date.adding(days: offset, calendar: calendar)
                let dot = SchoolWords.dot(item.kind)
                if !(dots[day] ?? []).contains(dot) {
                    dots[day, default: []].append(dot)
                }
            }
        }
        return dots
    }

    /// The chosen day's items (the calendar's list), today's at first.
    public var dayRows: [SchoolRowModel] {
        let day = selectedDay ?? today
        return shown.filter { $0.date <= day && day <= $0.lastDay }
            .sorted { $0.title < $1.title }
            .map(row)
    }

    /// The items the list and the calendar show: the filtered student's, else all.
    var shown: [SchoolItem] {
        guard let student = filteredStudent else { return items }
        return items.filter { SchoolItemRules.reaches($0, student) }
    }

    private var filteredStudent: Student? {
        filter.flatMap { register.student($0) }
    }

    /// "Dev's items".
    public var filterChip: String? {
        filteredStudent.map { "\($0.firstName)'s items" }
    }

    /// Under the list while filtered.
    public var filterLine: String? {
        filteredStudent.map {
            "What reaches \($0.firstName): their own items, their class's and their school's. "
                + "Show all lists the centre's."
        }
    }

    public var filterInitials: String {
        filteredStudent.map { NameInitials.of($0.name) } ?? ""
    }

    public func showAll() {
        filter = nil
    }

    /// The copy at once, then the read (D76); a failed read keeps what is shown.
    public func load() async {
        await read(showingCopy: items.isEmpty)
    }

    public func refresh() async {
        await read(showingCopy: false)
    }

    private func read(showingCopy: Bool) async {
        await register.loadIfNeeded()
        if let read = try? await schoolsRepository.schools(centre: workspace.centre.id) {
            schools = read
        }
        let (repository, centre, cache) = (repository, workspace.centre.id, cache)
        let reader = CopyFirst<[SchoolItem]>(
            copy: { cache?.load() }, keep: { items, at in cache?.keep(items, at: at) }, now: now
        )
        let outcome = await reader.load(showingCopy: showingCopy) { read, at in
            items = read
            savedAt = at
            state = read.isEmpty ? .empty : .items
        } read: {
            try await repository.items(centre: centre)
        }
        guard outcome.failure != nil else {
            offlineRead = false
            return
        }
        offlineRead = true
        if case .nothing = outcome, items.isEmpty {
            state = .failed
        } else {
            state = .offline
        }
    }

    func row(_ item: SchoolItem) -> SchoolRowModel {
        let column = SchoolWords.dayColumn(item.date)
        return SchoolRowModel(
            id: item.id, day: column.day, date: column.date, title: item.title,
            line: SchoolItemRules.line(item, today: today, students: register.activeStudents, schools: schools),
            kind: SchoolWords.kind(item.kind)
        )
    }
}
