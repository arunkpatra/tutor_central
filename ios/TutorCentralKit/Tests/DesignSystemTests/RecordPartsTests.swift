import Testing
@testable import DesignSystem

struct RecordPartsTests {
    @Test func theTrendsBarsAndTones() {
        #expect(TrendCard.fraction(right: 3) == 1 && TrendCard.fraction(right: 0) == 0)
        #expect(TrendCard.fraction(right: 2) == 2.0 / 3)
        #expect(TrendCard.tone(right: 3) == .ok && TrendCard.tone(right: 2) == .due && TrendCard
            .tone(right: 1) == .overdue)
        #expect(TrendCard.tone(right: 0) == .overdue)
    }

    @Test func theStateMarksWordsSymbolsAndTones() {
        #expect(SkillMark.secure.word == "Secure" && SkillMark.revisit.symbol == "exclamationmark.circle")
        #expect(SkillMark.notStarted.tone == nil && SkillMark.practising.tone == .due && SkillMark.secure.tone == .ok)
        #expect(SkillMark.taught.word == "Taught" && SkillMark.notStarted.word == "Not started")
    }

    @Test func aLadderStepIsSecureCurrentOrToCome() {
        #expect(LadderRow.stepKinds(secure: 2, of: 5) == [.secure, .secure, .current, .later, .later])
        #expect(LadderRow.stepKinds(secure: 5, of: 5) == [.secure, .secure, .secure, .secure, .secure])
    }
}
