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
    public let events: any EventsRepository
    public let tasks: any TasksRepository
    public let fees: any FeesRepository
    /// The UPI QR image, kept on this iPhone only.
    public let qrImages: any QRImageStore
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
        events: any EventsRepository,
        tasks: any TasksRepository,
        fees: any FeesRepository,
        qrImages: any QRImageStore,
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
        self.events = events
        self.tasks = tasks
        self.fees = fees
        self.qrImages = qrImages
        self.cachesRegister = cachesRegister
        self.now = now
        self.fixedClock = fixedClock
        self.bundleVersion = bundleVersion
    }

    /// The real thing, from Info.plist (SupabaseConfig) and the bundle's version strings.
    public static func live() throws -> Dependencies {
        let client = try SupabaseClientFactory.make(SupabaseConfig.fromMainBundle())
        let info = Bundle.main.infoDictionary ?? [:]
        let version = "\(info["CFBundleShortVersionString"] ?? "0") (\(info["CFBundleVersion"] ?? "0"))"
        return Dependencies(
            auth: SupabaseAuthRepository(client: client),
            centres: SupabaseCentreRepository(client: client),
            counts: SupabaseCountsRepository(client: client),
            students: SupabaseStudentsRepository(client: client),
            classes: SupabaseClassesRepository(client: client),
            attendance: SupabaseAttendanceRepository(client: client),
            messages: SupabaseMessageLogRepository(client: client),
            events: SupabaseEventsRepository(client: client),
            tasks: SupabaseTasksRepository(client: client),
            fees: SupabaseFeesRepository(client: client),
            qrImages: FileQRImageStore(),
            cachesRegister: true,
            now: { Date() },
            bundleVersion: version
        )
    }
}
