import Foundation
import Testing
@testable import Domain

struct GeneratePreviewTests {
    static let october = FeeInvoiceTests.october
    static let maths = Classroom(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333331") ?? UUID(), name: "Class 10 Maths", subject: nil,
        monthlyFee: Money(rupees: 1200), meetingDays: [.monday], startTime: nil, endTime: nil, archivedAt: nil
    )
    static let science = Classroom(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333332") ?? UUID(), name: "Class 8 Science", subject: nil,
        monthlyFee: Money(rupees: 1000), meetingDays: [.tuesday], startTime: nil, endTime: nil, archivedAt: nil
    )
    static func student(
        _ number: Int,
        _ name: String,
        classID: UUID?,
        fee: Int? = nil,
        archived: Bool = false
    ) -> Student {
        Student(
            id: UUID(uuidString: String(format: "aaaaaaaa-0000-0000-0000-%012d", number)) ?? UUID(), name: name,
            classID: classID, monthlyFee: fee.map(Money.init(rupees:)), parentName: nil, parentPhone: nil,
            dateOfBirth: nil, gender: nil, notes: nil, archivedAt: archived ? Date() : nil, thisMonth: nil
        )
    }

    static let students = [
        student(1, "Akshita Rao", classID: maths.id), student(2, "Riya Sharma", classID: maths.id, fee: 1500),
        student(3, "Dev Kumar", classID: science.id, fee: 1000), student(4, "Sahil Verma", classID: nil, fee: 800),
        student(5, "Gone Student", classID: maths.id, archived: true), student(6, "No Fee Anywhere", classID: nil),
    ]

    @Test func countsOnlyActiveStudentsWithoutAFee() {
        let preview = GeneratePreview.make(
            students: Self.students, classes: [Self.maths, Self.science], invoices: [], month: Self.october
        )
        #expect(preview.count == 5 && preview.total == Money(rupees: 4500) && preview.canCreate)
        #expect(preview.groups.map(\.line) == [
            "Class 10 Maths · 2 students", "Class 8 Science · 1 student", "No class · 2 students",
        ])
        #expect(preview.groups.map(\.total) == [Money(rupees: 2700), Money(rupees: 1000), Money(rupees: 800)])
        #expect(preview.title == "5 fees will be created" && preview.buttonLabel == "Create 5 fees")
        #expect(preview
            .line == "One for each student without a fee for October, from the class fee or the student's own.")
    }

    @Test func amountsFollowTheFeeRule() {
        // Akshita already has October's fee; Riya's own fee beats the class's; No Fee Anywhere is ₹0 (as
        // generate_fees).
        let existing = FeeInvoiceTests.invoice(1, month: Self.october, amount: 1200)
        let preview = GeneratePreview.make(
            students: Self.students, classes: [Self.maths, Self.science], invoices: [existing], month: Self.october
        )
        #expect(preview.count == 4 && preview.total == Money(rupees: 3300))
        #expect(preview.groups.first?.line == "Class 10 Maths · 1 student")
        #expect(preview.groups.first?.total == Money(rupees: 1500))
        let one = GeneratePreview.make(students: [Self.students[3]], classes: [], invoices: [], month: Self.october)
        #expect(one.title == "1 fee will be created" && one.buttonLabel == "Create 1 fee")
    }

    @Test func nothingToCreateSaysSo() {
        let invoices = Self.students.filter { !$0.isArchived }.map { student in
            FeeInvoice(
                id: UUID(), studentID: student.id, period: Self.october, amount: .zero, status: .due, paidAt: nil,
                paidMethod: nil, waivedReason: nil
            )
        }
        let preview = GeneratePreview.make(
            students: Self.students, classes: [Self.maths, Self.science], invoices: invoices, month: Self.october
        )
        #expect(preview.count < 1 && !preview.canCreate && preview.groups.isEmpty)
        #expect(preview.title == "Everyone has a fee for October" && preview.buttonLabel == "Nothing to create")
        #expect(preview.line == "Nothing to create. A student you add later gets one from here.")
    }
}
