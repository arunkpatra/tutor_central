import Foundation
import Testing
@testable import Data

/// D84: the same request makes the same key; another body another; "another one" a fresh key each time.
@Test func theSameRouteAndBodyMakeTheSameKey() {
    let body = Data(#"{"a":1,"b":"x"}"#.utf8)
    let key = IdempotencyKey.forBody(route: "ai/make", body: body)
    #expect(key == IdempotencyKey.forBody(route: "ai/make", body: body))
    #expect(key.hasPrefix("tc-") && key.count == 67)
    #expect(key != IdempotencyKey.forBody(route: "ai/make", body: Data(#"{"a":2,"b":"x"}"#.utf8)))
    #expect(key != IdempotencyKey.forBody(route: "ai/plan", body: body))
}

@Test func aFreshKeyDiffersEachTimeAndEveryKeyFitsTheAPIsBound() {
    let one = IdempotencyKey.fresh(), two = IdempotencyKey.fresh()
    #expect(one != two && one.hasPrefix("tc-"))
    #expect(one.count <= 200 && IdempotencyKey.forBody(route: "ai/generate", body: Data()).count <= 200)
}
