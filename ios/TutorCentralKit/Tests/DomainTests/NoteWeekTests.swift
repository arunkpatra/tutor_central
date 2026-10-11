import Foundation
import Testing
@testable import Domain

struct NoteWeekTests: ParentFixtures {
    func facts(
        student: Student? = nil, chapters: [Chapter]? = nil, skills: [Skill]? = nil, checks: [CheckRecord]? = nil,
        sessions: [AttendanceSession]? = nil, marks: [MarkRecord]? = nil, items: [SchoolItem]? = nil
    ) -> NoteFacts {
        NoteWeek.facts(
            NoteRecord(
                student: student ?? dev, chapters: chapters ?? parentChapters, skills: skills ?? parentSkills(),
                checks: checks ?? devChecks, sessions: sessions ?? weekSessions(), marks: marks ?? devMarks,
                items: items ?? [unitTest]
            ),
            week: week, calendar: calendar
        )
    }

    @Test func theFactsComeFromTheWeeksRecord() {
        let facts = facts()
        #expect(facts.taught == ["Balancing equations", "Types of reactions"])
        #expect(facts.taughtLine == "Chemical reactions: balancing equations, types of reactions")
        #expect(facts.right == "8 of 12 checks · 14 of 25 on Unit test 2")
        #expect(facts.practise == ["The numbers in front of a formula"])
        #expect(facts.coming == ["Acids, bases and salts", "the unit test on Fri 16 Oct"])
        #expect(facts.attendance == "absent 2 of 3 classes" && !facts.absentAllWeek)
        #expect(facts.rows.map(\.label) == ["Taught", "Got right", "To practise", "Coming"])
        #expect(facts.rows.map(\.symbol) == ["book.closed", "checkmark.circle", "pencil.line", "calendar"])
    }

    @Test func aSkillTaughtEarlierThatMovedOnThisWeekIsNotToldAsTaught() {
        var skills = parentSkills()
        // Writing a word equation, taught weeks ago, made secure on Tuesday: it moved this week but was not taught.
        skills[0] = parentSkill("11", "Writing a word equation", .secure, india(2026, 10, 6, 18, 30))
        // The numbers in front, practising since September, checked again on Wednesday.
        skills[3] = parentSkill("14", "The numbers in front of a formula", .practising, india(2026, 10, 7, 18, 30))
        #expect(facts(skills: skills).taught == ["Balancing equations", "Types of reactions"])
    }

    @Test func checksAndMarksOutsideTheWeekDoNotCount() {
        let facts = facts(checks: devChecks.map { moved($0, to: day(9, 28)) }, sessions: [], marks: [devMarks[0]])
        #expect(facts.right == nil && facts.rightLine == "No checks yet")
    }

    @Test func aStudentAbsentAllWeekGetsTheAttendanceFactAndNoTaught() {
        let facts = facts(
            skills: parentSkills(taughtThisWeek: false),
            checks: [],
            sessions: weekSessions(devAbsent: true)
        )
        #expect(facts.absentAllWeek && facts.attendance == "absent all week (3 classes)")
        #expect(facts.taught.isEmpty && facts.taughtLine == "Nothing new this week: absent all week")
        #expect(facts.lead(status: .watch, absentDays: [day(10, 5), day(10, 7), day(10, 9)]) == "3 absences")
    }

    @Test func aStudentAbsentAllWeekIsNotToldWhatTheGroupWasTaught() {
        let facts = facts(checks: [], sessions: weekSessions(devAbsent: true))
        #expect(facts.taught.isEmpty && facts.taughtLine == "Nothing new this week: absent all week")
    }

    @Test func aStudentWithNoChecksHasNoGotRightSentence() {
        let skills = parentSkills().filter { $0.state != .practising }
        let facts = facts(student: riya, skills: skills, checks: [], marks: [], items: [])
        #expect(facts.right == nil && facts.rightLine == "No checks yet")
        #expect(facts.practise.isEmpty && facts.practiseLine == "Nothing to add")
    }

    @Test func aStudentWithNoSkillsStillHasFacts() {
        let facts = facts(student: newStudent, chapters: [], skills: [], checks: [], marks: [], items: [])
        #expect(facts.taughtLine == "Nothing new this week" && facts.comingLine == "Nothing set")
        #expect(facts.attendance == nil)
    }

    @Test func thePlacementsChecksAreLeftOut() {
        let facts = facts(checks: devChecks.map(asPlacement), marks: [])
        #expect(facts.right == nil)
    }

    @Test func withNoPractisingSkillTheWeeksWrongChecksSayWhatToPractise() {
        let skills = parentSkills().map { skill in
            var copy = skill
            if copy.state == .practising {
                copy.state = .secure
            }
            return copy
        }
        let facts = facts(skills: skills)
        #expect(facts.practise == ["The numbers in front of a formula"])
    }

    @Test func theLeadReadsTheWeeksOneFact() {
        let allRight = devChecks.prefix(8).map(\.self)
        let facts = facts(checks: Array(allRight), marks: [])
        #expect(facts.lead(status: .onTrack, absentDays: []) == "all right")
        #expect(facts.lead(status: .onTrack, absentDays: [day(10, 7)]) == "absent Wed")
        #expect(facts.lead(status: .notOnTrack, absentDays: []) == "not on track")
        #expect(NoteWeek.topic(facts, chapters: parentChapters, skills: parentSkills()) == "Chemical reactions")
        let quiet = self.facts(skills: parentSkills(taughtThisWeek: false), checks: [], marks: [])
        #expect(NoteWeek.topic(quiet, chapters: parentChapters, skills: parentSkills()) == "Chemical reactions")
        #expect(quiet.lead(status: .onTrack, absentDays: []) == "The numbers in front of a formula")
    }
}

struct CanDoWeekTests: ParentFixtures {
    @Test func theLadderGivesWhatMovedUpWhatTheStudentCanDoAndWhatIsNext() {
        let facts = CanDoWeek.facts(chapters: sahilLadder, skills: sahilSkills(), week: week, calendar: calendar)
        #expect(facts.movedUp == [.init(area: .reading, step: "Sentences")])
        #expect(facts.canDo == ["Read short sentences", "Write letters", "Count to 99"])
        #expect(facts.atHome == "One page a day from the picture book")
        #expect(facts.next == ["Reading a paragraph", "Writing words", "Adding to 20"])
        #expect(facts.movedUpLine == "Sentences · moved up this week")
        #expect(facts.rows.map(\.label) == ["Can now do", "At home", "Next"])
        #expect(facts.rows.first?.fact == "Read short sentences · write letters · count to 99")
    }

    @Test func aWeekWithNoStepMovedStillSaysWhatTheStudentCanDo() {
        let facts = CanDoWeek.facts(
            chapters: sahilLadder, skills: sahilSkills(movedThisWeek: false), week: week, calendar: calendar
        )
        #expect(facts.movedUp.isEmpty && facts.movedUpLine == "No change this week" && !facts.canDo.isEmpty)
        #expect(facts.atHome == "One page a day from the picture book")
    }

    @Test func theAtHomeLineFollowsTheAreaAndStep() {
        #expect(CanDoWeek.atHome(area: .numbers, step: 1) == "Count things at home to 99")
        #expect(CanDoWeek.atHome(area: .writing, step: 2) == "Five words a day in the notebook")
        #expect(CanDoWeek.atHome(area: .reading, step: 2) == "One page a day from the picture book")
    }

    @Test func ladderStudentsGetCanNowDoAndOthersTheNote() {
        #expect(CanDoWeek.isLadderNote(sahil, chapters: sahilLadder))
        #expect(!CanDoWeek.isLadderNote(dev, chapters: parentChapters))
        var fourth = sahil
        fourth.classLevel = .four
        #expect(!CanDoWeek.isLadderNote(fourth, chapters: sahilLadder))
        var ukg = sahil
        ukg.classLevel = .ukg
        #expect(CanDoWeek.isLadderNote(ukg, chapters: []))
        #expect(!CanDoWeek.isLadderNote(sahil, chapters: parentChapters))
    }
}

struct MarkRulesSubjectTests: ParentFixtures {
    @Test func belowUsualComparesWithinTheSubjectAsWritten() {
        let hindi = mark(subject: "Hindi", test: "Unit test 2", on: day(9, 28), score: 11, max: 25)
        let earlier = [
            mark(subject: "Hindi", test: "Unit test 1", on: day(9, 1), score: 20, max: 25),
            mark(subject: "Hindi", test: "Class test", on: day(9, 10), score: 19, max: 25),
            mark(subject: "Mathematics", test: "Unit test 1", on: day(9, 1), score: 5, max: 25),
        ]
        #expect(MarkRules.belowUsual(hindi, earlier: earlier))
        let social = mark(subject: "Social science", test: "Unit test 2", on: day(9, 28), score: 11, max: 25)
        #expect(!MarkRules.belowUsual(social, earlier: earlier))
    }
}
