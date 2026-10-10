import Foundation
import Testing
@testable import Domain

struct SkillProgressTests {
    @Test func rightAndWrongMoveTheStatesAsDecided() {
        #expect(SkillProgress.after(.notStarted, correct: true, previousCorrect: nil) == .practising)
        #expect(SkillProgress.after(.taught, correct: true, previousCorrect: nil) == .practising)
        #expect(SkillProgress.after(.practising, correct: true, previousCorrect: true) == .secure)
        #expect(SkillProgress.after(.practising, correct: true, previousCorrect: false) == nil)
        #expect(SkillProgress.after(.revisit, correct: true, previousCorrect: nil) == .practising)
        #expect(SkillProgress.after(.secure, correct: true, previousCorrect: true) == nil)
        #expect(SkillProgress.after(.secure, correct: false, previousCorrect: nil) == .revisit)
        #expect(SkillProgress.after(.practising, correct: false, previousCorrect: nil) == nil)
        #expect(SkillProgress.after(.taught, correct: false, previousCorrect: nil) == nil)
    }

    @Test func thePlacementMakesTheChaptersBeforeTheFirstWrongSecure() {
        let (c1, c2, c3) = (chapter(1), chapter(2), chapter(3))
        let s1 = [skill(c1, 1), skill(c1, 2)], s2 = [skill(c2, 1)], s3 = [skill(c3, 1)]
        let changes = SkillProgress.placementChanges([.init(c1, s1, true), .init(c2, s2, nil), .init(c3, s3, false)])
        #expect(Set(changes.map(\.skillID)) == Set(s1.map(\.id)))
        #expect(changes.allSatisfy { $0.state == .secure })
        #expect(SkillProgress.placementChanges([.init(c1, s1, false), .init(c2, s2, true)]).isEmpty)
        // In position order, whatever order they are given in.
        #expect(SkillProgress.placementChanges([.init(c2, s2, true), .init(c1, s1, false)]).isEmpty)
    }
}
