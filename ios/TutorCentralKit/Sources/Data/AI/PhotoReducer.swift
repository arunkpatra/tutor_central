import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// Every photo is reduced on this iPhone before it is sent: a JPEG at most 2000 px on its long edge at quality 0.7
/// (a page of handwriting is 350 to 900 KB), so six pages fit the API's request body (design-tokens.md, Phase 6).
/// Never upscaled; the camera's orientation applied. Nothing is kept: the bytes go in the request and nowhere else.
public enum PhotoReducer {
    public static let longEdge: CGFloat = 2000
    public static let quality: CGFloat = 0.7

    /// A picked photo's file (HEIC, JPEG, PNG); nil when it is not an image.
    public static func reduce(_ data: Data) -> ImageUpload? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
        else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: min(longEdge, max(width, height)),
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return jpeg(image)
    }

    /// A page from the document camera.
    public static func reduce(_ image: UIImage) -> ImageUpload? {
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let longest = max(pixels.width, pixels.height)
        guard longest > 0 else { return nil }
        let factor = min(1, longEdge / longest)
        let target = CGSize(width: (pixels.width * factor).rounded(), height: (pixels.height * factor).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let drawn = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return drawn.cgImage.flatMap(jpeg)
    }

    private static func jpeg(_ image: CGImage) -> ImageUpload? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        else {
            return nil
        }
        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { return nil }
        return ImageUpload(data: data as Data, mediaType: "image/jpeg")
    }
}
