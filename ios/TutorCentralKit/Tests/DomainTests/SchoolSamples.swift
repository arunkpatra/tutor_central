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

    private func sample(_ letter: Character, _ name: String, level: ClassLevel?, school: UUID?) -> Student {
        let id = UUID(uuidString: "55555555-5555-5555-5555-55555555555\(letter)")!
        return Student(
            id: id, name: name, classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil, dateOfBirth: nil,
            gender: nil, notes: nil, archivedAt: nil, thisMonth: nil, classLevel: level, schoolID: school
        )
    }
}

extension SchoolItem {
    static func fixture(kind: SchoolItemKind, audience: ItemAudience, date: Day, title: String? = nil) -> SchoolItem {
        SchoolItem(
            id: UUID(), kind: kind, audience: audience, title: title ?? kind.rawValue.capitalized, subject: nil,
            date: date, endDate: nil, portions: nil, sourceText: nil, photoPath: nil, source: .typed,
            receivedAt: FakeClock.oct7at1635, confirmedAt: FakeClock.oct7at1635
        )
    }
}
