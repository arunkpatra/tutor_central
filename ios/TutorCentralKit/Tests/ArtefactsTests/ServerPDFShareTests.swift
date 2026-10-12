import Data
import Domain
import Foundation
import Testing
@testable import Artefacts

/// Share takes the server's PDF of a made sheet (plan decision 3): the questions, or the key's form; without it (not
/// made yet, offline) the phone draws its own.
@MainActor struct ServerPDFShareTests {
    func sheet(download: @escaping ServerFiles.Download) async throws -> (SheetStore, UUID) {
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
        store.serverPDF = ServerPDF(files: files, centre: centre)
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
}
