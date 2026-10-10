import Data
import Domain
import Foundation
import SwiftUI

/// Everything a store needs, given through the environment; previews and `bun shots` give fakes (Fixtures).
public struct Dependencies: Sendable {
    public let auth: any AuthRepository
    public let centres: any CentreRepository
    public let counts: any CountsRepository
    public let students: any StudentsRepository
    public let classes: any ClassesRepository
    public let attendance: any AttendanceRepository
    public let messages: any MessageLogRepository
    /// V2's record (Phase 11): the schools, the textbooks and each student's chapters and skills, the checks and
    /// homework.
    public let schools: any SchoolsRepository
    public let textbooks: any TextbooksRepository
    public let record: any RecordRepository
    /// The day's plans and their artefacts (Phase 12); the `photos` bucket (the tutor's own sheets).
    public let plans: any PlansRepository
    public let photos: any PhotoStore
    public let events: any EventsRepository
    public let tasks: any TasksRepository
    public let fees: any FeesRepository
    /// The UPI QR image, kept on this iPhone only.
    public let qrImages: any QRImageStore
    /// Our API's AI routes (never Anthropic's: D11) and the results it recorded.
    public let ai: any AIRepository
    public let aiHistory: any AIHistoryRepository
    /// The API's account route (D38): Apple told to forget the app before a deletion.
    public let account: any AccountRepository
    /// The device's notification centre and the tutor's reminder choices on this iPhone.
    public let notifications: any NotificationCenterClient
    public let reminderSettings: ReminderSettingsStore
    /// The network (D39): the offline bar and the replay follow it.
    public let connectivity: any ConnectivityMonitor
    /// The lists keep a copy on this iPhone (`CachedRead`); the fixtures write theirs into `filesDirectory`.
    public let cachesLists: Bool
    /// Where this iPhone's files go (the queue, the lists' caches): nil is Application Support/TutorCentral; the
    /// fixtures give a fresh temporary folder, so `bun shots` never touches the app's own files.
    public let filesDirectory: URL?
    /// The register is kept on disk for the next launch (`RegisterCache`); the fixtures never write a file.
    public let cachesRegister: Bool
    public let now: @Sendable () -> Date
    /// The fixtures hold their moment: Today's minute clock does not run (`bun shots`).
    public let fixedClock: Bool
    /// "0.1 (12)": the marketing version and the build.
    public let bundleVersion: String

    public init(
        auth: any AuthRepository,
        centres: any CentreRepository,
        counts: any CountsRepository,
        students: any StudentsRepository,
        classes: any ClassesRepository,
        attendance: any AttendanceRepository,
        messages: any MessageLogRepository,
        schools: any SchoolsRepository,
        textbooks: any TextbooksRepository,
        record: any RecordRepository,
        plans: any PlansRepository,
        photos: any PhotoStore,
        events: any EventsRepository,
        tasks: any TasksRepository,
        fees: any FeesRepository,
        qrImages: any QRImageStore,
        ai: any AIRepository,
        aiHistory: any AIHistoryRepository,
        account: any AccountRepository,
        notifications: any NotificationCenterClient,
        reminderSettings: ReminderSettingsStore,
        connectivity: any ConnectivityMonitor,
        cachesLists: Bool,
        filesDirectory: URL? = nil,
        cachesRegister: Bool,
        now: @escaping @Sendable () -> Date,
        fixedClock: Bool = false,
        bundleVersion: String
    ) {
        self.auth = auth
        self.centres = centres
        self.counts = counts
        self.students = students
        self.classes = classes
        self.attendance = attendance
        self.messages = messages
        self.schools = schools
        self.textbooks = textbooks
        self.record = record
        self.plans = plans
        self.photos = photos
        self.events = events
        self.tasks = tasks
        self.fees = fees
        self.qrImages = qrImages
        self.ai = ai
        self.aiHistory = aiHistory
        self.account = account
        self.notifications = notifications
        self.reminderSettings = reminderSettings
        self.connectivity = connectivity
        self.cachesLists = cachesLists
        self.filesDirectory = filesDirectory
        self.cachesRegister = cachesRegister
        self.now = now
        self.fixedClock = fixedClock
        self.bundleVersion = bundleVersion
    }

    /// "1.0.0 (14)": the marketing version and the build, as Settings' About and Help show them.
    static func version(from info: [String: Any]) -> String {
        "\(info["CFBundleShortVersionString"] ?? "0") (\(info["CFBundleVersion"] ?? "0"))"
    }

    /// The real thing, from Info.plist (SupabaseConfig) and the bundle's version strings.
    public static func live() throws -> Dependencies {
        let config = try SupabaseConfig.fromMainBundle()
        let client = SupabaseClientFactory.make(config)
        let version = version(from: Bundle.main.infoDictionary ?? [:])
        // supabase-swift refreshes the session before it hands the token over.
        let api = APIClient(origin: config.apiOrigin, token: { try await client.auth.session.accessToken })
        return Dependencies(
            auth: SupabaseAuthRepository(client: client),
            centres: SupabaseCentreRepository(client: client),
            counts: SupabaseCountsRepository(client: client),
            students: SupabaseStudentsRepository(client: client),
            classes: SupabaseClassesRepository(client: client),
            attendance: SupabaseAttendanceRepository(client: client),
            messages: SupabaseMessageLogRepository(client: client),
            schools: SupabaseSchoolsRepository(client: client),
            textbooks: SupabaseTextbooksRepository(client: client),
            record: SupabaseRecordRepository(client: client),
            plans: SupabasePlansRepository(client: client),
            photos: SupabasePhotoStore(client: client),
            events: SupabaseEventsRepository(client: client),
            tasks: SupabaseTasksRepository(client: client),
            fees: SupabaseFeesRepository(client: client),
            qrImages: FileQRImageStore(),
            ai: api,
            aiHistory: SupabaseAIHistoryRepository(client: client),
            account: api,
            notifications: UNClient(),
            reminderSettings: ReminderSettingsStore(),
            connectivity: PathMonitor(),
            cachesLists: true,
            cachesRegister: true,
            now: { Date() },
            bundleVersion: version
        )
    }
}
