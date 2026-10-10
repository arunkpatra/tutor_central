import AITools
import Data
import Domain
import Foundation
import UIKit

/// The AI Assistant's fixtures: the calls answered by the boards' results, an hour's wait for the creating states,
/// a lost connection for the failure (P6-Generate-Failed's words), and the forms as the boards fill them.
extension Fixtures {
    @MainActor static func ai(for state: LaunchState) -> FakeAIRepository {
        let ai = FakeAIRepository(now: { clock(for: state) })
        switch state {
        case .aiGenerating, .aiResultRegenerating: ai.delay = .seconds(3600)
        case .aiGenerateFailed, .scanFailed, .checkFailed: ai.script = .failure(.offline)
        case .scanReading, .checkChecking, .textbookReading: ai.delay = .seconds(3600)
        case .scanNothing: ai.scanRows = []
        case .sheetRegenerating: ai.delayByKind[.sheet] = .seconds(3600)
        default: break
        }
        return ai
    }

    /// The seven students a scan added (P6-Scan-Saved): the board's rows but Dev Kumar, already here, in Class 10
    /// Maths.
    static var scannedSeven: [Student] {
        AISamples.scanRows.filter { $0.name != "Dev Kumar" }.enumerated().map { index, row in
            Student(
                id: UUID(uuidString: String(format: "dddddddd-0000-0000-0000-%012d", index + 1)) ?? UUID(),
                name: row.name, classID: FakeClassesRepository.maths.id,
                monthlyFee: row.fee == 1200 ? nil : row.fee.map(Money.init(rupees:)), parentName: nil,
                parentPhone: row.phone.flatMap(PhoneNumber.init(e164:)), dateOfBirth: nil, gender: nil, notes: nil,
                archivedAt: nil, thisMonth: nil
            )
        }
    }

    /// A check state's visit as far as its board goes: Hemanth chosen, two drawn pages, the scheme read, the check run.
    @MainActor static func prepareCheck(_ store: CheckStore, for state: LaunchState) {
        guard RootView.checkStates.contains(state) else { return }
        store.studentID = FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" }?.id
        guard state != .checkIntro else { return }
        store.addPages([answerPage(lines: 8), answerPage(lines: 6)])
        if state == .checkSchemeTyped {
            store.typedScheme = "Q1 (1) b\nQ2 (1) D = 16 − 24 = −8\nQ3 (1) k = 6\nQ4 (1) real and equal\n"
                + "Q5 (2) x = 3, 4; 1 for factorising\nQ6 (2) x = √(2/3), both roots\nQ7 (2) k = ±6, 1 for one"
        }
        guard ![.checkPages, .checkScheme, .checkSchemeTyped].contains(state) else { return }
        Task {
            await store.loadPapers()
            store.scheme = .paper(generationID: FakeAIHistoryRepository.quadraticID)
            await store.check()
        }
    }

    /// A drawn page of answers (P6-Check-Pages draws two).
    static func answerPage(lines: Int) -> ImageUpload {
        let size = CGSize(width: 900, height: 1200)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let page = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.95, green: 0.93, blue: 0.88, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.23, green: 0.29, blue: 0.48, alpha: 1).setFill()
            for line in 0 ..< lines {
                let y = 90 + CGFloat(line) * 120
                context.fill(CGRect(x: 70, y: y, width: 60, height: 22))
                context.fill(CGRect(x: 170, y: y, width: 420 + CGFloat(line % 4) * 70, height: 22))
            }
        }
        return ImageUpload(data: page.jpegData(compressionQuality: 0.7) ?? Data(), mediaType: "image/jpeg")
    }

    /// The photo a scan state reads: a drawn register page (the simulator has no camera).
    static func scanSample(for _: LaunchState) -> ImageUpload {
        let size = CGSize(width: 1200, height: 900)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let page = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(red: 0.94, green: 0.91, blue: 0.85, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            for row in 0 ..< 8 {
                let y = 90 + CGFloat(row) * 95
                UIColor(red: 0.42, green: 0.38, blue: 0.34, alpha: 1).setFill()
                context.fill(CGRect(x: 80, y: y, width: 60, height: 18))
                context.fill(CGRect(x: 980, y: y, width: 140, height: 18))
                UIColor(red: 0.29, green: 0.26, blue: 0.24, alpha: 1).setFill()
                context.fill(CGRect(x: 180, y: y, width: 360 + CGFloat(row % 3) * 80, height: 18))
            }
        }
        return ImageUpload(data: page.jpegData(compressionQuality: 0.7) ?? Data(), mediaType: "image/jpeg")
    }

    /// The drafts each form state starts with (P6-Form-Paper, -Homework, -Worksheet, -ProgressNote).
    static func aiForms(for state: LaunchState) -> [GenerationKind: GenerateRequest] {
        let maths = FakeClassesRepository.maths
        let science = FakeClassesRepository.science
        let hemanth = FakeStudentsRepository.seed.first { $0.name == "Hemanth Reddy" }?.id
        let observations = "Improving in algebra, careless with signs. Homework on time this month. Needs to "
            + "practise word problems before the mock test on 17 Oct."
        return [
            .paper: .paper(PaperForm(classID: maths.id, subject: "Mathematics", topic: "Quadratic equations")),
            .homework: .homework(HomeworkForm(classID: science.id, subject: "Science", topic: "Cell structure")),
            .worksheet: .worksheet(WorksheetForm(
                classID: maths.id, subject: "Mathematics", topic: "Linear equations in two variables", level: .easy
            )),
            .progressNote: .progressNote(NoteForm(studentID: hemanth, observations: observations, tone: .warm)),
        ]
    }
}
