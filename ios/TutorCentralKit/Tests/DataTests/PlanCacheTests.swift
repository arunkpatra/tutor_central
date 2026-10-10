import Domain
import Foundation
import Testing
@testable import Data

struct PlanCacheTests {
    @Test func aPlanIsKeptPerBatchAndDayAndOldDaysAreRemoved() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = PlanCache(centre: UUID(), directory: directory)
        let plan = try PlanSamples.sampleRecord(date: #require(Day(iso: "2026-10-07")))
        cache.keep(plan, at: PlanSamples.oct7at1635)
        #expect(cache.load(classID: plan.classID, date: plan.date)?.value.id == plan.id)
        try cache.removeAll(before: #require(Day(iso: "2026-10-08")))
        #expect(cache.load(classID: plan.classID, date: plan.date) == nil)
    }
}
