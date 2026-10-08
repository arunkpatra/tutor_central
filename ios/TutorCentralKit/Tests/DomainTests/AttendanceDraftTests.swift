import Foundation
import Testing
@testable import Domain

struct AttendanceDraftTests {
    static let day = Day(year: 2026, month: 10, day: 7)!
    static let maths = UUID()
    static func member(_ name: String, archived: Bool = false) -> Student {
        Student(
            id: UUID(), name: name, classID: maths, monthlyFee: nil, parentName: nil, parentPhone: nil,
            dateOfBirth: nil,
            gender: nil, notes: nil, archivedAt: archived ? Date() : nil, thisMonth: nil
        )
    }

    let members = [member("Akshita Rao"), member("Hemanth Reddy"), member("Riya Sharma")]

    @Test func everyoneStartsPresentAndATapMarksAbsent() {
        var draft = AttendanceDraft(date: Self.day, classID: Self.maths, members: members, saved: nil)
        #expect(draft.presentCount == 3 && draft.absentCount == 0 && draft.marks.count == 3)
        draft.toggle(members[1].id)
        #expect(draft.presentCount == 2 && draft.absentCount == 1 && draft
            .absentIDs(ordered: members) == [members[1].id])
        draft.toggle(members[1].id)
        #expect(draft.absentCount == 0, "a second tap undoes it")
    }

    @Test func aSavedSessionReopensWithItsMarksAndANewMemberPresent() {
        let saved = AttendanceSession(
            id: UUID(), classID: Self.maths, date: Self.day, savedAt: Date(),
            marks: [members[0].id: .present, members[1].id: .absent]
        )
        let draft = AttendanceDraft(date: Self.day, classID: Self.maths, members: members, saved: saved)
        #expect(
            draft.marks[members[1].id] == .absent && draft.marks[members[2].id] == .present,
            "Riya joined since: present"
        )
        #expect(!draft.isChanged(from: saved, members: members), "nothing touched yet")
        var changed = draft
        changed.toggle(members[0].id)
        #expect(changed.isChanged(from: saved, members: members))
        #expect(draft.isChanged(from: nil, members: members), "a fresh class is always worth saving")
    }

    @Test func archivedMembersAreLeftOut() {
        let gone = Self.member("Old", archived: true)
        let draft = AttendanceDraft(date: Self.day, classID: Self.maths, members: members + [gone], saved: nil)
        #expect(draft.marks[gone.id] == nil && draft.presentCount == 3)
    }

    @Test func theSessionCountsItsMarks() {
        let session = AttendanceSession(
            id: UUID(), classID: nil, date: Self.day, savedAt: Date(),
            marks: [members[0].id: .present, members[1].id: .absent, members[2].id: .absent]
        )
        #expect(session.presentCount == 1 && session.absentCount == 2)
        #expect(Set(session.absentStudentIDs) == [members[1].id, members[2].id])
    }
}
