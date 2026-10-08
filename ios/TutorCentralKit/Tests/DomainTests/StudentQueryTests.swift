import Foundation
import Testing
@testable import Domain

struct StudentQueryTests {
    let maths = ClassroomTests.maths
    let science = Classroom(
        id: UUID(),
        name: "Class 8 Science",
        subject: "Science",
        monthlyFee: Money(rupees: 1000),
        meetingDays: [.tuesday, .thursday],
        startTime: nil,
        endTime: nil,
        archivedAt: nil
    )
    var students: [Student] {
        [
            StudentTests.student("Riya Sharma", fee: Money(rupees: 1500), classID: maths.id),
            StudentTests.student("Akshita Rao", classID: maths.id),
            StudentTests.student("Dev Kumar", classID: science.id),
            StudentTests.student("Sahil Verma", fee: Money(rupees: 800)),
            StudentTests.student("Old Student", classID: maths.id, archived: true),
        ]
    }

    func names(_ list: [Student]) -> [String] {
        list.map(\.name)
    }

    @Test func allIsActiveStudentsByName() {
        let out = StudentQuery.apply(students, classes: [maths, science], search: "", filter: .all, sort: .name)
        #expect(names(out) == ["Akshita Rao", "Dev Kumar", "Riya Sharma", "Sahil Verma"])
    }

    @Test func feeSortIsHighestFirstUsingTheClassFeeThenName() {
        let out = StudentQuery.apply(students, classes: [maths, science], search: "", filter: .all, sort: .fee)
        #expect(names(out) == ["Riya Sharma", "Akshita Rao", "Dev Kumar", "Sahil Verma"])
    }

    @Test func filtersByClassUnassignedAndArchived() {
        #expect(names(StudentQuery.apply(
            students,
            classes: [maths, science],
            search: "",
            filter: .classroom(science.id),
            sort: .name
        )) == ["Dev Kumar"])
        #expect(names(StudentQuery.apply(
            students,
            classes: [maths, science],
            search: "",
            filter: .unassigned,
            sort: .name
        )) == ["Sahil Verma"])
        #expect(names(StudentQuery.apply(
            students,
            classes: [maths, science],
            search: "",
            filter: .archived,
            sort: .name
        )) == ["Old Student"])
    }

    @Test func matchesNamesAndNumbersHoweverTyped() {
        let riya = students[0]
        var akshita = students[1]
        akshita.parentPhone = PhoneNumber(e164: "+919811122233")
        for query in ["rao", "SHA", "sharma ", "98111", "+91 98111", "98111 22233", "9811122233", "098111 22233"] {
            let hit = StudentQuery.matches(riya, search: query) || StudentQuery.matches(akshita, search: query)
            #expect(hit, "\(query)")
        }
        #expect(
            StudentQuery.matchesPhone(riya, search: "98111") == false,
            "Riya's parent in this fixture is +91 97991 13211"
        )
        #expect(StudentQuery.matchesPhone(riya, search: "97991 13211"))
        #expect(!StudentQuery.matches(riya, search: "xyz"))
        let range = StudentQuery.matchRange(in: "Akshita Rao", search: "SH")
        #expect(range.map { String("Akshita Rao"[$0]) } == "sh")
        #expect(StudentQuery.matchRange(in: "Akshita Rao", search: "") == nil)
    }

    @Test func archivedStudentsAreFoundBySearchAndHiddenByAll() {
        let out = StudentQuery.apply(students, classes: [maths, science], search: "old", filter: .all, sort: .name)
        #expect(names(out) == ["Old Student"], "a search looks everywhere, in every class and the archive")
        let none = StudentQuery.apply(students, classes: [maths, science], search: "", filter: .all, sort: .name)
        #expect(!names(none).contains("Old Student"))
    }
}
