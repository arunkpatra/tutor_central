#if DEBUG
    import SwiftUI

    /// Every component in every state the Kit boards draw (Kit-Controls, Kit-Surfaces), on `ground`. Reached by
    /// `bun shots kit` (and the states that start further down) and the "TutorCentral Kit" scheme; never in a Release
    /// build. A screenshot holds one screen, so each `Section` is a place the Kit can open at.
    public struct KitView: View {
        public enum Section: String, CaseIterable, Sendable {
            case controls
            case fields
            case surfaces
            case patterns
            case dialog
            case phase7
            case phase10
            case phase10Figures
            case phase20
        }

        let startAt: Section
        /// The figure templates, drawn by Artefacts and handed in by AppShell (DesignSystem does not import Domain).
        let figures: (() -> AnyView)?

        public init(startAt: Section = .controls, figures: (() -> AnyView)? = nil) {
            self.startAt = startAt
            self.figures = figures
        }

        public var body: some View {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                        KitControls()
                        KitSurfaces()
                        KitPhase7()
                        KitPhase10(figures: figures)
                        KitPhase20()
                    }
                    .padding(.horizontal, Tokens.pageSide)
                    .padding(.top, Tokens.heroInset)
                    .padding(.bottom, Tokens.contentBottom)
                }
                // Clipped to the safe area, so a section opened mid-scroll does not run under the clock.
                .clipped()
                .background(Tokens.ground.color)
                .onAppear { proxy.scrollTo(startAt, anchor: .top) }
            }
        }
    }

    /// One group of the Kit: its eyebrow, then its samples.
    struct KitGroup<Content: View>: View {
        let title: String
        let spacing: CGFloat
        let content: Content

        init(_ title: String, spacing: CGFloat = Tokens.tileGap, @ViewBuilder content: () -> Content) {
            self.title = title
            self.spacing = spacing
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: spacing) {
                Eyebrow(title)
                content
            }
        }
    }

    /// A note under a sample, footnote text3.
    struct KitNote: View {
        let text: String

        init(_ text: String) {
            self.text = text
        }

        var body: some View {
            Text(text).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color)
        }
    }
#endif
