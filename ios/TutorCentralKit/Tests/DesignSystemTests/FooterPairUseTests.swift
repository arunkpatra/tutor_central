import Foundation
import Testing

/// A footer's Copy beside its main button clipped the button's words at the accessibility sizes ("Send on Wh…", Phase
/// 21
/// hand run 12): every row that holds a `CopyButton` is an `AdaptiveRow`, which stacks the pair there.
struct FooterPairUseTests {
    static var sources: URL {
        URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources")
    }

    @Test func everyCopyPairStacksAtTheAccessibilitySizes() throws {
        let files = FileManager.default.enumerator(at: Self.sources, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" } ?? []
        var found = 0
        for file in files {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
            for (index, line) in lines.enumerated() where line.trimmingCharacters(in: .whitespaces)
                .hasPrefix("CopyButton") {
                found += 1
                let before = lines[max(0, index - 2) ..< index].joined()
                #expect(before.contains("AdaptiveRow("), "\(file.lastPathComponent):\(index + 1)")
            }
        }
        #expect(found > 0)
    }
}
