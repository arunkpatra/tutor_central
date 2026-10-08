import CoreGraphics
import Vision

/// A QR's payload read from a picture on this iPhone (Vision): nothing leaves the device.
public enum QRDecoder {
    /// The current revision first; where Vision cannot make its model's context (the simulator says "Could not create
    /// inference context"), revision 1, which reads a QR without one.
    public static func payload(in image: CGImage) -> String? {
        for revision in [VNDetectBarcodesRequest.currentRevision, VNDetectBarcodesRequestRevision1] {
            let request = VNDetectBarcodesRequest()
            request.revision = revision
            request.symbologies = [.qr]
            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
                return request.results?.first?.payloadStringValue
            } catch {
                continue
            }
        }
        return nil
    }
}
