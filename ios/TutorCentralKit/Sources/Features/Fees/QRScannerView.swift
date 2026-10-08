import SwiftUI
import VisionKit

/// The camera for a UPI QR (Scan a QR on Parent payments): VisionKit's `DataScannerViewController` behind a
/// `UIViewControllerRepresentable`, because SwiftUI has no barcode camera (D8). The first QR it sees is handed back;
/// the simulator has no camera (`isSupported` is false there). Shown in a sheet, so a swipe down closes it.
public struct QRScannerView: UIViewControllerRepresentable {
    let onPayload: (String) -> Void

    public init(onPayload: @escaping (String) -> Void) {
        self.onPayload = onPayload
    }

    /// The device has a camera that can read barcodes (permission is `CameraAccess`'s question).
    @MainActor public static var isSupported: Bool {
        DataScannerViewController.isSupported
    }

    public func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .balanced, isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    public func updateUIViewController(_ scanner: DataScannerViewController, context _: Context) {
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    public static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator _: Coordinator) {
        scanner.stopScanning()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload)
    }

    /// Hands back the first QR's text, once.
    public final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onPayload: (String) -> Void
        private var handed = false

        init(onPayload: @escaping (String) -> Void) {
            self.onPayload = onPayload
        }

        public func dataScanner(
            _: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems _: [RecognizedItem]
        ) {
            guard !handed else { return }
            for item in addedItems {
                if case let .barcode(barcode) = item, let payload = barcode.payloadStringValue {
                    handed = true
                    onPayload(payload)
                    return
                }
            }
        }
    }
}
