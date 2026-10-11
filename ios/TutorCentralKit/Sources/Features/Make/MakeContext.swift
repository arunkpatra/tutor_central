import Data
import Domain
import Foundation

/// What a Make form reads and calls, given by AppShell.
public struct MakeContext {
    let workspace: Workspace
    let register: any Register
    let plans: any PlansRepository
    let textbooks: any TextbooksRepository
    let schoolItems: (any SchoolItemsRepository)?
    let ai: any AIRepository
    let online: () async -> Bool
    let now: @Sendable () -> Date
    let calendar: Calendar
    /// Where the last target of each kind is kept on this iPhone (wiped at sign-out); nil keeps nothing.
    let defaults: UserDefaults?

    public init(
        workspace: Workspace, register: any Register, plans: any PlansRepository, textbooks: any TextbooksRepository,
        schoolItems: (any SchoolItemsRepository)?, ai: any AIRepository, online: @escaping () async -> Bool,
        now: @escaping @Sendable () -> Date, calendar: Calendar, defaults: UserDefaults?
    ) {
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.textbooks = textbooks
        self.schoolItems = schoolItems
        self.ai = ai
        self.online = online
        self.now = now
        self.calendar = calendar
        self.defaults = defaults
    }

    var today: Day {
        Day(now(), calendar: calendar)
    }
}

/// The mock's exam: one of the student's coming exams, or typed when there is none.
public enum ExamChoice: Hashable, Sendable {
    case item(SchoolItem)
    case typed(subject: String, title: String, portions: String)

    var title: String {
        switch self {
        case let .item(item): item.title
        case let .typed(_, title, _): title
        }
    }
}

/// What Make did, for AppShell to show.
public enum MakeOutcome: Hashable, Sendable {
    /// Kept: open the artefact's screen.
    case made(Artefact)
    /// Phase 14's note for the student and the note day, with the tutor's words (decision 7).
    case opensNote(UUID, Day, tutorSays: String?)
    /// The exam's mock already made: open it (decision 8).
    case opensExisting(UUID)
    /// Refused before any call (offline, no consent, one already running): `alert` says why.
    case refused
    /// The call failed: the error row says why.
    case failed
}

/// Today's plan groups, read for the For sheet and a group's level and skill: the plans of the batches meeting today.
@MainActor enum TodayGroups {
    static func read(_ context: MakeContext) async -> [TodayGroup] {
        let today = context.today
        let weekday = today.weekday(in: context.calendar)
        var groups: [TodayGroup] = []
        for batch in context.register.activeClasses where batch.meetingDays.contains(weekday) {
            guard let plan = await (try? context.plans.plan(
                centre: context.workspace.centre.id, classID: batch.id, date: today
            )) ?? nil else { continue }
            groups += plan.groups.map { TodayGroup(planID: plan.id, classID: batch.id, group: $0) }
        }
        return groups
    }
}
