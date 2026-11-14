package com.brixel.kameti.data

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.core.get
import com.brixel.kameti.core.stringValue
import com.brixel.kameti.domain.AccountDeletionCheck
import com.brixel.kameti.domain.AccountRepository
import com.brixel.kameti.domain.AuditEntry
import com.brixel.kameti.domain.AuditRepository
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.ContactsRepository
import com.brixel.kameti.domain.NewNote
import com.brixel.kameti.domain.Note
import com.brixel.kameti.domain.NoteVisibility
import com.brixel.kameti.domain.NotesRepository
import com.brixel.kameti.domain.Profile
import com.brixel.kameti.domain.ProfileRepository
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.functions.functions
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import kotlinx.serialization.json.JsonElement

internal class SupabaseAuditRepository(private val client: SupabaseClient) : AuditRepository {
    override suspend fun audit(kametiId: String, limit: Int): List<AuditEntry> = call {
        client.from("audit_log").select {
            filter { eq("kameti_id", kametiId) }
            order("at", Order.DESCENDING)
            limit(limit.toLong())
        }.decodeList()
    }
}

internal class SupabaseProfileRepository(private val client: SupabaseClient) : ProfileRepository {
    override suspend fun myProfile(userId: String): Profile = call {
        client.from("profiles").select {
            filter { eq("id", userId) }
            single()
        }.decodeAs()
    }

    override suspend fun updateDisplayName(userId: String, name: String): Profile = call {
        client.from("profiles").update({ set("display_name", name) }) {
            filter { eq("id", userId) }
            select()
            single()
        }.decodeAs()
    }
}

internal class SupabaseContactsRepository(private val client: SupabaseClient) : ContactsRepository {
    override suspend fun contacts(): List<Contact> = call {
        client.from("contacts").select { order("name", Order.ASCENDING) }.decodeList()
    }
}

/**
 * Notes through the backend's RPCs (migration `notes`): `list_notes` reads
 * what the caller may see, and only the owner can add, edit or delete.
 */
internal class SupabaseNotesRepository(private val client: SupabaseClient) : NotesRepository {
    override suspend fun notes(kametiId: String): List<Note> = call {
        client.postgrest.rpc("list_notes", params("p_kameti_id" to text(kametiId))).decodeList()
    }

    override suspend fun addNote(kametiId: String, new: NewNote): Note = call {
        client.postgrest.rpc("add_note", Params.addNote(kametiId, new)).decodeAs()
    }

    override suspend fun updateNote(id: String, body: String?, visibility: NoteVisibility?): Note = call {
        client.postgrest.rpc("update_note", Params.updateNote(id, body, visibility)).decodeAs()
    }

    override suspend fun deleteNote(id: String) {
        call { client.postgrest.rpc("delete_note", params("p_note_id" to text(id))) }
    }
}

/**
 * Account deletion: `account_deletion_check()` says what would happen, and
 * the `delete-account` Edge Function does it (data first, then the sign-in).
 */
internal class SupabaseAccountRepository(private val client: SupabaseClient) : AccountRepository {
    override suspend fun deletionCheck(): AccountDeletionCheck = call {
        client.postgrest.rpc("account_deletion_check").decodeAs()
    }

    override suspend fun deleteAccount() {
        call {
            try {
                client.functions.invoke("delete-account", params("confirm" to flag(true)))
            } catch (error: RestException) {
                // The function answers {"error": "<code>"}; show its message.
                throw Failure.Server(errorCode(error.error) ?: "delete_failed")
            }
        }
    }

    private fun errorCode(body: String): String? = try {
        KametiJson.json.decodeFromString<JsonElement>(body)["error"]?.stringValue
    } catch (_: Exception) {
        null
    }
}
