import SwiftUI
import UIKit

/// The system share sheet for text, opened from a plain action (the nav row's Share on P6-Check-Result):
/// `UIActivityViewController` behind a `UIViewControllerRepresentable`, because SwiftUI's `ShareLink` must itself be
/// the tapped control (D8).
struct ActivitySheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
