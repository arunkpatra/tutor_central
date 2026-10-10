import SwiftUI
import UIKit

/// The system share sheet opened from a plain action (the nav row's Share on P6-Check-Result and P10-Figure):
/// `UIActivityViewController` behind a `UIViewControllerRepresentable`, because SwiftUI's `ShareLink` must itself be
/// the tapped control (D8). It shares text or a file.
public struct ActivitySheet: UIViewControllerRepresentable {
    let text: String?
    let url: URL?

    public init(text: String) {
        self.text = text
        url = nil
    }

    public init(url: URL) {
        text = nil
        self.url = url
    }

    public func makeUIViewController(context _: Context) -> UIActivityViewController {
        var items: [Any] = []
        if let text {
            items.append(text)
        }
        if let url {
            items.append(url)
        }
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    public func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
