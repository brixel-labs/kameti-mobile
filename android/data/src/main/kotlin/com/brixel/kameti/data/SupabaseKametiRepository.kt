package com.brixel.kameti.data

import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.domain.KametiRepository
import com.brixel.kameti.domain.LedgerRepository
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MemberChanges
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.NewKameti
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.ShareInput
import com.brixel.kameti.domain.Slot
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import java.time.LocalDate

internal class SupabaseKametiRepository(private val client: SupabaseClient) : KametiRepository {
    private fun kametiParam(id: String) = params("p_kameti_id" to text(id))

    override suspend fun listKametis(): List<Kameti> = call {
        client.from("kametis").select { order("created_at", Order.DESCENDING) }.decodeList()
    }

    override suspend fun kameti(id: String): Kameti = call {
        client.from("kametis").select {
            filter { eq("id", id) }
            single()
        }.decodeAs()
    }

    override suspend fun members(kametiId: String): List<Member> = call {
        client.from("members").select {
            filter { eq("kameti_id", kametiId) }
            order("created_at", Order.ASCENDING)
        }.decodeList()
    }

    override suspend fun slots(kametiId: String): List<Slot> = call {
        client.from("slots").select {
            filter { eq("kameti_id", kametiId) }
            order("payout_month_index", Order.ASCENDING)
        }.decodeList()
    }

    override suspend fun shares(kametiId: String): List<Share> = call {
        client.from("shares").select {
            filter { eq("kameti_id", kametiId) }
            order("created_at", Order.ASCENDING)
        }.decodeList()
    }

    override suspend fun createKameti(new: NewKameti): Kameti = call {
        client.postgrest.rpc("create_kameti", Params.createKameti(new)).decodeAs()
    }

    override suspend fun updateKameti(id: String, changes: KametiChanges): Kameti = call {
        client.postgrest.rpc("update_kameti_draft", Params.updateKameti(id, changes)).decodeAs()
    }

    override suspend fun startKameti(id: String): Kameti = call {
        client.postgrest.rpc("start_kameti", kametiParam(id)).decodeAs()
    }

    override suspend fun deleteKametiDraft(id: String) {
        call { client.postgrest.rpc("delete_kameti_draft", kametiParam(id)) }
    }

    override suspend fun archiveKameti(id: String): Kameti = call {
        client.postgrest.rpc("archive_kameti", kametiParam(id)).decodeAs()
    }

    override suspend fun reopenKameti(id: String): Kameti = call {
        client.postgrest.rpc("reopen_kameti", kametiParam(id)).decodeAs()
    }

    override suspend fun restoreKameti(id: String): Kameti = call {
        client.postgrest.rpc("restore_kameti", kametiParam(id)).decodeAs()
    }

    override suspend fun duplicateKameti(id: String, name: String, startMonth: LocalDate): Kameti = call {
        client.postgrest.rpc(
            "duplicate_kameti",
            params("p_kameti_id" to text(id), "p_name" to text(name), "p_start_month" to day(startMonth)),
        ).decodeAs()
    }

    override suspend fun transferShare(shareId: String, toMemberId: String, fromMonth: Int, note: String?): Share =
        call {
            client.postgrest.rpc(
                "transfer_share",
                params(
                    "p_share_id" to text(shareId),
                    "p_to_member_id" to text(toMemberId),
                    "p_from_month" to number(fromMonth),
                    "p_note" to opt(note),
                ),
            ).decodeAs()
        }

    override suspend fun addMember(kametiId: String, new: NewMember): Member = call {
        client.postgrest.rpc("add_member", Params.addMember(kametiId, new)).decodeAs()
    }

    override suspend fun updateMember(id: String, changes: MemberChanges): Member = call {
        client.postgrest.rpc("update_member", Params.updateMember(id, changes)).decodeAs()
    }

    override suspend fun removeMember(id: String) {
        call { client.postgrest.rpc("remove_member", params("p_member_id" to text(id))) }
    }

    override suspend fun setSlotShares(slotId: String, shares: List<ShareInput>): List<Share> = call {
        client.postgrest.rpc("set_slot_shares", Params.setSlotShares(slotId, shares)).decodeList()
    }

    override suspend fun reorderSlots(kametiId: String, slotIdsInOrder: List<String>): List<Slot> = call {
        client.postgrest.rpc(
            "reorder_slots",
            params("p_kameti_id" to text(kametiId), "p_slot_ids" to texts(slotIdsInOrder)),
        ).decodeList()
    }
}

internal class SupabaseLedgerRepository(private val client: SupabaseClient) : LedgerRepository {
    override suspend fun memberBalances(kametiId: String): List<MemberBalanceRow> = call {
        client.from("member_balances").select { filter { eq("kameti_id", kametiId) } }.decodeList()
    }

    override suspend fun memberMonths(kametiId: String, memberId: String?): List<MemberMonthRow> = call {
        client.from("member_month_status").select {
            filter {
                eq("kameti_id", kametiId)
                if (memberId != null) eq("member_id", memberId)
            }
            order("month_index", Order.ASCENDING)
        }.decodeList()
    }

    override suspend fun monthCollections(kametiId: String): List<MonthCollectionRow> = call {
        client.from("month_collection").select {
            filter { eq("kameti_id", kametiId) }
            order("month_index", Order.ASCENDING)
        }.decodeList()
    }
}
