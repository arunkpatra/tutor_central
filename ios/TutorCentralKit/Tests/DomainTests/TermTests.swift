import Testing
@testable import Domain

/// The school term (plan/phase-15-plan.md decision 15; Review focus 3).
struct TermTests {
    @Test func termTwoSpansTheNewYear() {
        let term = Term(schoolYear: 2026, number: 2, calendar: .standard)
        #expect(term.months.first == Period(year: 2026, month: 10) && term.months.last == Period(year: 2027, month: 3))
        #expect(term.months.count == 6)
        #expect(term.title == "Term 2 · October to March" && term.fileStem == "term-2-2026")
    }

    @Test func termOneIsJuneToSeptember() {
        let term = Term(schoolYear: 2026, number: 1, calendar: .standard)
        #expect(term.title == "Term 1 · June to September" && term.months.count == 4)
    }

    @Test func theTermBeforeTermOneIsLastYearsTermTwo() {
        #expect(Term(schoolYear: 2026, number: 1, calendar: .standard).previous
            == Term(schoolYear: 2025, number: 2, calendar: .standard))
        #expect(Term(schoolYear: 2025, number: 2, calendar: .standard).next
            == Term(schoolYear: 2026, number: 1, calendar: .standard))
        #expect(Term(schoolYear: 2026, number: 1, calendar: .standard).next
            == Term(schoolYear: 2026, number: 2, calendar: .standard))
    }

    @Test func theKarnatakaYearEndsInApril() {
        let two = Term(schoolYear: 2026, number: 2, calendar: .karnataka)
        #expect(two.months.first == Period(year: 2026, month: 11) && two.months.last == Period(year: 2027, month: 4))
        #expect(Term(schoolYear: 2026, number: 1, calendar: .karnataka).title == "Term 1 · June to October")
        #expect(two.title == "Term 2 · November to April")
    }

    @Test func octoberIsTermTwoAndMayIsTermTwoOfTheYearBefore() throws {
        #expect(try Term.containing(#require(Day(year: 2026, month: 10, day: 7)), calendar: .standard)
            == Term(schoolYear: 2026, number: 2, calendar: .standard))
        #expect(try Term.containing(#require(Day(year: 2026, month: 5, day: 3)), calendar: .standard)
            == Term(schoolYear: 2025, number: 2, calendar: .standard))
        #expect(try Term.containing(#require(Day(year: 2026, month: 10, day: 7)), calendar: .karnataka)
            == Term(schoolYear: 2026, number: 1, calendar: .karnataka))
        #expect(try Term.containing(#require(Day(year: 2027, month: 1, day: 7)), calendar: .karnataka)
            == Term(schoolYear: 2026, number: 2, calendar: .karnataka))
    }

    @Test func theCentresCalendarIsTheCommonBoard() {
        #expect(Term.calendar(for: [.karnataka, .karnataka, .cbse, nil]) == .karnataka)
        #expect(Term.calendar(for: [.karnataka, .cbse]) == .standard)
        #expect(Term.calendar(for: []) == .standard)
    }

    @Test func aTermHasEndedOnceItsLastMonthHasGone() throws {
        let one = Term(schoolYear: 2026, number: 1, calendar: .standard)
        #expect(try one.hasEnded(#require(Day(year: 2026, month: 10, day: 1))))
        #expect(try !one.hasEnded(#require(Day(year: 2026, month: 9, day: 30))))
    }
}
