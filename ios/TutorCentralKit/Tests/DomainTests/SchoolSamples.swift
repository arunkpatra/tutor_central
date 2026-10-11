import Foundation
@testable import Domain

/// The school tests' people (plan/phase-13-plan.md Task 4): Dev, Meher and Nikhil in class 8 at Vidya Niketan; Akshita
/// in class 10 there; Riya in class 5 at St Mary's; Bir with no class. Fixed ids, so each read is the same student.
protocol SchoolSamples {}

extension SchoolSamples {
    var sampleToday: Day {
        Day(year: 2026, month: 10, day: 7)!
    }

    var vidya: School {
        School(id: UUID(uuidString: "44444444-4444-4444-4444-444444444441")!, name: "Vidya Niketan", board: .cbse)
    }

    var stMarys: School {
        School(id: UUID(uuidString: "44444444-4444-4444-4444-444444444442")!, name: "St Mary's School", board: nil)
    }

    var dev: Student {
        sample("D", "Dev Kumar", level: .eight, school: vidya.id)
    }

    var meher: Student {
        sample("E", "Meher Shah", level: .eight, school: vidya.id)
    }

    var nikhil: Student {
        sample("F", "Nikhil Das", level: .eight, school: vidya.id)
    }

    var akshita: Student {
        sample("A", "Akshita Rao", level: .ten, school: vidya.id)
    }

    var riya: Student {
        sample("B", "Riya Sharma", level: .five, school: stMarys.id)
    }

    var bir: Student {
        sample("C", "Bir Bikram Singh", level: nil, school: nil)
    }

    var sahil: Student {
        sample("0", "Sahil Verma", level: .two, school: stMarys.id)
    }

    var people: [Student] {
        [riya, dev, nikhil, akshita, meher, bir]
    }

    func student(_ name: String, level: ClassLevel?, school: UUID?) -> Student {
        Student(
            id: UUID(), name: name, classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil, dateOfBirth: nil,
            gender: nil, notes: nil, archivedAt: nil, thisMonth: nil, classLevel: level, schoolID: school
        )
    }

    /// An exam, nine days out by default, for class 8 at Vidya Niketan.
    func exam(
        audience: ItemAudience? = nil, date: Day? = nil, subject: String = "Science",
        title: String = "Science unit test 3", portions: String? = nil
    ) -> SchoolItem {
        var item = SchoolItem.fixture(
            kind: .exam,
            audience: audience ?? .schoolClass(school: vidya.id, level: .eight),
            date: date ?? sampleToday.adding(days: 9, calendar: DayHeading.india)
        )
        item.subject = subject
        item.title = title
        item.portions = portions
        return item
    }

    /// The Evening batch: Monday to Friday, 17:00 to 18:30.
    var evening: Classroom {
        Classroom(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, name: "Evening batch", subject: "Science",
            monthlyFee: nil, meetingDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 30), archivedAt: nil
        )
    }

    /// "Science unit test 3" for class 8 at Vidya Niketan on Friday 16 October, portions chapters 1 and 2.
    var exam16: SchoolItem {
        var item = SchoolItem.fixture(
            kind: .exam, audience: .schoolClass(school: vidya.id, level: .eight), date: Day(
                year: 2026,
                month: 10,
                day: 16
            )!,
            title: "Science unit test 3", portions: "Ch 1 Chemical reactions · Ch 2 Acids, bases and salts",
            id: UUID(uuidString: "66666666-6666-6666-6666-666666666661")!
        )
        item.subject = "Science"
        return item
    }

    /// Dev's Science chapters: Chemical reactions and Acids, bases and salts, four skills each.
    var devChapters: [Chapter] {
        [
            Chapter(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777771")!,
                subject: "Science",
                position: 1,
                name: "Chemical reactions"
            ),
            Chapter(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777772")!,
                subject: "Science",
                position: 2,
                name: "Acids, bases and salts"
            ),
        ]
    }

    /// Chapter 1: two secure, "Balance a chemical equation" to revisit, one practising; chapter 2: taught, then not
    /// started.
    var devSkills: [Skill] {
        let names = [
            "Spot a chemical change", "Write a word equation", "Balance a chemical equation",
            "Name the types of reactions",
            "Use indicators", "Reactions with metals", "Make a salt", "pH in daily life",
        ]
        let states: [SkillState] = [
            .secure,
            .secure,
            .revisit,
            .practising,
            .taught,
            .notStarted,
            .notStarted,
            .notStarted,
        ]
        return names.enumerated().map { index, name in
            Skill(
                id: UUID(uuidString: String(format: "88888888-8888-8888-8888-%012d", index + 1))!,
                chapterID: devChapters[index / 4].id, position: index % 4 + 1, name: name, state: states[index],
                stateAt: FakeClock.oct7at1635, lastCheckedAt: nil
            )
        }
    }

    private func sample(_ letter: Character, _ name: String, level: ClassLevel?, school: UUID?) -> Student {
        let id = UUID(uuidString: "55555555-5555-5555-5555-55555555555\(letter)")!
        return Student(
            id: id, name: name, classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil, dateOfBirth: nil,
            gender: nil, notes: nil, archivedAt: nil, thisMonth: nil, classLevel: level, schoolID: school
        )
    }
}

extension SchoolItem {
    static func fixture(
        kind: SchoolItemKind, audience: ItemAudience, date: Day, title: String? = nil, portions: String? = nil,
        id: UUID = UUID()
    ) -> SchoolItem {
        SchoolItem(
            id: id, kind: kind, audience: audience, title: title ?? kind.rawValue.capitalized, subject: nil,
            date: date, endDate: nil, portions: portions, sourceText: nil, photoPath: nil, source: .typed,
            receivedAt: FakeClock.oct7at1635, confirmedAt: FakeClock.oct7at1635
        )
    }
}
