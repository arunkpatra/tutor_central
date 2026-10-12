import Data
import Domain

/// What the shell records of the tutor's activity, and when (D82; plan decision 16): the app opened (the scene active),
/// a sign-in, a tab chosen, a link opened, a sign-out (recorded and posted before the wipe). Never a name or an id.
struct ActivityRecorder {
    let log: ActivityLog

    func appOpened() async {
        await log.record(.appOpened)
    }

    func signedIn() async {
        await log.record(.signedIn)
    }

    func tabChosen(_ tab: AppTab) async {
        await log.record(.tabOpened, screen: tab.rawValue)
    }

    func linkOpened(_ link: DeepLink) async {
        await log.record(.linkOpened, screen: Self.screen(of: link))
    }

    /// The scene went to the background or came back: what has gathered goes.
    func flush() async {
        await log.flush()
    }

    /// Before the wipe: the sign-out is recorded and everything gathered is posted with the session still there.
    func signingOut() async {
        await log.record(.signedOut)
        await log.flush()
    }

    /// A link by its kind alone.
    static func screen(of link: DeepLink) -> String {
        switch link {
        case .today: "today"
        case .student: "student"
        case .fees: "fees"
        case .attendance: "attendance"
        case .event: "event"
        case .school: "school"
        case .authCallback: "auth"
        }
    }
}
