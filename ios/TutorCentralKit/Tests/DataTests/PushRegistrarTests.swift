import Foundation
import Testing
@testable import Data

@MainActor struct PushRegistrarTests {
    final class Calls {
        var registered = 0
        var unregistered = 0
    }

    func make(
        _ center: FakeNotificationCenter, tokens: FakeDeviceTokenRepository, calls: Calls, device: String? = "device-1"
    ) -> PushRegistrar {
        PushRegistrar(
            notifications: center, tokens: tokens, registerForRemote: { calls.registered += 1 },
            unregisterFromRemote: { calls.unregistered += 1 }, deviceID: { device }, environment: "sandbox", build: 28
        )
    }

    /// The review's R-app-4: an offline sign-out cannot delete the token's row, so the app also unregisters from APNs
    /// (no connection needed); Apple then answers 410 for the token and the server retires it.
    @Test func forgettingUnregistersFromApplePushEvenWhenTheRowCannotBeDeleted() async {
        let calls = Calls()
        let offline = FakeDeviceTokenRepository(failure: URLError(.notConnectedToInternet))
        await make(FakeNotificationCenter(permission: .allowed), tokens: offline, calls: calls).forget()
        #expect(calls.unregistered == 1)
        let online = FakeDeviceTokenRepository()
        await make(FakeNotificationCenter(permission: .allowed), tokens: online, calls: calls).forget()
        #expect(calls.unregistered == 2)
        #expect(await online.forgotten == ["device-1"])
    }

    @Test func registersOnlyOnceNotificationsAreAllowedAndNeverAsks() async {
        let calls = Calls()
        let notAsked = FakeNotificationCenter(permission: .notAsked)
        await make(notAsked, tokens: FakeDeviceTokenRepository(), calls: calls).register()
        let refused = FakeNotificationCenter(permission: .refused)
        await make(refused, tokens: FakeDeviceTokenRepository(), calls: calls).register()
        #expect(calls.registered == 0 && notAsked.asked == 0 && refused.asked == 0)
        await make(FakeNotificationCenter(permission: .allowed), tokens: FakeDeviceTokenRepository(), calls: calls)
            .register()
        #expect(calls.registered == 1)
    }

    @Test func theTokenIsKeptInHexWithTheDeviceTheEnvironmentAndTheBuild() async {
        let tokens = FakeDeviceTokenRepository()
        let push = make(FakeNotificationCenter(permission: .allowed), tokens: tokens, calls: Calls())
        await push.received(token: Data([0x0A, 0xFF, 0x00, 0x7B]))
        #expect(await tokens.saved == [
            DeviceToken(deviceID: "device-1", token: "0aff007b", environment: "sandbox", build: 28),
        ])
        await push.forget()
        #expect(await tokens.forgotten == ["device-1"])
    }

    @Test func noDeviceIDKeepsNothingAndAFailedSaveIsQuiet() async {
        let none = FakeDeviceTokenRepository()
        let push = make(FakeNotificationCenter(permission: .allowed), tokens: none, calls: Calls(), device: nil)
        await push.received(token: Data([1]))
        await push.forget()
        #expect(await none.saved.isEmpty)
        #expect(await none.forgotten.isEmpty)
        let failing = FakeDeviceTokenRepository(failure: URLError(.notConnectedToInternet))
        await make(FakeNotificationCenter(permission: .allowed), tokens: failing, calls: Calls())
            .received(token: Data([1]))
        #expect(await failing.saved.isEmpty)
    }

    @Test func aTokenBeforeTheShellListensIsHandedOverOnce() {
        let relay = PushRelay()
        relay.received(Data([1, 2]))
        var heard: [Data] = []
        relay.onToken = { heard.append($0) }
        relay.onToken = { heard.append($0) }
        #expect(heard == [Data([1, 2])])
        relay.received(Data([3]))
        #expect(heard == [Data([1, 2]), Data([3])])
    }
}
