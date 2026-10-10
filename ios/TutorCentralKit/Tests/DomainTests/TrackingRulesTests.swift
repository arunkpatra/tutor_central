import Foundation
import Testing
@testable import Domain

@MainActor struct TrackingRulesTests {
    let now = FakeClock.oct7at1635
    let day: TimeInterval = 86400
    func input(
        checks: [CheckRecord] = [],
        absences: Int = 0,
        homework: [HomeworkRecord] = [],
        skills: [Skill] = [],
        chapters: [Chapter] = []
    ) -> TrackingInput {
        TrackingInput(
            checks: checks,
            absences: absences,
            homework: homework,
            skills: skills,
            chapters: chapters,
            classLevel: .ten,
            now: now,
            calendar: DayHeading.india
        )
    }

    func check(_ correct: Bool, daysAgo: Int) -> CheckRecord {
        CheckRecord(
            id: UUID(),
            studentID: UUID(),
            skillID: UUID(),
            sessionID: UUID(),
            question: "",
            correct: correct,
            at: now - Double(daysAgo) * day,
            isPlacement: false
        )
    }

    func homework(_ status: HomeworkStatus, daysAgo: Int) -> HomeworkRecord {
        HomeworkRecord(
            id: UUID(),
            studentID: UUID(),
            sessionID: UUID(),
            givenAt: now - Double(daysAgo) * day,
            status: status
        )
    }

    @Test func aStudentWithoutChecksIsNotKnown() {
        let tracking = TrackingRules.evaluate(input(absences: 5))
        #expect(tracking.status == .notKnown && tracking.reasons.isEmpty)
        #expect(tracking.nextStep == "Start with the class's first chapter until the checks say otherwise.")
    }

    @Test func accuracyOverThreeWeeksBands() {
        let poor = (0 ..< 9).map { check($0 < 4, daysAgo: $0 * 2) } // 4 of 9
        let tracking = TrackingRules.evaluate(input(checks: poor))
        #expect(tracking.status == .notOnTrack && tracking.reasons == ["4 of 9 checks right over three weeks"])
        let fair = (0 ..< 10).map { check($0 < 6, daysAgo: $0) } // 6 of 10
        #expect(TrackingRules.evaluate(input(checks: fair)).status == .watch)
        let good = (0 ..< 10).map { check($0 < 8, daysAgo: $0) } // 8 of 10
        #expect(TrackingRules.evaluate(input(checks: good)).status == .onTrack)
        let few = (0 ..< 3).map { check(false, daysAgo: $0) } // under six checks: accuracy does not fire
        #expect(TrackingRules.evaluate(input(checks: few)).status == .onTrack)
        let old = (0 ..< 9).map { check(false, daysAgo: 22 + $0) } // outside the window
        #expect(TrackingRules.evaluate(input(checks: old)).status == .onTrack)
    }

    @Test func absencesAndHomeworkBands() {
        let some = [check(true, daysAgo: 1)]
        #expect(TrackingRules.evaluate(input(checks: some, absences: 2)).status == .watch)
        let tracking = TrackingRules.evaluate(input(checks: some, absences: 4))
        #expect(tracking.status == .notOnTrack && tracking.reasons == ["Absent 4 times in four weeks"])
        let twoNotDone = [homework(.notDone, daysAgo: 1), homework(.notDone, daysAgo: 3), homework(.done, daysAgo: 5)]
        #expect(TrackingRules.evaluate(input(checks: some, homework: twoNotDone)).status == .watch)
        let three = [homework(.notDone, daysAgo: 1), homework(.notDone, daysAgo: 3), homework(.notDone, daysAgo: 5)]
        #expect(TrackingRules.evaluate(input(checks: some, homework: three))
            .reasons == ["Homework not done three times running"])
        let given = [homework(.given, daysAgo: 1), homework(.notDone, daysAgo: 3), homework(.notDone, daysAgo: 5)]
        #expect(TrackingRules.evaluate(input(checks: some, homework: given))
            .status == .onTrack) // a row still "given" is not "not done"
    }

    @Test func chaptersBehindTheTermCalendar() {
        // October: five of ten months gone, so a book of 14 chapters expects 7 started.
        let chapters = (1 ... 14).map { chapter($0) }
        let skills = chapters
            .flatMap { c in [skill(c, 1, state: c.position <= 4 ? .secure : .notStarted, stateAt: now)] }
        let behind = TrackingRules.chaptersBehind(
            skills: skills,
            chapters: chapters,
            now: now,
            calendar: DayHeading.india
        )
        #expect(behind?.behind == 3 && behind?.subject == "Mathematics")
        let tracking = TrackingRules.evaluate(input(
            checks: [check(true, daysAgo: 1)],
            skills: skills,
            chapters: chapters
        ))
        #expect(tracking.status == .notOnTrack && tracking.reasons == ["3 chapters behind in Mathematics"])
    }

    @Test func theWorstRuleWinsAndEveryFiredReasonIsKept() {
        let fair = (0 ..< 10).map { check($0 < 6, daysAgo: $0) }
        let tracking = TrackingRules.evaluate(input(checks: fair, absences: 4))
        #expect(tracking.status == .notOnTrack)
        #expect(tracking.reasons == ["Absent 4 times in four weeks", "6 of 10 checks right over three weeks"])
    }

    @Test func theNextStepNamesTheCurrentSkill() {
        let c = chapter(1)
        let skills = [
            skill(c, 1, state: .secure, stateAt: now),
            skill(c, 2, state: .practising, stateAt: now, name: "Add like fractions"),
            skill(c, 3, name: "Subtract fractions"),
        ]
        let watch = TrackingRules.evaluate(input(
            checks: (0 ..< 10).map { check($0 < 6, daysAgo: $0) },
            skills: skills,
            chapters: [c]
        ))
        #expect(watch.nextStep == "Teach Add like fractions again with a worked example.")
        let good = TrackingRules.evaluate(input(checks: [check(true, daysAgo: 1)], skills: skills, chapters: [c]))
        #expect(good.nextStep == "Continue with Add like fractions.")
        let bad = TrackingRules.evaluate(input(
            checks: (0 ..< 9).map { check(false, daysAgo: $0) },
            skills: skills,
            chapters: [c]
        ))
        #expect(bad.nextStep == "Step back to the skill before Add like fractions.")
        #expect(TrackingRules.evaluate(input(checks: [check(true, daysAgo: 1)]))
            .nextStep == "Carry on with the next chapter.")
    }
}

extension TrackingRulesTests {
    @Test func placementChecksDoNotCountTowardsAccuracyButMakeTheStudentKnown() {
        let placement = (0 ..< 8).map {
            CheckRecord(
                id: UUID(),
                studentID: UUID(),
                skillID: UUID(),
                sessionID: nil,
                question: "",
                correct: $0 < 2,
                at: now - day,
                isPlacement: true
            )
        }
        #expect(TrackingRules.evaluate(input(checks: placement)).status == .onTrack)
    }

    @Test func theWatchAndNotOnTrackStepsWithoutASkill() {
        let fair = (0 ..< 10).map { check($0 < 6, daysAgo: $0) }
        #expect(TrackingRules.evaluate(input(checks: fair))
            .nextStep == "Teach the last chapter again with a worked example.")
        let poor = (0 ..< 9).map { check(false, daysAgo: $0) }
        #expect(TrackingRules.evaluate(input(checks: poor))
            .nextStep == "Tell the parent, then teach again with the worked example.")
        let twoNotDone = [homework(.notDone, daysAgo: 1), homework(.notDone, daysAgo: 3)]
        #expect(TrackingRules.evaluate(input(checks: [check(true, daysAgo: 1)], homework: twoNotDone))
            .reasons == ["Homework not done twice running"])
    }
}
