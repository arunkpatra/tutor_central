import Domain
import Foundation
import Supabase

/// The centre through PostgREST: RLS shows a user only the centres they belong to and their own profile.
public final class SupabaseCentreRepository: CentreRepository {
    private let client: SupabaseClient
    static let decoder = PostgRESTDecoder.make()

    public init(client: SupabaseClient) {
        self.client = client
    }

    public func workspace(for user: AuthUser) async throws -> Workspace? {
        let response = try await client.from("centres")
            .select("id, name, whatsapp_number, upi_id, upi_confirmed_at, payment_link, send_receipts")
            .order("created_at")
            .limit(1)
            .execute()
        guard let row = try Self.decoder.decode([CentreRow].self, from: response.data).first else { return nil }
        let profiles: [ProfileRow] = try await client.from("profiles")
            .select("display_name")
            .eq("user_id", value: user.id)
            .execute()
            .value
        return Workspace(
            user: user,
            centre: row.centre,
            profile: Profile(displayName: profiles.first?.displayName)
        )
    }

    public func createCentre(_ draft: CentreDraft, for user: AuthUser) async throws -> Workspace {
        let params: [String: AnyJSON] = [
            "p_name": .string(draft.centreName),
            "p_whatsapp": draft.whatsappNumber.map(AnyJSON.string) ?? .null,
            "p_display_name": .string(draft.displayName),
        ]
        let id: UUID = try await client.rpc("create_centre", params: params).execute().value
        return Workspace(
            user: user,
            centre: Centre(id: id, name: draft.centreName, whatsappNumber: draft.whatsappNumber),
            profile: Profile(displayName: draft.displayName)
        )
    }

    public func updateCentreName(id: UUID, name: String) async throws {
        try await client.from("centres").update(["name": AnyJSON.string(name)]).eq("id", value: id).execute()
    }

    public func updateWhatsAppNumber(id: UUID, number: String?) async throws {
        try await client.from("centres")
            .update(["whatsapp_number": number.map(AnyJSON.string) ?? .null])
            .eq("id", value: id)
            .execute()
    }

    public func updateUPI(id: UUID, upiID: String?) async throws {
        try await client.from("centres")
            .update(["upi_id": upiID.map(AnyJSON.string) ?? .null, "upi_confirmed_at": .null])
            .eq("id", value: id)
            .execute()
    }

    public func updatePaymentLink(id: UUID, link: String?) async throws {
        try await client.from("centres").update(["payment_link": link.map(AnyJSON.string) ?? .null]).eq("id", value: id)
            .execute()
    }

    public func updateSendReceipts(id: UUID, on: Bool) async throws {
        try await client.from("centres").update(["send_receipts": AnyJSON.bool(on)]).eq("id", value: id).execute()
    }

    public func confirmUPI(id: UUID, at: Date) async throws {
        try await client.from("centres")
            .update(["upi_confirmed_at": AnyJSON.string(ISO8601DateFormatter().string(from: at))])
            .eq("id", value: id)
            .execute()
    }

    public func updateProfile(displayName: String) async throws {
        let userID = try await client.auth.session.user.id
        try await client.from("profiles")
            .update(["display_name": AnyJSON.string(displayName)])
            .eq("user_id", value: userID)
            .execute()
    }
}

/// A `centres` row with its payment columns (decoded from snake case by `PostgRESTDecoder`).
struct CentreRow: Decodable {
    let id: UUID
    let name: String
    let whatsappNumber: String?
    let upiId: String?
    let upiConfirmedAt: Date?
    let paymentLink: String?
    let sendReceipts: Bool

    var centre: Centre {
        Centre(
            id: id, name: name, whatsappNumber: whatsappNumber,
            payments: PaymentsRow(
                upiId: upiId,
                upiConfirmedAt: upiConfirmedAt,
                paymentLink: paymentLink,
                sendReceipts: sendReceipts
            )
            .settings
        )
    }
}

/// The payment columns alone, as a settings update answers them.
struct PaymentsRow: Decodable {
    let upiId: String?
    let upiConfirmedAt: Date?
    let paymentLink: String?
    let sendReceipts: Bool

    var settings: PaymentSettings {
        PaymentSettings(
            upiID: upiId,
            paymentLink: paymentLink,
            sendReceipts: sendReceipts,
            upiConfirmedAt: upiConfirmedAt
        )
    }
}

private struct ProfileRow: Decodable {
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}
