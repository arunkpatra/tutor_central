import CoreGraphics
import Vision

/// A QR's payload read from a picture on this iPhone (Vision): nothing leaves the device.
public enum QRDecoder {
    /// The current revision first; where it reads nothing (the simulator says "Could not create inference context";
    /// CI's virtual machine answers empty), revision 1, which reads a QR without a model.
    public static func payload(in image: CGImage) -> String? {
        for revision in [VNDetectBarcodesRequest.currentRevision, VNDetectBarcodesRequestRevision1] {
            let request = VNDetectBarcodesRequest()
            request.revision = revision
            request.symbologies = [.qr]
            try? VNImageRequestHandler(cgImage: image).perform([request])
            if let payload = request.results?.first?.payloadStringValue {
                return payload
            }
        }
        return nil
    }
}
