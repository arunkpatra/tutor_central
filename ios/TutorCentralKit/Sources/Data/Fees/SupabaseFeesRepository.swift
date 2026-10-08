import Domain
import Foundation
import Supabase

public final class SupabaseFeesRepository: FeesRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()
    private static let columns = "id, student_id, period, amount, status, paid_at, paid_method, waived_reason"

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func invoices(centre: UUID, month: Period) async throws -> [FeeInvoice] {
        let response = try await client.from("fee_invoices").select(Self.columns)
            .eq("centre_id", value: centre).eq("period", value: month.isoDay).execute()
        return try Self.decoder.decode([InvoiceRow].self, from: response.data).compactMap(\.invoice)
    }

    public func invoices(centre: UUID, student: UUID) async throws -> [FeeInvoice] {
        let response = try await client.from("fee_invoices").select(Self.columns)
            .eq("centre_id", value: centre).eq("student_id", value: student).order("period", ascending: false).execute()
        return try Self.decoder.decode([InvoiceRow].self, from: response.data).compactMap(\.invoice)
    }

    public func dueBefore(centre: UUID, month: Period) async throws -> [FeeInvoice] {
        let response = try await client.from("fee_invoices").select(Self.columns)
            .eq("centre_id", value: centre).eq("status", value: "due").lt("period", value: month.isoDay).execute()
        return try Self.decoder.decode([InvoiceRow].self, from: response.data).compactMap(\.invoice)
    }

    public func generate(centre: UUID, month: Period) async throws -> Int {
        let response = try await client.rpc("generate_fees", params: [
            "p_centre": AnyJSON.string(centre.uuidString), "p_period": .string(month.isoDay),
        ]).execute()
        return try Self.decoder.decode(Int.self, from: response.data)
    }

    public func markPaid(id: UUID, method: MonthFee.PaidMethod, at: Date) async throws -> FeeInvoice {
        try await update(id, [
            "status": .string("paid"), "paid_at": .string(ISO8601DateFormatter().string(from: at)),
            "paid_method": .string(method.rawValue), "waived_reason": .null,
        ])
    }

    public func markDue(id: UUID) async throws -> FeeInvoice {
        try await update(id, ["status": .string("due"), "paid_at": .null, "paid_method": .null])
    }

    public func waive(id: UUID, reason: String) async throws -> FeeInvoice {
        try await update(
            id,
            ["status": .string("waived"), "paid_at": .null, "paid_method": .null, "waived_reason": .string(reason)]
        )
    }

    private func update(_ id: UUID, _ values: [String: AnyJSON]) async throws -> FeeInvoice {
        let response = try await client.from("fee_invoices").update(values).eq("id", value: id)
            .select(Self.columns).single().execute()
        guard let invoice = try Self.decoder.decode(InvoiceRow.self, from: response.data).invoice else {
            throw URLError(.cannotParseResponse)
        }
        return invoice
    }
}
