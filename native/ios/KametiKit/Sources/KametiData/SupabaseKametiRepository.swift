import Foundation
import KametiCore
import KametiDomain
import Supabase

public final class SupabaseKametiRepository: KametiRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func listKametis() async throws(Failure) -> [Kameti] {
        try await run {
            try await client.from("kametis").select()
                .order("created_at", ascending: false)
                .execute().value
        }
    }

    public func kameti(id: String) async throws(Failure) -> Kameti {
        try await run {
            try await client.from("kametis").select().eq("id", value: id).single().execute().value
        }
    }

    public func members(kametiId: String) async throws(Failure) -> [Member] {
        try await run {
            try await client.from("members").select()
                .eq("kameti_id", value: kametiId).order("created_at").execute().value
        }
    }

    public func slots(kametiId: String) async throws(Failure) -> [Slot] {
        try await run {
            try await client.from("slots").select()
                .eq("kameti_id", value: kametiId).order("payout_month_index").execute().value
        }
    }

    public func shares(kametiId: String) async throws(Failure) -> [Share] {
        try await run {
            try await client.from("shares").select()
                .eq("kameti_id", value: kametiId).order("created_at").execute().value
        }
    }

    public func createKameti(_ new: NewKameti) async throws(Failure) -> Kameti {
        try await run { try await client.rpc("create_kameti", params: Params.createKameti(new)).execute().value }
    }

    public func updateKameti(id: String, changes: KametiChanges) async throws(Failure) -> Kameti {
        try await run {
            try await client.rpc("update_kameti_draft", params: Params.updateKameti(id: id, changes)).execute().value
        }
    }

    public func startKameti(id: String) async throws(Failure) -> Kameti {
        try await run {
            try await client.rpc("start_kameti", params: ["p_kameti_id": JSONValue.string(id)]).execute().value
        }
    }

    public func archiveKameti(id: String) async throws(Failure) -> Kameti {
        try await run {
            try await client.rpc("archive_kameti", params: ["p_kameti_id": JSONValue.string(id)]).execute().value
        }
    }

    public func reopenKameti(id: String) async throws(Failure) -> Kameti {
        try await run {
            try await client.rpc("reopen_kameti", params: ["p_kameti_id": JSONValue.string(id)]).execute().value
        }
    }

    public func restoreKameti(id: String) async throws(Failure) -> Kameti {
        try await run {
            try await client.rpc("restore_kameti", params: ["p_kameti_id": JSONValue.string(id)]).execute().value
        }
    }

    public func duplicateKameti(id: String, name: String, startMonth: Date) async throws(Failure) -> Kameti {
        try await run {
            try await client.rpc("duplicate_kameti", params: [
                "p_kameti_id": JSONValue.string(id), "p_name": .string(name), "p_start_month": .day(startMonth),
            ] as RPCParams).execute().value
        }
    }

    public func transferShare(shareId: String, toMemberId: String, fromMonth: Int, note: String?) async throws(Failure) -> Share {
        try await run {
            try await client.rpc("transfer_share", params: [
                "p_share_id": JSONValue.string(shareId), "p_to_member_id": .string(toMemberId),
                "p_from_month": .int(fromMonth), "p_note": .opt(note),
            ] as RPCParams).execute().value
        }
    }

    public func addMember(kametiId: String, _ new: NewMember) async throws(Failure) -> Member {
        try await run {
            try await client.rpc("add_member", params: Params.addMember(kametiId: kametiId, new)).execute().value
        }
    }

    public func updateMember(id: String, changes: MemberChanges) async throws(Failure) -> Member {
        try await run {
            try await client.rpc("update_member", params: Params.updateMember(id: id, changes)).execute().value
        }
    }

    public func removeMember(id: String) async throws(Failure) {
        try await run {
            _ = try await client.rpc("remove_member", params: ["p_member_id": JSONValue.string(id)]).execute()
        }
    }

    public func setSlotShares(slotId: String, shares: [ShareInput]) async throws(Failure) -> [Share] {
        try await run {
            try await client.rpc("set_slot_shares", params: Params.setSlotShares(slotId: slotId, shares)).execute().value
        }
    }

    public func reorderSlots(kametiId: String, slotIdsInOrder: [String]) async throws(Failure) -> [Slot] {
        try await run {
            try await client.rpc("reorder_slots", params: [
                "p_kameti_id": JSONValue.string(kametiId),
                "p_slot_ids": .array(slotIdsInOrder.map { .string($0) }),
            ]).execute().value
        }
    }
}

public final class SupabaseLedgerRepository: LedgerRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func memberBalances(kametiId: String) async throws(Failure) -> [MemberBalanceRow] {
        try await run {
            try await client.from("member_balances").select().eq("kameti_id", value: kametiId).execute().value
        }
    }

    public func memberMonths(kametiId: String, memberId: String?) async throws(Failure) -> [MemberMonthRow] {
        try await run {
            var query = client.from("member_month_status").select().eq("kameti_id", value: kametiId)
            if let memberId { query = query.eq("member_id", value: memberId) }
            return try await query.order("month_index").execute().value
        }
    }

    public func monthCollections(kametiId: String) async throws(Failure) -> [MonthCollectionRow] {
        try await run {
            try await client.from("month_collection").select()
                .eq("kameti_id", value: kametiId).order("month_index").execute().value
        }
    }
}
