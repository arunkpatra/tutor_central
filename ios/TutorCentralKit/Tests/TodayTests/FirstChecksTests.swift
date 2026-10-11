import Data
import Domain
import Foundation
import Testing
@testable import Today

/// A new batch's first checks (the owner, 2026-10-11): a group /ai/plan names writes each member's chapter and skill,
/// so
/// the first close offers checks on their own skills.
@MainActor struct FirstChecksTests {
    var nikhil: Student {
        PlanTest.members.first { $0.id == FakeStudentsRepository.nikhil }!
    }

    func plan(_ plans: FakePlansRepository) async throws -> PlanRecord {
        try #require(try await plans.plan(
            centre: PlanTest.centre, classID: PlanTest.evening.id, date: PlanTest.wednesday
        ))
    }

    @Test func aGroupNamedByThePlanWritesEachMembersChapterAndSkill() async throws {
        let plans = FakePlansRepository(), textbooks = FakeTextbooksRepository.evening()
        let maker = PlanTest.maker(plans: plans, textbooks: textbooks)
        await maker.make(PlanTest.batch([nikhil]), choices: nil) { _ in }
        let made = try await plan(plans)
        let group = try #require(made.groups.first)
        let chapters = textbooks.chaptersByStudent[nikhil.id] ?? []
        let skills = textbooks.skillsByStudent[nikhil.id] ?? []
        #expect(chapters.map(\.name) == [group.chapter] && chapters.first?.subject == group.subject)
        #expect(skills.map(\.name) == [group.skill])
        let teach = made.items(of: nikhil.id).first { $0.kind == .teach }
        #expect(teach?.words == "Teach: \(group.skill)" && teach?.skillID == skills.first?.id)
    }

    @Test func theFirstCloseThenHasChecksOnTheirOwnSkills() async throws {
        let plans = FakePlansRepository(), textbooks = FakeTextbooksRepository.evening()
        await PlanTest.maker(plans: plans, textbooks: textbooks).make(PlanTest.batch([nikhil]), choices: nil) { _ in }
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await CloseStoreTests().store(attendance: attendance, textbooks: textbooks, plans: plans)
        let index = try #require(store.students.firstIndex { $0.id == nikhil.id })
        guard case let .rows(rows) = store.students[index].checks else {
            Issue.record("Nikhil has no check rows")
            return
        }
        #expect(rows.count == 3)
        store.tap(index, 0, right: true)
        #expect(await store.done())
        let check = try #require(attendance.closes.last?.checks.first { $0.studentID == nikhil.id })
        #expect(textbooks.skillsByStudent[nikhil.id]?.contains { $0.id == check.skillID } == true)
    }

    @Test func aMemberWhoAlreadyHasTheChapterGetsNoSecond() async throws {
        let plans = FakePlansRepository(), textbooks = FakeTextbooksRepository.evening()
        // The topic /ai/plan gives this group, from a make with no writes.
        let probe = FakePlansRepository(), refusing = FakeTextbooksRepository.evening()
        refusing.writeFailure = URLError(.badServerResponse)
        await PlanTest.maker(plans: probe, textbooks: refusing).make(PlanTest.batch([nikhil]), choices: nil) { _ in }
        let named = try #require(try await plan(probe).groups.first)
        let existing = Chapter(id: UUID(), subject: named.subject, position: 1, name: named.chapter)
        textbooks.chaptersByStudent[nikhil.id] = [existing]
        await PlanTest.maker(plans: plans, textbooks: textbooks).make(PlanTest.batch([nikhil]), choices: nil) { _ in }
        #expect(textbooks.chaptersByStudent[nikhil.id]?.count == 1)
        let skills = textbooks.skillsByStudent[nikhil.id] ?? []
        #expect(skills.map(\.name) == [named.skill] && skills.first?.chapterID == existing.id)
    }

    @Test func aFailedWriteLeavesTheGroupNamedWithNoOwnSkill() async throws {
        let plans = FakePlansRepository(), textbooks = FakeTextbooksRepository.evening()
        let maker = PlanTest.maker(plans: plans, textbooks: textbooks)
        textbooks.writeFailure = URLError(.badServerResponse)
        await maker.make(PlanTest.batch([nikhil]), choices: nil) { _ in }
        let made = try await plan(plans)
        let teach = made.items(of: nikhil.id).first { $0.kind == .teach }
        #expect(teach?.words == "Teach: \(made.groups[0].skill)" && teach?.skillID == nil)
        #expect(textbooks.chaptersByStudent[nikhil.id]?.isEmpty ?? true)
    }
}
