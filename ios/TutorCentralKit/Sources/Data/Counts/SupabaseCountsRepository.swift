import Domain
import Foundation
import Supabase

/// The counts through PostgREST, scoped by RLS and by the centre: active students, the fees still due, the classes
/// that meet on the day (ISO weekday in India).
public final class SupabaseCountsRepository: CountsRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func todayCounts(centre: UUID, on date: Date) async throws -> TodayCounts {
        async let students = client.from("students")
            .select("id", head: true, count: .exact)
            .eq("centre_id", value: centre)
            .is("archived_at", value: nil)
            .execute()
            .count
        async let due: [AmountRow] = client.from("fee_invoices")
            .select("amount")
            .eq("centre_id", value: centre)
            .eq("status", value: "due")
            .execute()
            .value
        let weekday = Self.isoWeekday(date)
        async let classes = client.from("classes")
            .select("id", head: true, count: .exact)
            .eq("centre_id", value: centre)
            .is("archived_at", value: nil)
            .contains("meeting_days", value: [weekday])
            .execute()
            .count
        return try await TodayCounts(
            students: students ?? 0,
            due: due.map { Money(rupees: $0.amount) }.total,
            classesToday: classes ?? 0
        )
    }

    /// Monday 1 … Sunday 7, in India.
    static func isoWeekday(_ date: Date) -> Int {
        (DayHeading.india.component(.weekday, from: date) + 5) % 7 + 1
    }
}

private struct AmountRow: Decodable {
    let amount: Int
}
