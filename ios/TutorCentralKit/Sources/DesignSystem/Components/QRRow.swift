import SwiftUI
import UIKit

/// Parent payments (P5-Payments-QR): the QR's thumbnail, "QR from your UPI app" over its line, a quiet Remove in
/// `overdue`. The thumbnail sits on white with a 4 pt inset: that is the QR's own quiet zone, which a camera needs to
/// read it in either appearance, not a theme colour.
public struct QRRow: View {
    static let thumbnail: CGFloat = 56
    static let inset: CGFloat = 4
    static let radius: CGFloat = 10
    static let quietZone = Color.white

    let image: UIImage
    let title: String
    let line: String
    let remove: () -> Void

    public init(image: UIImage, title: String, line: String, remove: @escaping () -> Void) {
        self.image = image
        self.title = title
        self.line = line
        self.remove = remove
    }

    public var body: some View {
        HStack(spacing: Tokens.rowPaddingDense) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .padding(Self.inset)
                .frame(width: Self.thumbnail, height: Self.thumbnail)
                .background(Self.quietZone, in: .rect(cornerRadius: Self.radius, style: .continuous))
                .accessibilityLabel("Your UPI QR")
            RowTitles(title: title, subtitle: line)
            Button("Remove", action: remove).buttonStyle(.quiet(tone: .overdue))
        }
    }
}

#Preview {
    QRRow(
        image: UIImage(systemName: "qrcode") ?? UIImage(), title: "QR from your UPI app",
        line: "Kept on this iPhone to show a parent.", remove: {}
    )
    .padding(Tokens.pageSide)
    .background(Tokens.surface1.color)
}
