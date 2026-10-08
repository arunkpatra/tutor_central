import Domain
import Foundation
import ImageIO
import Testing
import UIKit
@testable import Data

struct PhotoReducerTests {
    static func image(width: Int, height: Int) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: Self.format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            UIColor.black.setFill()
            context.fill(CGRect(x: 40, y: 40, width: width / 2, height: 12))
        }
        return image.pngData() ?? Data()
    }

    /// Pixels, not points: a 4000 px drawing is 4000 px however the simulator's screen scales.
    static var format: UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return format
    }

    static func size(of upload: ImageUpload) -> CGSize {
        guard let source = CGImageSourceCreateWithData(upload.data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
        else { return .zero }
        return CGSize(width: width, height: height)
    }

    @Test func aLargePhotoComesBackUnder2000pxAsJPEG() throws {
        let reduced = try #require(PhotoReducer.reduce(Self.image(width: 4000, height: 3000)))
        #expect(reduced.mediaType == "image/jpeg")
        #expect(reduced.data.prefix(3) == Data([0xFF, 0xD8, 0xFF]))
        #expect(Self.size(of: reduced) == CGSize(width: 2000, height: 1500))
        let small = try #require(PhotoReducer.reduce(Self.image(width: 800, height: 600)))
        #expect(Self.size(of: small) == CGSize(width: 800, height: 600), "never upscaled")
        #expect(PhotoReducer.reduce(Data("not an image".utf8)) == nil)
    }

    @Test func sixReducedPagesFitTheBody() throws {
        let page = try #require(PhotoReducer.reduce(Self.image(width: 3024, height: 4032)))
        #expect(Self.size(of: page).height == 2000)
        let total = page.base64.count * 6
        #expect(total < APIClient.bodyLimit, "six pages of a drawn page: \(total) characters")
    }

    @Test func aCameraImageIsReducedToo() throws {
        let drawn = try #require(UIImage(data: Self.image(width: 2400, height: 3200)))
        let reduced = try #require(PhotoReducer.reduce(drawn))
        #expect(Self.size(of: reduced) == CGSize(width: 1500, height: 2000))
    }
}
