import UIKit

/// Print (P10-Sheet): the system's print panel for a PDF. UIKit behind one wrapper (D8): SwiftUI has no print sheet.
public enum Printer {
    @MainActor public static func print(_ url: URL, title: String) {
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.outputType = .general
        info.jobName = title
        controller.printInfo = info
        controller.printingItem = url
        controller.present(animated: true)
    }
}
