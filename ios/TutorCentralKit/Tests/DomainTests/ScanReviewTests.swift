import Foundation
import Testing
@testable import Domain

struct ScanReviewTests {
    static let science = UUID(uuidString: "33333333-3333-3333-3333-333333333332") ?? UUID()
    static let dev = Student(
        id: UUID(), name: "Dev Kumar", classID: science, monthlyFee: Money(rupees: 1000), parentName: "Ramesh Kumar",
        parentPhone: PhoneNumber(e164: "+919884843831"), dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil,
        thisMonth: nil
    )
    static let scienceClass = Classroom(
        id: science, name: "Class 8 Science", subject: "Science", monthlyFee: Money(rupees: 1000), meetingDays: [],
        startTime: nil, endTime: nil, archivedAt: nil
    )
    static let classes = [scienceClass]

    static func row(_ name: String, phone: String?, fee: Int?) -> ScanRow {
        ScanRow(
            id: UUID(), name: name, phone: phone.flatMap(PhoneNumber.init(e164:)), fee: fee.map(Money.init(rupees:)),
            parentName: "", included: true, flag: nil
        )
    }

    @Test func aMatchByPhoneOrNameIsFlaggedAndUnticked() {
        let rows = [
            Self.row("Aarav Mehta", phone: "+919876543210", fee: 1200), Self.row("DEV  kumar", phone: nil, fee: nil),
            Self.row("Someone Else", phone: "+919884843831", fee: 1000),
        ]
        let flagged = ScanReview.flag(rows, against: [Self.dev], classes: Self.classes)
        let dev = ScanRowFlag.alreadyHere(name: "Dev Kumar", className: "Class 8 Science")
        #expect(flagged[0].flag == nil && flagged[0].included)
        #expect(flagged[1].flag == dev && !flagged[1].included)
        #expect(flagged[2].flag == dev && !flagged[2].included, "the phone matches")
        #expect(flagged[1].flag?.chip == "Already here" && flagged[1].flag?
            .line == "Matches Dev Kumar in Class 8 Science")
        var archived = Self.dev
        archived.archivedAt = Date()
        #expect(
            ScanReview.flag(rows, against: [archived], classes: Self.classes)[1].flag == .noNumber,
            "an archived student is not a match"
        )
    }

    @Test func aBadPhoneBecomesNoNumber() {
        #expect(PhoneNumber(e164: "+91432") == nil)
        let row = ScanReview.flag([Self.row("Kavya Nair", phone: nil, fee: 1200)], against: [], classes: [])[0]
        #expect(row.flag == .noNumber && row.included && row.line == "No number read · ₹1,200")
        #expect(Self.row("Aarav Mehta", phone: "+919876543210", fee: 1200).line == "+91 98765 43210 · ₹1,200")
        #expect(Self.row("Aarav Mehta", phone: "+919876543210", fee: nil).line == "+91 98765 43210 · class fee")
        #expect(ScanReview.folded("  Bir  Bikram   SINGH ") == "bir bikram singh")
    }

    @Test func aRowBecomesADraftAndTheWordsCount() {
        var row = Self.row("Kavya Nair", phone: "+919876543210", fee: 1200)
        row.parentName = "Asha Nair"
        let draft = row.draft(classID: Self.science)
        #expect(draft.trimmedName == "Kavya Nair" && draft.classID == Self.science && draft.fee == Money(rupees: 1200))
        #expect(draft.trimmedParentName == "Asha Nair" && draft.parentDigits == "9876543210")
        #expect(ScanReview.title(found: 8) == "8 found" && ScanReview.title(found: 1) == "1 found")
        #expect(ScanReview.addLabel(ticked: 7) == "Add 7 students" && ScanReview.addLabel(ticked: 1) == "Add 1 student")
        #expect(ScanReview.addLabel(ticked: 0) == "Nothing to add")
        #expect(ScanReview.addedToast(count: 7) == "7 students added from the register.")
        #expect(ScanReview.addedToast(count: 1) == "1 student added from the register.")
    }

    @Test func aRowsOwnClassWinsOverTheListsAddTo() {
        var row = Self.row("Kavya Nair", phone: nil, fee: nil)
        #expect(row.draft(classID: Self.science).classID == Self.science)
        let maths = UUID()
        row.classID = maths
        #expect(row.draft(classID: Self.science).classID == maths, "fixed in Fix this row")
    }
}
