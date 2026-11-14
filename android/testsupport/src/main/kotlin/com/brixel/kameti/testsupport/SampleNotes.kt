package com.brixel.kameti.testsupport

import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.NewNote
import com.brixel.kameti.domain.Note
import com.brixel.kameti.domain.NoteTarget
import com.brixel.kameti.domain.NoteVisibility
import com.brixel.kameti.domain.NotesRepository
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * The demo's notes, with the backend's rules (FR-70 to FR-72): the owner
 * reads and writes everything; a member reads only shared notes they're
 * involved in (any kameti-wide note, a note on themselves, on a slot they
 * share, or on their own payment or payout).
 */
class SampleNotesRepository(
    private val kametis: SampleKametiRepository,
    private val payments: SamplePaymentStore,
    private val log: SampleAuditLog = SampleAuditLog(),
) : NotesRepository {
    private val lock = Any()
    private val now = SampleData.now
    private var counter = 0

    private fun note(
        id: String, kameti: String, target: NoteTarget, targetId: String?, visibility: NoteVisibility,
        author: String, ago: Long, body: String,
    ) = Note(
        id = id, kametiId = kameti, targetType = target, targetId = targetId, body = body, visibility = visibility,
        authorId = author, authorName = SampleData.ownerNames[author], createdAt = now.minusSeconds(ago),
    )

    private var notes = listOf(
        note("n1", "family", NoteTarget.Member, "f1", NoteVisibility.Private, SampleData.USER_ID, 2 * HOUR,
            "Ali is travelling until the 12th and will pay November when he's back."),
        note("n2", "family", NoteTarget.Member, "f2", NoteVisibility.Shared, SampleData.USER_ID, 7 * DAY,
            "Sara's extra Rs 2,50,000 in October counts as credit for November."),
        note("n3", "family", NoteTarget.Slot, "fs1", NoteVisibility.Private, SampleData.USER_ID, 29 * DAY,
            "October's payout was handed to Ali in cash at home."),
        note("n4", "family", NoteTarget.Kameti, null, NoteVisibility.Shared, SampleData.USER_ID, 40 * DAY,
            "Payments by the 10th please. Bank: Meezan, account details in the family group."),
        note("o-n1", "office", NoteTarget.Kameti, null, NoteVisibility.Shared, "someone-else", 5 * DAY,
            "From December, bank transfers only please, no cash."),
        note("o-n2", "office", NoteTarget.Member, "o2", NoteVisibility.Shared, "someone-else", 3 * DAY,
            "Your October payment came in on the 7th, thanks."),
        note("o-n3", "office", NoteTarget.Member, "o3", NoteVisibility.Shared, "someone-else", 3 * DAY,
            "Zainab paid November early."),
        note("o-n4", "office", NoteTarget.Kameti, null, NoteVisibility.Private, "someone-else", 1 * DAY,
            "Remind Usman about the shortfall."),
    )

    private fun fail(code: String): Nothing = throw Failure.Server(code)
    private fun body(text: String) = buildJsonObject { put("body", text) }

    override suspend fun notes(kametiId: String): List<Note> {
        val kameti = kametis.kametiRow(kametiId) ?: fail("not_kameti_member")
        val all = synchronized(lock) { notes.filter { it.kametiId == kametiId } }
        val visible = if (kameti.ownerId == SampleData.USER_ID) all else all.filter(::canMemberRead)
        return visible.sortedByDescending { it.createdAt }
    }

    override suspend fun addNote(kametiId: String, new: NewNote): Note {
        val kameti = kametis.kametiRow(kametiId) ?: fail("not_found")
        if (kameti.ownerId != SampleData.USER_ID) fail("not_kameti_owner")
        val text = clean(new.body)
        if (new.targetType != NoteTarget.Kameti) {
            val id = new.targetId
            if (id == null || !exists(new.targetType, id, kametiId)) fail("target_not_found")
        }
        return synchronized(lock) {
            counter += 1
            val created = Note(
                id = "n-new-$counter", kametiId = kametiId, targetType = new.targetType,
                targetId = if (new.targetType == NoteTarget.Kameti) null else new.targetId, body = text,
                visibility = new.visibility, authorId = SampleData.USER_ID,
                authorName = SampleData.ownerNames[SampleData.USER_ID], createdAt = now.plusSeconds(counter.toLong()),
            )
            notes = notes + created
            log.record(kametiId, "note.add", entity = "note", entityId = created.id, member = null, after = body(text))
            created
        }
    }

    override suspend fun updateNote(id: String, body: String?, visibility: NoteVisibility?): Note {
        if (body == null && visibility == null) fail("nothing_to_change")
        val cleaned = body?.let(::clean)
        val old = ownedNote(id)
        val new = old.copy(
            body = cleaned ?: old.body, visibility = visibility ?: old.visibility,
            updatedAt = maxOf(old.createdAt.plusSeconds(1), now),
        )
        synchronized(lock) { notes = notes.map { if (it.id == id) new else it } }
        log.record(old.kametiId, "note.update", entity = "note", entityId = id, member = null, before = body(old.body), after = body(new.body))
        return new
    }

    override suspend fun deleteNote(id: String) {
        val old = ownedNote(id)
        synchronized(lock) { notes = notes.filterNot { it.id == id } }
        log.record(old.kametiId, "note.delete", entity = "note", entityId = id, member = null, before = body(old.body))
    }

    // Helpers

    private fun ownedNote(id: String): Note {
        val note = synchronized(lock) { notes.firstOrNull { it.id == id } } ?: fail("not_found")
        if (kametis.kametiRow(note.kametiId)?.ownerId != SampleData.USER_ID) fail("not_kameti_owner")
        return note
    }

    private fun clean(body: String): String {
        val text = body.trim()
        if (text.length !in 1..2000) fail("invalid_note_body")
        return text
    }

    private fun exists(target: NoteTarget, id: String, kametiId: String): Boolean = when (target) {
        NoteTarget.Kameti -> true
        NoteTarget.Member -> kametis.memberRow(id)?.kametiId == kametiId
        NoteTarget.Slot -> kametis.slotRow(id)?.kametiId == kametiId
        NoteTarget.Payment -> payments.all(kametiId).any { it.id == id }
        NoteTarget.Payout -> payments.payouts(kametiId).any { it.id == id }
    }

    /** FR-71 for a member of someone else's kameti. */
    private fun canMemberRead(note: Note): Boolean {
        if (note.visibility != NoteVisibility.Shared) return false
        val me = kametis.myMember(note.kametiId)
        if (me == null || me.joinStatus != JoinStatus.Joined) return false
        return when (note.targetType) {
            NoteTarget.Kameti -> true
            NoteTarget.Member -> note.targetId == me.id
            NoteTarget.Slot -> kametis.shareRows(me.id, note.kametiId).any { it.first.slotId == note.targetId }
            NoteTarget.Payment -> payments.all(note.kametiId).any { it.id == note.targetId && it.memberId == me.id }
            NoteTarget.Payout -> payments.payouts(note.kametiId).any { it.id == note.targetId && it.memberId == me.id }
        }
    }
}
