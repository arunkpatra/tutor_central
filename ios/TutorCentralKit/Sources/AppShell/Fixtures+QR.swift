import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

extension Fixtures {
    /// Meera's UPI QR as a PNG (P5-Payments-QR's thumbnail): made with Core Image, so `payments-qr` draws a real QR
    /// that the decoder reads back.
    static func sampleQR() -> Data {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data("upi://pay?pa=meera@okhdfcbank&pn=Meera%20Nair".utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)),
              let image = CIContext().createCGImage(output, from: output.extent) else { return Data() }
        return UIImage(cgImage: image).pngData() ?? Data()
    }
}
