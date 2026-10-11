import Data
import DesignSystem
import Domain
import Foundation
import Testing
@testable import Artefacts

/// Make's artefacts on their screens (plan/phase-15-plan.md decision 6; Review focus 5): the eyebrow from `made_for`
/// with no plan, Make it again keeping `made_from` and the target, the sheet's key at the end.
@MainActor struct MakeArtefactsTests {
    func sheet(_ plans: FakePlansRepository, _ id: UUID = FakePlansRepository.madeSheetID, ai: FakeAIRepository) async
        -> SheetStore {
        let store = await SheetStore(
            artefactID: id, workspace: FakeCentreRepository.meeraWorkspace, register: ArtefactTest.register(),
            plans: plans, ai: ai, photos: FakePhotoStore(), now: { ArtefactTest.at1640 }, calendar: DayHeading.india
        )
        await store.load()
        return store
    }

    @Test func aMakeArtefactsEyebrowNamesItsTarget() {
        let made = MakeFor(
            target: .student(FakeStudentsRepository.dev), title: "For Dev",
            line: "Class 8 Science · Balancing equations"
        )
        #expect(ArtefactWords.eyebrow(madeFor: made) == "For Dev · Class 8 Science · Balancing equations")
    }

    @Test func aMakeSheetsHeroNamesItsTarget() async {
        let store = await sheet(FakePlansRepository(artefacts: FakePlansRepository.madeRecent), ai: FakeAIRepository())
        #expect(store.eyebrow == "Group 1 · Class 8 Science · Balancing equations")
        #expect(store.line == "10 questions · made today, 16:40")
    }

    @Test func makeItAgainOnAMakeSheetKeepsMadeFromAndTheTarget() async throws {
        let plans = FakePlansRepository(artefacts: FakePlansRepository.madeRecent)
        let ai = FakeAIRepository()
        let store = await sheet(plans, ai: ai)
        let old = try #require(store.artefact)
        await store.makeAgain(.easier)
        let new = try #require(store.artefact)
        #expect(new.id != old.id && new.regeneratedFrom == old.id && store.message == nil)
        #expect(new.madeFrom == "make" && new.madeFor == old.madeFor && new.planID == nil)
        #expect(ai.sheetRequests.last == SheetRequest(
            classLevel: .eight, subject: "Science", skills: ["Balancing equations"], questions: 10, forHomework: false,
            reason: "easier"
        ))
        #expect(try await plans.made(centre: ArtefactTest.centre).first?.id == new.id)
    }

    /// The review's R-app-3: "Key at the end" is "For you; left out of what you share" (P10-Make-Form): Print carries
    /// the
    /// key after the questions, Share as PDF on the Paper form never does.
    @Test func aMakeSheetWithKeyAtEndPrintsTheKeyAfterTheQuestions() async throws {
        let made = MakeFor(
            target: .classLevel(.eight), title: "Class 8", line: "Science · Balancing equations", level: .eight,
            subject: "Science", skills: ["Balancing equations"], keyAtEnd: true
        )
        let plans = FakePlansRepository()
        let kept = try await plans.keepMade(
            NewArtefact(
                kind: .sheet, source: .made, title: "Balancing equations · sheet",
                content: .sheet(AISamples.sheet(questions: 6, forHomework: false, light: false)), photoPath: nil,
                generationID: nil, regeneratedFrom: nil
            ).made(for: made), student: nil, exam: nil, centre: ArtefactTest.centre
        )
        let store = await sheet(plans, kept.id, ai: FakeAIRepository())
        let hasKey = { (sheet: PDFSheet) in
            sheet.blocks.contains {
                if case .key = $0 {
                    true
                } else {
                    false
                }
            }
        }
        #expect(hasKey(store.printSheet))
        if case .key? = store.printSheet.blocks.last {} else {
            Issue.record("the key is not last")
        }
        #expect(!hasKey(store.pdfSheet), "the shared PDF carries no key")
        store.form = .key
        #expect(hasKey(store.pdfSheet), "the Key form shares the key, as before")
    }

    @Test func makeItAgainOnAMakeBriefKeepsTheTarget() async throws {
        let plans = FakePlansRepository(artefacts: FakePlansRepository.madeRecent)
        let ai = FakeAIRepository()
        let store = await BriefStore(
            artefactID: FakePlansRepository.madeBriefID, workspace: FakeCentreRepository.meeraWorkspace,
            register: ArtefactTest.register(), plans: plans, ai: ai, now: { ArtefactTest.at1640 },
            calendar: DayHeading.india
        )
        await store.load()
        #expect(store.eyebrow == "Class 8 · Science · Chemical reactions")
        await store.makeAgain()
        #expect(ai.briefs.last == "Chemical reactions")
        let made = try await plans.made(centre: ArtefactTest.centre)
        #expect(made.first?.kind == .brief && made.first?.madeFor?.title == "Class 8")
        #expect(made.first?.regeneratedFrom == FakePlansRepository.madeBriefID)
    }

    @Test func makeItAgainOnAMakeMockKeepsTheTarget() async throws {
        let plans = FakePlansRepository(artefacts: FakePlansRepository.madeRecent)
        let store = await MockStore(
            artefactID: FakePlansRepository.madeMockID, workspace: FakeCentreRepository.meeraWorkspace,
            register: ArtefactTest.register(), plans: plans, ai: FakeAIRepository(),
            schoolItems: FakeSchoolItemsRepository(items: []), schools: FakeSchoolsRepository(),
            now: { ArtefactTest.at1640 }, calendar: DayHeading.india
        )
        await store.load()
        #expect(store.eyebrow == "For Dev · Class 8 Science")
        #expect(await store.again())
        let made = try await plans.made(centre: ArtefactTest.centre)
        #expect(made.first?.kind == .mock && made.first?.madeFor?.title == "For Dev")
        #expect(made.first?.studentID == FakeStudentsRepository.dev)
    }

    @Test func useMyOwnOnAMakeSheetKeepsItAsMakesAndTheMadeOneComesBack() async throws {
        let plans = FakePlansRepository(artefacts: FakePlansRepository.madeRecent)
        let store = await sheet(plans, ai: FakeAIRepository())
        await store.useOwn(text: "Do exercise 3.2, questions 1 to 10.")
        #expect(store.message == nil && store.artefact?.source == .own && store.artefact?.isMade == true)
        #expect(try await plans.made(centre: ArtefactTest.centre).first?.source == .own)
        await store.useMadeInstead()
        let back = try #require(store.artefact)
        #expect(store.message == nil && back.source == .made && back.isMade)
        #expect(back.content == FakePlansRepository.madeRecent[0].content)
        #expect(try await plans.made(centre: ArtefactTest.centre).first?.id == back.id)
    }
}
