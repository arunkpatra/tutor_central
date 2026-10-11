import Foundation
import Testing
@testable import Domain

struct MessageCadenceDecisionTests: ParentFixtures {
    var now: Date {
        india(2026, 10, 11, 18, 30)
    }

    @Test func aParentWithThreeSuggestedThisWeekHasTheFourthHeld() {
        let three = [MessageKind.testTomorrow, .notOnTrack, .note].map { entry($0, day: 7) }
        #expect(MessageCadence.decision(for: devWithParent, parentEntries: three, now: now, calendar: calendar)
            == .held(.threeThisWeek))
        #expect(MessageCadence.decision(
            for: devWithParent, parentEntries: Array(three.prefix(2)), now: now, calendar: calendar
        ) == .send)
    }

    @Test func handSendsNeverCount() {
        let hand = [MessageKind.reminder, .receipt, .absence, .consent, .forwardAsk, .progress]
            .map { entry($0, day: 7) }
        #expect(MessageCadence.decision(for: devWithParent, parentEntries: hand, now: now, calendar: calendar) == .send)
    }

    @Test func noConsentHoldsWithTheParentsName() {
        #expect(MessageCadence.decision(for: riyaWithParent, parentEntries: [], now: now, calendar: calendar)
            == .held(.consent(parentFirstName: "Neha")))
        #expect(MessageCadence.heldWords(.consent(parentFirstName: "Neha")) == "waits for Neha's consent")
        #expect(MessageCadence.heldWords(.consent(parentFirstName: nil)) == "waits for the parent's consent")
        #expect(MessageCadence.heldWords(.threeThisWeek) == "held: three messages this week")
    }

    @Test func noNumberMeansNothingToSendTo() {
        var student = devWithParent
        student.parentPhone = nil
        #expect(MessageCadence.decision(for: student, parentEntries: [], now: now, calendar: calendar) == .noNumber)
    }

    @Test func twoStudentsOfOneParentShareTheThree() {
        let entries = [entry(.note, day: 5), entry(.note, day: 5), entry(.testTomorrow, day: 7)]
        #expect(MessageCadence.decision(for: devWithParent, parentEntries: entries, now: now, calendar: calendar)
            == .held(.threeThisWeek))
    }

    @Test func aNoteHeldOnSundayIsFreeOnMonday() {
        let three = [MessageKind.testTomorrow, .notOnTrack, .note].map { entry($0, day: 7) }
        #expect(MessageCadence.decision(
            for: devWithParent, parentEntries: three, now: india(2026, 10, 12, 9, 0), calendar: calendar
        ) == .send)
    }

    @Test func theNotOnTrackMessageCountsAsASuggestion() {
        #expect(MessageCadence.suggestedKinds.contains(.notOnTrack))
    }

    @Test func theHeldFootnoteNamesTheNextNoteDay() {
        let footnote = MessageCadence.heldFootnote(nextNoteDay: day(10, 18))
        let expected = [
            "Three messages this week already. The app suggests at most three a week per parent, so this weekly note",
            "waits for Sunday the 18th unless you send it now. Messages you send yourself are never held.",
        ].joined(separator: " ")
        #expect(footnote == expected)
        #expect(MessageCadence.heldFootnote(nextNoteDay: day(10, 21)).contains("Wednesday the 21st"))
        #expect(MessageCadence.heldFootnote(nextNoteDay: day(10, 22)).contains("Thursday the 22nd"))
        #expect(MessageCadence.heldFootnote(nextNoteDay: day(11, 1)).contains("Sunday the 1st"))
        #expect(MessageCadence.heldFootnote(nextNoteDay: day(11, 13)).contains("Friday the 13th"))
    }
}

struct PlanRulesStepTests: ParentFixtures {
    func teach(_ plan: PlanDraft) -> PlanLine? {
        plan.lines.first { $0.studentID == dev.id && $0.kind == .teach }
    }

    @Test func theStepsChangeTheTeachLine() {
        let words = { (step: NextStep?) in teach(PlanRules.plan(planInput(dev: .notOnTrack, step: step)))?.words }
        #expect(words(nil) == "Teach again: Balancing equations, with the worked example")
        #expect(words(.teachAgain) == "Teach again: Balancing equations, with the worked example")
        #expect(words(.stepBack) == "Step back: Counting atoms in a formula, then Balancing equations")
        #expect(words(.leave) == "Teach: Balancing equations")
        #expect(words(.addToChecks) == "Teach: Balancing equations")
    }

    @Test func stepBackTeachesTheSkillBeforeAndLinksIt() {
        #expect(teach(PlanRules.plan(planInput(dev: .notOnTrack, step: .stepBack)))?.skillID == countingAtoms.id)
    }

    @Test func addToTheChecksPutsTheSkillAtTheHeadOfTheStudentsChecks() {
        let plan = PlanRules.plan(planInput(dev: .notOnTrack, step: .addToChecks))
        let check = plan.lines.first { $0.studentID == dev.id && $0.kind == .check }
        #expect(check?.personalChecks == true)
        #expect(plan.personalCheckSkills[dev.id]?.first?.name == "Balancing equations")
        let requests = ArtefactBudget.requests(
            for: plan, students: [dev.id: planInput(dev: .notOnTrack, step: .addToChecks).students[0]],
            spacedSkills: [dev.id: [countingAtoms]], briefsMade: []
        )
        let personal = requests.compactMap { request -> [String]? in
            if case let .personalChecks(_, skills, _, _, _) = request {
                return skills
            }
            return nil
        }
        #expect(personal.first == ["Balancing equations", "Counting atoms in a formula"])
    }

    @Test func theCaptionShowsUntilTheParentIsTold() {
        var student = planInput(dev: .notOnTrack, step: nil, since: day(10, 9)).students[0]
        #expect(PlanRules.caption(student, told: false, calendar: calendar)
            == "Since Fri 9 Oct · tell Ramesh after the class")
        #expect(PlanRules.caption(student, told: true, calendar: calendar) == nil)
        student.nextStep = .leave
        #expect(PlanRules.caption(student, told: false, calendar: calendar) == nil)
        student.nextStep = nil
        student.trackStatus = .watch
        #expect(PlanRules.caption(student, told: false, calendar: calendar) == nil)
        student.trackStatus = .notOnTrack
        student.parentName = nil
        #expect(PlanRules.caption(student, told: false, calendar: calendar)
            == "Since Fri 9 Oct · tell the parent after the class")
    }

    @Test func aWatchStudentKeepsPhase12sTeachAgain() {
        #expect(teach(PlanRules.plan(planInput(dev: .watch, step: nil)))?.words
            == "Teach again: Balancing equations, with the worked example")
    }
}

struct NotOnTrackMessageTests: ParentFixtures {
    @Test func theEnglishTemplateReadsAsTheBoard() {
        let facts = NotOnTrackMessage.Facts(
            hard: ["balancing equations"], reasons: ["absent twice this month"],
            doing: "teach it again with a worked example in the next class",
            atHome: "Ten minutes of practice each evening at home will make a big difference."
        )
        let text = NotOnTrackMessage.text(
            studentName: "Dev Kumar", parentName: "Ramesh Kumar", facts: facts, tutorName: "Meera Nair",
            centreName: "Bright Minds Tuition"
        )
        let board = [
            "Hello Ramesh, Dev is finding balancing equations hard and was absent twice this month.",
            "We will teach it again with a worked example in the next class.",
            "Ten minutes of practice each evening at home will make a big difference.",
            "Could we talk for five minutes this week? Thank you.",
        ].joined(separator: " ")
        #expect(text.hasPrefix(board))
        #expect(text.hasSuffix(MessageSignature.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition")))
        #expect(NotOnTrackMessage.heading(studentFirstName: "Dev") == "Dev needs a hand this month")
    }

    @Test func theFactsComeFromTheReasonsTheSkillAndTheStep() {
        let reasons = ["3 of 10 on the mock", "Absent twice in four weeks", "Homework not done three times running"]
        let facts = NotOnTrackMessage.facts(reasons: reasons, skill: balancing, before: countingAtoms, step: .stepBack)
        #expect(facts.hard == ["balancing equations"])
        #expect(facts.reasons == [
            "3 of 10 on the mock",
            "absent twice in four weeks",
            "homework not done three times running",
        ])
        #expect(facts.doing == "step back to counting atoms in a formula, then balancing equations")
        let noSkill = NotOnTrackMessage.facts(
            reasons: ["Absent 4 times in four weeks"],
            skill: nil,
            before: nil,
            step: .tellParent
        )
        #expect(noSkill.hard == ["this month's work"])
        #expect(NotOnTrackMessage.body(studentName: "Dev Kumar", parentName: "Ramesh Kumar", facts: noSkill)
            .hasPrefix("Hello Ramesh, Dev is finding this month's work hard"))
        #expect(noSkill.doing == "go over the last chapter again in the next class")
        let again = NotOnTrackMessage.facts(reasons: [], skill: balancing, before: nil, step: .tellParent)
        #expect(again.doing == "teach it again with a worked example in the next class")
    }
}
