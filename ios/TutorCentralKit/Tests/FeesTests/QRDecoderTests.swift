import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import Testing
@testable import Fees

struct QRDecoderTests {
    static func qr(_ text: String) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)) else { return nil }
        return CIContext().createCGImage(output, from: output.extent)
    }

    @Test func readsAUPIQRAndRefusesAPlainPicture() throws {
        let payload = "upi://pay?pa=meera@okhdfcbank&pn=Meera%20Nair&cu=INR"
        let image = try #require(Self.qr(payload))
        #expect(QRDecoder.payload(in: image) == payload)
        let square = CGRect(x: 0, y: 0, width: 200, height: 200)
        let blank = try #require(CIContext().createCGImage(CIImage(color: .white).cropped(to: square), from: square))
        #expect(QRDecoder.payload(in: blank) == nil)
    }
}
