import SwiftUI

/// A sheet at its content's height (New class, Sign in with email): the header pinned, the fields under it. When the
/// fields are taller than the room left (the larger text sizes, the keyboard up) they scroll and the header stays:
/// sized to the whole content it was pushed off the top (build 10). The height is the content's own, measured, not
/// what the detent gives back, which would grow it each pass; medium until measured, since a zero-height detent closes
/// the sheet as it opens.
public struct FittedSheet<Header: View, Content: View>: View {
    let spacing: CGFloat
    let bottom: CGFloat
    let header: Header
    let content: Content
    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    public init(
        spacing: CGFloat, bottom: CGFloat, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.bottom = bottom
        self.header = header()
        self.content = content()
    }

    private var height: CGFloat {
        headerHeight > 0 && contentHeight > 0 ? Tokens.inline + headerHeight + spacing + contentHeight : 0
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            header
                .padding(.horizontal, Tokens.pageSide)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
            ScrollView {
                content
                    .padding(.horizontal, Tokens.pageSide)
                    .padding(.bottom, bottom)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.top, Tokens.inline)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([height > 0 ? .height(height) : .medium])
    }
}
