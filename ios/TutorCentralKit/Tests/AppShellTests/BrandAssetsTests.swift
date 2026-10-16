import Foundation
import Testing
@testable import AppShell

/// The brand kit's files in the app target (D120, D122): the layered icon in place of the asset-catalogue icon, the
/// launch mark in place of the book. Reads `ios/` from this file's own path, as the simulator reads the host's files.
struct BrandAssetsTests {
    static let ios: URL = {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "ios" {
            url.deleteLastPathComponent()
        }
        return url
    }()

    static func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: ios.appending(path: path).path)
    }

    @Test func theLaunchScreenAndItsCoverDrawTheMark() throws {
        let data = try Data(contentsOf: Self.ios.appending(path: "App/Info.plist"))
        let plist = try #require(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        let launch = try #require(plist["UILaunchScreen"] as? [String: Any])
        #expect(launch["UIImageName"] as? String == "LaunchMark")
        #expect(OpeningCover.image == "LaunchMark")
        #expect(Self.exists("App/Assets.xcassets/LaunchMark.imageset/LaunchMark.svg"))
    }

    @Test func theBookIsGone() {
        #expect(!Self.exists("App/Assets.xcassets/LaunchBook.imageset"))
        #expect(!Self.exists("App/Assets.xcassets/AppIcon.appiconset"))
    }

    @Test func theIconIsTheLayeredOne() throws {
        #expect(Self.exists("App/TutorCentral.icon/icon.json"))
        let project = try String(contentsOf: Self.ios.appending(path: "project.yml"), encoding: .utf8)
        #expect(project.contains("ASSETCATALOG_COMPILER_APPICON_NAME: TutorCentral\n"))
    }
}
