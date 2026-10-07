import Foundation
import Onboarding

/// The sign-in line's two links. The owner has not published the pages yet (session 4): both go to the site the
/// bundle id names until he gives their addresses; real pages are needed before App Store review (STATE.md).
enum Legal {
    static let site = URL(string: "https://journium.app") ?? URL(fileURLWithPath: "/")
    static let links = SignInView.Legal(terms: site, privacy: site)
}
