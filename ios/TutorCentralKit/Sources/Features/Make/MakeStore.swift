import Data
import Domain
import Foundation
import Observation

/// Make something for one centre (`ShellState.make`, plan/phase-15-plan.md decisions 5 and 30): what Make made and
/// V1's results together for Recent and History, each with its copy on this iPhone. V1's results and its forms stay the
/// Assistant's store (`AIStore`), read through here.
@MainActor @Observable public final class MakeStore {
    /// What a row opens: a Make artefact's screen, or a V1 result.
    public enum Opens: Hashable, Sendable {
        case artefact(UUID), generation(UUID)
    }

    public struct Row: Identifiable, Hashable, Sendable {
        public var id: Opens {
            opens
        }

        public let symbol: String
        public let title: String
        public let line: String
        public let opens: Opens
        public let at: Date
    }

    public internal(set) var workspace: Workspace
    /// What Make made, newest first, a regenerated one in its predecessor's place.
    public private(set) var made: [Artefact] = []
    public private(set) var madeLoaded = false
    /// When the list on screen was saved on this iPhone, until the network replaces it (D39).
    public private(set) var madeSavedAt: Date?
    public private(set) var madeOfflineRead = false
    private var madeError: String?
    /// The list's copy on this iPhone (AppShell's).
    public var madeCache: CachedRead<[Artefact]>?

    let register: any Register
    let plans: any PlansRepository
    /// V1's results, its forms and its one call (the Assistant's store).
    public let ai: AIStore
    let now: @Sendable () -> Date
    let calendar: Calendar

    public init(
        workspace: Workspace, register: any Register, plans: any PlansRepository, ai: AIStore,
        now: @escaping @Sendable () -> Date, calendar: Calendar = DayHeading.india
    ) {
        self.workspace = workspace
        self.register = register
        self.plans = plans
        self.ai = ai
        self.now = now
        self.calendar = calendar
    }

    public func workspaceChanged(_ workspace: Workspace) {
        self.workspace = workspace
    }

    /// Both lists have answered (from the network or this iPhone's copy).
    public var historyLoaded: Bool {
        madeLoaded && ai.historyLoaded
    }

    /// The words for a list that could not load and has nothing saved.
    public var historyError: String? {
        madeError ?? (ai.historyLoaded ? nil : ai.historyError)
    }

    /// The empty row: only once both have loaded with nothing in either.
    public var showsEmpty: Bool {
        historyLoaded && rows.isEmpty
    }

    /// The list on screen came from this iPhone's copy: the older of the two saves.
    public var savedAt: Date? {
        [madeSavedAt, ai.historySavedAt].compactMap(\.self).min()
    }

    public var offlineRead: Bool {
        madeOfflineRead || ai.historyOfflineRead
    }

    public func loadHistory() async {
        await ai.prepare()
        async let results: Void = ai.loadHistory()
        await loadMade()
        await results
    }

    /// A newly made or regenerated artefact, at the top of Recent at once (its predecessor leaves the list).
    public func kept(_ artefact: Artefact) {
        made = ([artefact] + made.filter { $0.id != artefact.id }).hidingRegenerated()
    }

    private func loadMade() async {
        if !madeLoaded, let cached = madeCache?.load() {
            made = cached.value
            madeSavedAt = cached.savedAt
            madeLoaded = true
        }
        do {
            let loaded = try await plans.made(centre: workspace.centre.id)
            madeCache?.keep(loaded, at: now())
            made = loaded
            madeSavedAt = nil
            madeOfflineRead = false
            madeLoaded = true
            madeError = nil
        } catch {
            if TransportError.isCancelled(error) {
                return
            }
            madeOfflineRead = TransportError.isOffline(error)
            madeError = madeLoaded && madeOfflineRead ? nil : MakeWords.historyFailed
        }
    }
}
