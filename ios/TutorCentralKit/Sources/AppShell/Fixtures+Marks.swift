import Data
import Foundation

/// Marks from a photo (P14-Marks-*): Hemanth's report card photographed on Friday 9 October; the fake reads Unit test 2
/// in Mathematics, Science and Hindi, the Hindi row undated.
extension Fixtures {
    static let marksStates: Set<LaunchState> = [.marksReading, .marksConfirm, .marksEdit, .studentMarks]

    /// A photographed page as the board draws it.
    static var marksPage: ImageUpload {
        ImageUpload(data: sheetPhoto(), mediaType: "image/jpeg")
    }
}
