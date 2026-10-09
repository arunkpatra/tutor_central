import Foundation
import Testing

/// A graphical calendar in a popover with no width collapses to a sliver (build 10, the date of birth): every
/// `.datePickerStyle(.graphical)` in the app is given `.calendarPopover(timeZone:)` within the next few lines.
struct CalendarPopoverUseTests {
    static var sources: URL {
        URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources")
    }

    @Test func everyGraphicalCalendarHasItsWidth() throws {
        let files = FileManager.default.enumerator(at: Self.sources, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" } ?? []
        var found = 0
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where line.contains(".datePickerStyle(.graphical)") {
                found += 1
                let next = lines[index ..< min(index + 4, lines.count)].joined()
                #expect(next.contains(".calendarPopover("), "\(file.lastPathComponent):\(index + 1)")
            }
        }
        #expect(found > 0)
    }
}
