import Data
import Domain
import Foundation

/// What `bun shots <state>` launches: the fakes, filled with the boards' data, and a fixed clock, so every picture is
/// the same every time and matches its board.
public enum Fixtures {
    /// Wednesday 7 October 2026, 18:30 in India: "Good evening, Meera".
    public static let now: Date = {
        let components = DateComponents(
            timeZone: TimeZone(identifier: "Asia/Kolkata"),
            year: 2026,
            month: 10,
            day: 7,
            hour: 18,
            minute: 30
        )
        return Calendar(identifier: .gregorian).date(from: components) ?? .distantPast
    }()

    public static let meeraWorkspace = Workspace(
        user: FakeAuthRepository.meera,
        centre: Centre(
            id: UUID(uuid: (
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22,
                0x22
            )),
            name: "Bright Minds Tuition",
            whatsappNumber: "+919611299988"
        ),
        profile: Profile(displayName: "Meera Nair")
    )

    @MainActor public static func dependencies(for state: LaunchState) -> Dependencies {
        let auth = FakeAuthRepository()
        let centres = FakeCentreRepository()
        switch initialState(for: state) {
        case .needsOnboarding: auth.user = FakeAuthRepository.meera
        case .ready:
            auth.user = FakeAuthRepository.meera
            centres.workspace = meeraWorkspace
        case .loading, .signedOut: break
        }
        return Dependencies(auth: auth, centres: centres, now: { now }, bundleVersion: "0.1 (12)")
    }

    public static func initialState(for state: LaunchState) -> SessionStore.State {
        switch state {
        case .onboarding: .needsOnboarding(FakeAuthRepository.meera)
        case .todayEmpty, .laterStudents, .laterFees, .laterAttendance, .laterMore, .settings: .ready(meeraWorkspace)
        case .placeholder, .kit, .kitFields, .kitSurfaces, .kitPatterns, .kitDialog, .signin, .signinEmail, .signinCode,
             .signinCodeWrong, .signinPassword: .signedOut
        }
    }
}
