import SwiftUI
import VisionKit

/// The system's document camera (P6-Scan-Camera; Take a photo, Add a page): VisionKit's
/// `VNDocumentCameraViewController` behind a `UIViewControllerRepresentable`, because SwiftUI has no camera (D8). Shown
/// as a full-screen cover with the system's own Cancel and Save; the first `maxPages` pages come back as images. The
/// simulator has no camera (`isSupported` is false there).
public struct DocumentCameraView: UIViewControllerRepresentable {
    let maxPages: Int
    let onPages: ([UIImage]) -> Void
    let onCancel: () -> Void

    public init(maxPages: Int, onPages: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
        self.maxPages = maxPages
        self.onPages = onPages
        self.onCancel = onCancel
    }

    @MainActor public static var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let camera = VNDocumentCameraViewController()
        camera.delegate = context.coordinator
        return camera
    }

    public func updateUIViewController(_: VNDocumentCameraViewController, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(maxPages: maxPages, onPages: onPages, onCancel: onCancel)
    }

    /// Hands back the scan's pages (the first `maxPages`), or a cancel; a camera failure is a cancel, logged.
    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let maxPages: Int
        let onPages: ([UIImage]) -> Void
        let onCancel: () -> Void

        init(maxPages: Int, onPages: @escaping ([UIImage]) -> Void, onCancel: @escaping () -> Void) {
            self.maxPages = maxPages
            self.onPages = onPages
            self.onCancel = onCancel
        }

        public func documentCameraViewController(
            _: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan
        ) {
            let count = min(scan.pageCount, maxPages)
            onPages((0 ..< count).map { scan.imageOfPage(at: $0) })
        }

        public func documentCameraViewControllerDidCancel(_: VNDocumentCameraViewController) {
            onCancel()
        }

        public func documentCameraViewController(_: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("document camera failed: \(error.localizedDescription)")
            onCancel()
        }
    }
}
