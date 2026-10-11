import Data
import Domain
import Foundation
import Observation
import UIKit

/// "Check what was read" (P10-School-Confirm, P13-School-Reading; plan/phase-13-plan.md decision 1): what the school
/// sent read by `/ai/parse-school` into drafts the tutor ticks, opens and adds. Nothing is kept before Add; the
/// inbox item is removed once its items are added or the screen is left.
@MainActor @Observable public final class ReadStore {
    public enum Stage: Hashable, Sendable { case reading, read, adding, added([SchoolItem]), failed(String) }

    public private(set) var stage: Stage = .reading
    public let source: ReadSource
    public private(set) var drafts: [SchoolItemDraft] = []
    /// A refused or failed write, for the system alert.
    public var message: String?
    public var online: @Sendable () async -> Bool

    let workspace: Workspace
    let register: any Register
    private let items: any SchoolItemsRepository
    private let ai: any AIRepository
    private let schoolsRepository: any SchoolsRepository
    private let photos: any PhotoStore
    private let leaveInbox: (@MainActor () -> Void)?
    private let now: @Sendable () -> Date
    let calendar: Calendar
    public private(set) var schools: [School] = []
    private var left = false

    public init(
        source: ReadSource, workspace: Workspace, items: any SchoolItemsRepository, ai: any AIRepository,
        register: any Register, schools: any SchoolsRepository, photos: any PhotoStore,
        leaveInbox: (@MainActor () -> Void)?, now: @escaping @Sendable () -> Date, calendar: Calendar,
        online: @escaping @Sendable () async -> Bool
    ) {
        self.source = source
        self.workspace = workspace
        self.items = items
        self.ai = ai
        self.register = register
        schoolsRepository = schools
        self.photos = photos
        self.leaveInbox = leaveInbox
        self.now = now
        self.calendar = calendar
        self.online = online
    }

    public var today: Day {
        Day(now(), calendar: calendar)
    }

    /// The text the school sent, for the source well.
    public var sourceText: String? {
        switch source {
        case let .pasted(text): text
        case let .shared(read): read.text
        case .photo, .typed: nil
        }
    }

    public var sourceImage: UIImage? {
        switch source {
        case let .photo(upload): UIImage(data: upload.data)
        case let .shared(read): read.image.flatMap { UIImage(data: $0.data) }
        case .pasted, .typed: nil
        }
    }

    /// "3 items read".
    public var countLine: String {
        drafts.count == 1 ? "1 item read" : "\(drafts.count) items read"
    }

    private var addable: [SchoolItemDraft] {
        drafts.filter { $0.ticked && $0.isComplete }
    }

    /// "Add 3 items", "Add an item", "Add" when none can be added.
    public var addLabel: String {
        switch addable.count {
        case 0: "Add"
        case 1: "Add an item"
        case let count: "Add \(count) items"
        }
    }

    public var canAdd: Bool {
        stage == .read && !addable.isEmpty
    }

    /// `/ai/parse-school` with today's date, the centre's schools and class levels; Add by hand reads nothing.
    public func read() async {
        await register.loadIfNeeded()
        if let read = try? await schoolsRepository.schools(centre: workspace.centre.id) {
            schools = read
        }
        guard let parse = parseSource else {
            stage = .read
            return
        }
        guard await online() else {
            message = OfflineRefusal.words(for: .readSchool)
            stage = .read
            return
        }
        stage = .reading
        let levels = Array(Set(register.activeStudents.compactMap(\.classLevel))).sorted()
        do {
            let reading = try await ai.parseSchool(
                parse, today: today, schools: schools.map(\.name), classLevels: levels, centre: workspace.centre.id
            )
            drafts = reading.items.map {
                DraftResolver.resolve($0, source: source, schools: schools, students: register.activeStudents)
            }
            stage = .read
        } catch {
            stage = .failed(error.words)
        }
    }

    public func toggle(_ id: UUID) {
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[index].ticked.toggle()
    }

    /// A draft checked on its sheet: ticked once it is complete.
    public func replace(_ draft: SchoolItemDraft) {
        var changed = draft
        changed.ticked = draft.isComplete
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index] = changed
        } else {
            drafts.append(changed)
        }
    }

    public func remove(_ id: UUID) {
        drafts.removeAll { $0.id == id }
    }

    /// The ticked complete drafts in one insert, the photo uploaded first; the inbox item removed after.
    public func add() async -> Bool {
        guard canAdd else { return false }
        guard await online() else {
            message = OfflineRefusal.words(for: .schoolItem)
            return false
        }
        stage = .adding
        do {
            var path: String?
            if let upload = imageUpload {
                path = try await photos.add(upload.data, centre: workspace.centre.id, kind: "item")
            }
            let added = try await items.add(addable, photoPath: path, centre: workspace.centre.id)
            stage = .added(added)
            removeInbox()
            return true
        } catch {
            stage = .read
            message = "That didn't go through. Check your connection and try again. What was read is still here."
            return false
        }
    }

    /// Back or Cancel: the inbox item goes; nothing read is kept.
    public func leave() {
        removeInbox()
    }

    private func removeInbox() {
        guard !left else { return }
        left = true
        leaveInbox?()
    }

    private var parseSource: SchoolSource? {
        switch source {
        case let .photo(upload): .image(upload)
        case let .pasted(text): .text(text)
        case let .shared(read): read.image.map(SchoolSource.image) ?? read.text.map(SchoolSource.text)
        case .typed: nil
        }
    }

    private var imageUpload: ImageUpload? {
        switch source {
        case let .photo(upload): upload
        case let .shared(read): read.image
        case .pasted, .typed: nil
        }
    }
}

private extension Error {
    var words: String {
        (self as? APIFailure)?.words ?? "That didn't go through. Check your connection and try again."
    }
}
