import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

/// Share takes the server's PDF of a made sheet (plan decision 3): the questions, or the key's form; without it (not
/// made yet, offline) the phone draws its own.
@MainActor struct ServerPDFShareTests {
    func sheet(
        online: Bool = true, wait: Duration = .seconds(5), download: @escaping ServerFiles.Download
    ) async throws -> (SheetStore, UUID) {
        let plans = FakePlansRepository.evening()
        let plan = try #require(try await ArtefactTest.plan(plans))
        let id = try #require(plan.artefact(group: 1, kind: .sheet, homework: true)?.id)
        let store = await SheetStore(
            artefactID: id, workspace: FakeCentreRepository.meeraWorkspace, register: ArtefactTest.register(),
            plans: plans, ai: FakeAIRepository(), photos: FakePhotoStore(), now: { ArtefactTest.at1640 },
            calendar: DayHeading.india
        )
        let centre = FakeCentreRepository.meeraWorkspace.centre.id
        let files = ServerFiles(
            centre: centre, directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString),
            download: download
        )
        store.serverPDF = ServerPDF(files: files, centre: centre, online: { online }, wait: wait)
        await store.load()
        return (store, id)
    }

    @Test func aSheetSharesTheServersFileAndItsKeyForm() async throws {
        let (store, id) = try await sheet { _, path in Data(path.utf8) }
        let centre = FakeCentreRepository.meeraWorkspace.centre.id.uuidString.lowercased()
        let paper = try #require(await store.sharedPDF())
        #expect(try String(contentsOf: paper, encoding: .utf8) == "\(centre)/\(id.uuidString.lowercased()).pdf")
        store.form = .key
        let key = try #require(await store.sharedPDF())
        #expect(try String(contentsOf: key, encoding: .utf8) == "\(centre)/\(id.uuidString.lowercased())-key.pdf")
    }

    @Test func withoutTheServersFileThePhoneDrawsItsOwn() async throws {
        let (store, _) = try await sheet { _, _ in throw URLError(.notConnectedToInternet) }
        let drawn = try #require(await store.sharedPDF())
        #expect(try Data(contentsOf: drawn).starts(with: Data("%PDF".utf8)))
    }

    /// The review's R-app-7: offline the phone draws at once, no download tried; on a stalled link it draws after the
    /// short wait, not the read's 20 s.
    @Test func offlineOrStalledThePhoneDrawsWithoutWaitingForTheDownload() async throws {
        let tried = Tried()
        let (offline, _) = try await sheet(online: false) { _, _ in
            await tried.add()
            return Data("server".utf8)
        }
        let drawn = try #require(await offline.sharedPDF())
        #expect(try Data(contentsOf: drawn).starts(with: Data("%PDF".utf8)))
        #expect(await tried.none)
        let (stalled, _) = try await sheet(wait: .milliseconds(200)) { _, _ in
            try await Task.sleep(for: .seconds(60))
            return Data("server".utf8)
        }
        let clock = ContinuousClock()
        var shared: URL?
        let took = await clock.measure { shared = await stalled.sharedPDF() }
        #expect(took < .seconds(2), "Share waited for the stalled download")
        #expect(try Data(contentsOf: #require(shared)).starts(with: Data("%PDF".utf8)))
    }

    actor Tried {
        private(set) var none = true
        func add() {
            none = false
        }
    }
}
