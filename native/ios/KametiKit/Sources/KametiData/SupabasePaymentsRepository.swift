import Foundation
import KametiCore
import KametiDomain
import Supabase

public final class SupabasePaymentsRepository: PaymentsRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func payments(kametiId: String) async throws(Failure) -> [Payment] {
        try await run {
            try await client.from("payments").select()
                .eq("kameti_id", value: kametiId)
                .order("received_on", ascending: false)
                .order("created_at", ascending: false)
                .execute().value
        }
    }

    public func payouts(kametiId: String) async throws(Failure) -> [Payout] {
        try await run {
            try await client.from("payouts").select()
                .eq("kameti_id", value: kametiId)
                .order("paid_on", ascending: false)
                .execute().value
        }
    }

    public func recordPayment(_ new: NewPayment) async throws(Failure) -> Payment {
        try await run { try await client.rpc("record_payment", params: Params.recordPayment(new)).execute().value }
    }

    public func recordPayments(
        kametiId: String, receivedOn: Date, items: [BatchPaymentItem], method: PaymentMethod
    ) async throws(Failure) -> [Payment] {
        try await run {
            try await client.rpc(
                "record_payments_batch",
                params: Params.recordPayments(kametiId: kametiId, receivedOn: receivedOn, items: items, method: method)
            ).execute().value
        }
    }

    public func voidPayment(id: String, reason: String) async throws(Failure) -> Payment {
        try await run {
            try await client.rpc("void_payment", params: [
                "p_payment_id": JSONValue.string(id), "p_reason": .string(reason),
            ]).execute().value
        }
    }

    public func recordPayout(_ new: NewPayout) async throws(Failure) -> Payout {
        try await run { try await client.rpc("record_payout", params: Params.recordPayout(new)).execute().value }
    }

    public func voidPayout(id: String, reason: String) async throws(Failure) -> Payout {
        try await run {
            try await client.rpc("void_payout", params: [
                "p_payout_id": JSONValue.string(id), "p_reason": .string(reason),
            ]).execute().value
        }
    }
}
