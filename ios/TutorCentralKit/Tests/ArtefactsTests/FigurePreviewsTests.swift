import Domain
import Testing
@testable import Artefacts

/// The Kit's figure previews (plan/phase-15-plan.md decision 19): one per template, each a spec the app would draw.
struct FigurePreviewsTests {
    @Test func theSevenPreviewsAreTheSevenTemplatesAndEachPassesItsRule() {
        let specs = FigurePreviews.specs
        #expect(specs.map(\.kind) == FigureSpec.Kind.allCases)
        #expect(specs.allSatisfy { $0.validate() == nil })
    }
}
