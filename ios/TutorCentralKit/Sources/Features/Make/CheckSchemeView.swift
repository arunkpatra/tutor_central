import Data
import DesignSystem
import Domain
import SwiftUI

/// The marking scheme (P6-Check-Scheme, -Typed): a paper created here (its answer key and marks) or typed (4000).
/// Check N pages runs the check and opens the marks. As the intro's chooser (P10-Make-Check), its first segment is "A
/// mock or paper made here" with the student's mocks first, and the footer is Use this scheme.
public struct CheckSchemeView: View {
    @Bindable var store: CheckStore
    let showsFocus: Bool
    let chooser: Bool
    let openResult: () -> Void
    @State private var typing: Bool
    @State private var picked: SchemeChoice.ID?
    @State private var topInset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss

    public init(
        store: CheckStore, typed: Bool = false, showsFocus: Bool = false, chooser: Bool = false,
        openResult: @escaping () -> Void
    ) {
        self.store = store
        self.showsFocus = showsFocus
        self.chooser = chooser
        self.openResult = openResult
        _typing = State(initialValue: typed)
    }

    static var wellHeight: CGFloat {
        220
    }

    private var pagesLabel: String {
        store.pages.count == 1 ? "Check 1 page" : "Check \(store.pages.count) pages"
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.sectionGap) {
                BackRow(title: "Marking scheme") { dismiss() }
                Segmented(
                    options: [(false, chooser ? "A mock or paper made here" : "A paper I created"), (true, "Type it")],
                    selection: $typing
                )
                if typing {
                    VStack(alignment: .leading, spacing: Tokens.fieldGap) {
                        MultilineWell(
                            label: "Marking scheme", text: $store.typedScheme, placeholder: "",
                            limit: SchemeSource.typedLimit, minHeight: Self.wellHeight, showsFocus: showsFocus,
                            slashed: true
                        )
                        footnote("One line per question with its marks: what earns full marks and what earns part.")
                    }
                } else if chooser {
                    Card {
                        VStack(spacing: 0) {
                            ForEach(store.schemeChoices) { choice in
                                PaperChoiceRow(title: choice.title, line: choice.line, chosen: chosenID == choice.id) {
                                    picked = choice.id
                                }
                                .rowDivider(choice.id != store.schemeChoices.last?.id)
                            }
                        }
                    }
                    footnote("A mock's key and marks, or a paper's, are the scheme.")
                } else {
                    Card {
                        VStack(spacing: 0) {
                            ForEach(store.papers) { paper in
                                PaperChoiceRow(
                                    title: paper.title(studentName: { _ in nil }), line: store.paperLine(paper),
                                    chosen: store.scheme == .paper(generationID: paper.id)
                                ) { store.scheme = .paper(generationID: paper.id) }
                                    .rowDivider(paper.id != store.papers.last?.id)
                            }
                        }
                    }
                    footnote("The paper's answer key and its marks are the scheme.")
                }
            }
            .padding(.horizontal, Tokens.pageSide)
            .padding(.top, max(0, Tokens.pageTop - topInset))
            .padding(.bottom, Tokens.contentBottom)
        }
        .statusBarGlass()
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .scrollDismissesKeyboard(.interactively)
        .background(Tokens.ground.color)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) { footer }
        .task {
            if chooser {
                await store.loadSchemes()
            } else {
                await store.loadPapers()
            }
        }
        .onChange(of: typing) { apply() }
        .onChange(of: store.typedScheme) { apply() }
        .onAppear(perform: apply)
    }

    @ViewBuilder private var footer: some View {
        if chooser {
            FooterButton {
                Button("Use this scheme") {
                    if typing {
                        store.chooseTyped()
                    } else if let choice = store.schemeChoices.first(where: { $0.id == chosenID }) {
                        store.choose(choice)
                    }
                    openResult()
                }
                .buttonStyle(.primary(.card))
                .disabled(typing ? !SchemeSource.typed(store.typedScheme).isValid : chosenID == nil)
            }
        } else {
            FooterButton {
                Button {
                    store.begin()
                    openResult()
                } label: {
                    Label(pagesLabel, systemImage: "sparkles")
                }
                .buttonStyle(.primary(.card))
                .disabled(!source.isValid || store.pages.isEmpty)
            }
        }
    }

    /// The row ticked: the one tapped here, else the scheme already chosen, else the first.
    private var chosenID: SchemeChoice.ID? {
        picked ?? store.schemeChoices.first { $0.scheme == store.scheme }?.id ?? store.schemeChoices.first?.id
    }

    private var source: SchemeSource {
        typing ? .typed(store.typedScheme) : store.scheme
    }

    private func apply() {
        guard !chooser else { return }
        if typing {
            store.scheme = .typed(store.typedScheme)
        } else if case .typed = store.scheme, let first = store.papers.first {
            store.scheme = .paper(generationID: first.id)
        }
    }

    private func footnote(_ text: String) -> some View {
        Text(text).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text3.color).padding(
            .horizontal,
            Tokens.rowGapInner
        )
    }
}

/// A paper to check against: its title and line, ticked in accentText when chosen, a ring otherwise.
private struct PaperChoiceRow: View {
    let title: String
    let line: String
    let chosen: Bool
    let choose: () -> Void
    static var ring: CGFloat {
        24
    }

    static var ringWidth: CGFloat {
        1.5
    }

    var body: some View {
        Button(action: choose) {
            HStack(spacing: Tokens.rowPaddingDense) {
                VStack(alignment: .leading, spacing: Tokens.rowGapInner) {
                    Text(title).typeStyle(Tokens.rowTitle).foregroundStyle(Tokens.text.color)
                    Text(line).typeStyle(Tokens.footnote).foregroundStyle(Tokens.text2.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if chosen {
                    Image(systemName: "checkmark").accessibilityHidden(true)
                        .font(.system(size: Tokens.iconButton, weight: .semibold))
                        .foregroundStyle(Tokens.accentText.color)
                        .frame(width: Self.ring, height: Self.ring)
                } else {
                    Circle().strokeBorder(Tokens.lineStrong.color, lineWidth: Self.ringWidth)
                        .frame(width: Self.ring, height: Self.ring)
                }
            }
            .padding(.vertical, Tokens.rowPaddingDense)
            .padding(.horizontal, Tokens.rowPaddingHorizontal)
            .contentShape(.rect)
        }
        .pressable()
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }
}
