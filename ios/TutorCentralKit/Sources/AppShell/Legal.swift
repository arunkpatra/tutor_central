import Foundation
import Onboarding

/// The sign-in line's two links: pages on the product website, tutorcentral.in (its own phase builds the site).
enum Legal {
    static let terms = URL(string: "https://tutorcentral.in/terms") ?? URL(fileURLWithPath: "/")
    static let privacy = URL(string: "https://tutorcentral.in/privacy") ?? URL(fileURLWithPath: "/")
    static let links = SignInView.Legal(terms: terms, privacy: privacy)
}
