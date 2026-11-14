package com.brixel.kameti.domain

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Timestamp
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** What a note is about (`public.note_target`). */
@Serializable
enum class NoteTarget {
    @SerialName("kameti") Kameti,
    @SerialName("member") Member,
    @SerialName("slot") Slot,
    @SerialName("payment") Payment,
    @SerialName("payout") Payout,
}

/**
 * Who can read a note (`public.note_visibility`, FR-71): the owner only, or
 * also the members involved.
 */
@Serializable
enum class NoteVisibility {
    @SerialName("private") Private,
    @SerialName("shared") Shared,
}

/** A row of `list_notes()` (FR-70 to FR-72): a note with its author's name. */
@Serializable
data class Note(
    val id: String,
    val kametiId: String,
    val targetType: NoteTarget = NoteTarget.Kameti,
    /** `null` for a kameti-wide note. */
    val targetId: String? = null,
    val body: String,
    val visibility: NoteVisibility = NoteVisibility.Private,
    val authorId: String? = null,
    val authorName: String? = null,
    val createdAt: Timestamp,
    val updatedAt: Timestamp = createdAt,
) {
    /** Edited after it was written. */
    val isEdited: Boolean get() = updatedAt > createdAt
}

/** Input for `add_note`. */
data class NewNote(
    val body: String,
    val visibility: NoteVisibility = NoteVisibility.Private,
    val targetType: NoteTarget = NoteTarget.Kameti,
    val targetId: String? = null,
)

/** Notes on a kameti. Writes are owner only; reads follow FR-71. */
interface NotesRepository {
    /** Newest first. Members get only the shared notes they're involved in. */
    suspend fun notes(kametiId: String): List<Note>
    suspend fun addNote(kametiId: String, new: NewNote): Note

    /** `null` leaves a field unchanged. */
    suspend fun updateNote(id: String, body: String?, visibility: NoteVisibility?): Note
    suspend fun deleteNote(id: String)
}

/**
 * The default when no notes backend is wired (older test setups): every
 * call fails, and screens treat notes as unavailable.
 */
class UnavailableNotesRepository : NotesRepository {
    private fun fail(): Nothing = throw Failure.Unknown("notes are not available")
    override suspend fun notes(kametiId: String): List<Note> = fail()
    override suspend fun addNote(kametiId: String, new: NewNote): Note = fail()
    override suspend fun updateNote(id: String, body: String?, visibility: NoteVisibility?): Note = fail()
    override suspend fun deleteNote(id: String): Unit = fail()
}
