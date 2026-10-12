import Domain
import Foundation
import Testing
@testable import Data

/// D84: the same request on the same day makes the same key; another body, route or day another; "another one" a
/// fresh key each time.
@Test func theSameRouteAndBodyMakeTheSameKeyOnTheDay() throws {
    let body = Data(#"{"a":1,"b":"x"}"#.utf8)
    let day = try #require(Day(iso: "2026-10-12")), next = try #require(Day(iso: "2026-10-13"))
    let key = IdempotencyKey.forBody(route: "ai/make", body: body, day: day)
    #expect(key == IdempotencyKey.forBody(route: "ai/make", body: body, day: day))
    #expect(key.hasPrefix("tc-") && key.count == 67)
    #expect(key != IdempotencyKey.forBody(route: "ai/make", body: Data(#"{"a":2,"b":"x"}"#.utf8), day: day))
    #expect(key != IdempotencyKey.forBody(route: "ai/plan", body: body, day: day))
    #expect(key != IdempotencyKey.forBody(route: "ai/make", body: body, day: next))
}

@Test func aFreshKeyDiffersEachTimeAndEveryKeyFitsTheAPIsBound() throws {
    let one = IdempotencyKey.fresh(), two = IdempotencyKey.fresh()
    #expect(one != two && one.hasPrefix("tc-"))
    let day = try #require(Day(iso: "2026-10-12"))
    #expect(one.count <= 200 && IdempotencyKey.forBody(route: "ai/generate", body: Data(), day: day).count <= 200)
}
