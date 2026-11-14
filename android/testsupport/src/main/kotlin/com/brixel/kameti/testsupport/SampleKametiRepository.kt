package com.brixel.kameti.testsupport

import com.brixel.kameti.core.Day
import com.brixel.kameti.core.ReminderTime
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.domain.KametiRepository
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberChanges
import com.brixel.kameti.domain.NewKameti
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.ShareInput
import com.brixel.kameti.domain.Slot
import java.time.Instant

/**
 * An in-memory kameti store seeded with the sample kametis. It supports the
 * whole create flow (draft, members, slot splits, order, start), so the
 * wizard can be tried without a backend. Nothing is saved to disk.
 */
class SampleKametiRepository(
    private val payments: SamplePaymentStore,
    private val contacts: SampleContactStore,
    private val log: SampleAuditLog = SampleAuditLog(),
) : KametiRepository {
    private val lock = Any()
    private var kametis = listOf(
        SampleData.neighbours, SampleData.family, SampleData.friends, SampleData.office, SampleData.cousins, SampleData.past,
    )
    private val members = mutableMapOf(
        "family" to SampleData.familyMembers, "friends" to SampleData.friendsMembers, "office" to SampleData.officeMembers,
        "cousins" to SampleData.cousinsMembers, "neighbours" to SampleData.neighboursMembers, "past-2025" to SampleData.pastMembers,
    )
    private val slots = mutableMapOf(
        "family" to SampleData.familySlots, "friends" to SampleData.friendsSlots, "office" to SampleData.officeSlots,
        "cousins" to SampleData.cousinsSlots, "neighbours" to SampleData.neighboursSlots, "past-2025" to SampleData.pastSlots,
    )
    private val shares = mutableMapOf(
        "family" to SampleData.familyShares, "friends" to SampleData.friendsShares, "office" to SampleData.officeShares,
        "cousins" to SampleData.cousinsShares, "neighbours" to SampleData.neighboursShares, "past-2025" to SampleData.pastShares,
    )
    private var counter = 0

    /** What each archived kameti was before, for restore. */
    private val archivedFrom = mutableMapOf<String, KametiStatus>()

    private val open = setOf(KametiStatus.Draft, KametiStatus.Active)

    private fun fail(code: String): Nothing = throw Failure.Server(code)

    /** Like RLS: kametis I run, or where a member is linked to my account. */
    override suspend fun listKametis(): List<Kameti> = synchronized(lock) {
        kametis.filter { k ->
            k.ownerId == SampleData.USER_ID || members[k.id].orEmpty().any { it.profileId == SampleData.USER_ID }
        }
    }

    // For the invites, notes and audit stores

    fun kametiRow(id: String): Kameti? = synchronized(lock) { kametis.firstOrNull { it.id == id } }

    fun memberRow(id: String): Member? = synchronized(lock) { members.values.flatten().firstOrNull { it.id == id } }

    fun slotRow(id: String): Slot? = synchronized(lock) { slots.values.flatten().firstOrNull { it.id == id } }

    /** My own member row in a kameti, if I'm in it. */
    fun myMember(kametiId: String): Member? =
        synchronized(lock) { members[kametiId]?.firstOrNull { it.profileId == SampleData.USER_ID } }

    fun shareRows(memberId: String, kametiId: String): List<Pair<Share, Slot?>> = synchronized(lock) {
        shares[kametiId].orEmpty().filter { it.memberId == memberId }.map { share ->
            share to slots[kametiId]?.firstOrNull { it.id == share.slotId }
        }
    }

    /** Replaces a member's join status and linked account. */
    fun setJoin(memberId: String, status: JoinStatus, profileId: String?): Member? = synchronized(lock) {
        for ((key, rows) in members) {
            val old = rows.firstOrNull { it.id == memberId } ?: continue
            val new = old.copy(joinStatus = status, profileId = profileId)
            members[key] = rows.map { if (it.id == memberId) new else it }
            return new
        }
        null
    }

    override suspend fun kameti(id: String): Kameti = kametiRow(id) ?: throw notFound()
    override suspend fun members(kametiId: String): List<Member> = synchronized(lock) { members[kametiId].orEmpty() }
    override suspend fun slots(kametiId: String): List<Slot> =
        synchronized(lock) { slots[kametiId].orEmpty().sortedBy { it.payoutMonthIndex } }
    override suspend fun shares(kametiId: String): List<Share> = synchronized(lock) { shares[kametiId].orEmpty() }

    override suspend fun createKameti(new: NewKameti): Kameti = synchronized(lock) {
        counter += 1
        val id = "draft-$counter"
        val created = Kameti(
            id = id, ownerId = SampleData.USER_ID, name = new.name, description = new.description,
            startMonth = new.startMonth, monthsN = new.months, slotAmountC = new.slotAmount, dueDay = new.dueDay,
            reminderDays = new.reminderDays, maxSlotsPerMember = new.maxSlotsPerMember, status = KametiStatus.Draft,
            reminderHour = new.reminderHour,
        )
        kametis = listOf(created) + kametis
        members[id] = emptyList()
        shares[id] = emptyList()
        slots[id] = (1..new.months).map { Slot("$id-s$it", id, it) }
        created
    }

    private fun nameTaken(name: String, ownerId: String, exceptId: String?): Boolean = kametis.any {
        it.id != exceptId && it.ownerId == ownerId && it.name.lowercase() == name.lowercase() && it.status in open
    }

    override suspend fun updateKameti(id: String, changes: KametiChanges): Kameti = synchronized(lock) {
        val old = kametis.firstOrNull { it.id == id } ?: throw notFound()
        // Like update_kameti_draft: drafts and running kametis only, and
        // once started the money shape is fixed (FR-34).
        if (old.status !in open) fail("kameti_not_editable")
        val structural = (changes.startMonth != null && changes.startMonth != old.startMonth) ||
            (changes.months != null && changes.months != old.monthsN) ||
            (changes.slotAmount != null && changes.slotAmount != old.slotAmountC) ||
            (changes.maxSlotsPerMember != null && changes.maxSlotsPerMember != old.maxSlotsPerMember)
        if (structural && old.status != KametiStatus.Draft) fail("kameti_not_draft")
        changes.name?.let { name ->
            val trimmed = name.trim()
            if (trimmed.length !in 3..40) fail("invalid_name")
            if (nameTaken(trimmed, old.ownerId, id)) fail("kameti_name_taken")
        }
        changes.reminderHour?.let { if (it !in ReminderTime.HOURS) fail("invalid_reminder_hour") }
        val months = changes.months ?: old.monthsN
        val updated = old.copy(
            name = changes.name ?: old.name, description = changes.description ?: old.description,
            startMonth = changes.startMonth ?: old.startMonth, monthsN = months,
            slotAmountC = changes.slotAmount ?: old.slotAmountC, dueDay = changes.dueDay ?: old.dueDay,
            reminderDays = changes.reminderDays ?: old.reminderDays,
            maxSlotsPerMember = changes.maxSlotsPerMember ?: old.maxSlotsPerMember,
            reminderHour = changes.reminderHour ?: old.reminderHour,
        )
        replace(updated)
        log.record(
            id, "kameti.update", entity = "kameti", entityId = id, member = null,
            before = SampleAuditLog.kameti(old), after = SampleAuditLog.kameti(updated),
        )
        if (old.status == KametiStatus.Draft && months != slots[id].orEmpty().size) {
            slots[id] = (1..months).map { Slot("$id-s$it", id, it) }
            shares[id] = emptyList()
        }
        updated
    }

    private fun replace(updated: Kameti): Kameti {
        kametis = kametis.map { if (it.id == updated.id) updated else it }
        return updated
    }

    override suspend fun startKameti(id: String): Kameti = synchronized(lock) {
        val old = kametis.firstOrNull { it.id == id } ?: throw notFound()
        val slotRows = slots[id].orEmpty()
        val shareRows = shares[id].orEmpty()
        val filled = slotRows.all { slot -> shareRows.any { it.slotId == slot.id } }
        if (!filled || slotRows.isEmpty()) fail("kameti_not_ready")
        replace(old.copy(status = KametiStatus.Active, startedAt = Instant.now()))
    }

    private fun owned(id: String): Kameti {
        val old = kametis.firstOrNull { it.id == id } ?: throw notFound()
        if (old.ownerId != SampleData.USER_ID) fail("not_kameti_owner")
        return old
    }

    /** Mirrors `archive_kameti`: owner only, anything but an archived kameti. */
    override suspend fun archiveKameti(id: String): Kameti = synchronized(lock) {
        val old = owned(id)
        if (old.status == KametiStatus.Archived) fail("kameti_already_archived")
        archivedFrom[id] = old.status
        replace(old.copy(status = KametiStatus.Archived))
    }

    /**
     * Mirrors `reopen_kameti` (sample data has no payment check): a running
     * kameti whose first month hasn't come goes back to a draft.
     */
    override suspend fun reopenKameti(id: String): Kameti = synchronized(lock) {
        val old = owned(id)
        if (old.status != KametiStatus.Active) fail("kameti_not_active")
        replace(old.copy(status = KametiStatus.Draft))
    }

    /** Mirrors `restore_kameti`: back to what it was, if the name is still free. */
    override suspend fun restoreKameti(id: String): Kameti = synchronized(lock) {
        val old = owned(id)
        if (old.status != KametiStatus.Archived) fail("kameti_not_archived")
        val to = archivedFrom[id] ?: KametiStatus.Completed
        if (to in open && nameTaken(old.name, old.ownerId, id)) fail("kameti_name_taken")
        archivedFrom.remove(id)
        replace(old.copy(status = to))
    }

    /**
     * Mirrors `duplicate_kameti` (FR-13): settings, members, current shares and
     * payout order; only my own member row stays linked; no payments.
     */
    override suspend fun duplicateKameti(id: String, name: String, startMonth: Day): Kameti = synchronized(lock) {
        val old = owned(id)
        val trimmed = name.trim()
        if (trimmed.length !in 3..40) fail("invalid_name")
        if (nameTaken(trimmed, old.ownerId, null)) fail("kameti_name_taken")
        counter += 1
        val newId = "draft-$counter"
        val copy = old.copy(id = newId, name = trimmed, startMonth = startMonth, status = KametiStatus.Draft, startedAt = null)
        val memberIds = mutableMapOf<String, String>()
        members[newId] = members[id].orEmpty().mapIndexed { index, m ->
            val mine = m.profileId == SampleData.USER_ID
            memberIds[m.id] = "$newId-m${index + 1}"
            Member(
                id = "$newId-m${index + 1}", kametiId = newId, name = m.name,
                joinStatus = if (mine) JoinStatus.Joined else JoinStatus.NotInvited,
                contactId = m.contactId, profileId = if (mine) m.profileId else null, nickname = m.nickname, color = m.color,
            )
        }
        val slotIds = mutableMapOf<String, String>()
        slots[newId] = slots[id].orEmpty().map { slot ->
            slotIds[slot.id] = "$newId-s${slot.payoutMonthIndex}"
            Slot("$newId-s${slot.payoutMonthIndex}", newId, slot.payoutMonthIndex, slot.note)
        }
        shares[newId] = shares[id].orEmpty().filter { it.effectiveToMonth == null }.mapIndexedNotNull { index, share ->
            val slot = slotIds[share.slotId] ?: return@mapIndexedNotNull null
            val member = memberIds[share.memberId] ?: return@mapIndexedNotNull null
            Share("$newId-h${index + 1}", newId, slot, member, share.monthlyAmount, effectiveFromMonth = 1)
        }
        kametis = listOf(copy) + kametis
        copy
    }

    /**
     * Mirrors `add_member`: the kameti must be a draft or active, a name of
     * 1–80 characters, and the same person can't be added twice.
     */
    override suspend fun addMember(kametiId: String, new: NewMember): Member = synchronized(lock) {
        requireEditable(kametiId)
        val contact: Contact?
        val name: String
        if (new.isSelf) {
            contact = null
            name = "Demo Owner"
            if (members[kametiId].orEmpty().any { it.profileId == SampleData.USER_ID }) fail("already_member")
        } else if (new.contactId != null) {
            contact = contacts.contact(new.contactId) ?: fail("contact_not_found")
            name = trimmed(new.name) ?: contact.name
        } else {
            name = trimmed(new.name) ?: fail("invalid_name")
            contact = contacts.findOrCreate(name, trimmed(new.email)?.lowercase(), trimmed(new.phone))
        }
        if (name.length > 80) fail("invalid_name")
        if (contact != null && members[kametiId].orEmpty().any { it.contactId == contact.id }) fail("contact_already_member")
        counter += 1
        val member = Member(
            id = "m-$counter", kametiId = kametiId, name = name,
            joinStatus = if (new.isSelf) JoinStatus.Joined else JoinStatus.NotInvited,
            contactId = contact?.id, profileId = if (new.isSelf) SampleData.USER_ID else null,
            nickname = trimmed(new.nickname),
        )
        members[kametiId] = members[kametiId].orEmpty() + member
        log.record(kametiId, "member.add", entity = "member", entityId = member.id, member = member.id, after = SampleAuditLog.member(member))
        member
    }

    /**
     * Mirrors `update_member`: `null` keeps a field, an empty string clears
     * it; an email or phone goes on the member's contact (made if missing).
     */
    override suspend fun updateMember(id: String, changes: MemberChanges): Member = synchronized(lock) {
        val old = memberRow(id) ?: throw notFound()
        val kameti = kametis.firstOrNull { it.id == old.kametiId }
        if (kameti == null || kameti.status !in open + KametiStatus.Completed) fail("kameti_not_editable")
        changes.name?.let { if (it.trim().length !in 1..80) fail("invalid_name") }
        val name = changes.name?.trim() ?: old.name
        var contactId = old.contactId
        if (changes.email != null || changes.phone != null) {
            contactId = contacts.update(old.contactId, name, changes.email?.trim()?.lowercase(), changes.phone?.trim()).id
        }
        val nickname = if (changes.nickname != null) trimmed(changes.nickname) else old.nickname
        val updated = old.copy(name = name, contactId = contactId, nickname = nickname)
        members[old.kametiId] = members[old.kametiId].orEmpty().map { if (it.id == id) updated else it }
        log.record(
            old.kametiId, "member.update", entity = "member", entityId = id, member = id,
            before = SampleAuditLog.member(old), after = SampleAuditLog.member(updated),
        )
        updated
    }

    /**
     * Mirrors `remove_member`: once a kameti has started, someone who holds a
     * share or has any payment or payout (voided ones too) stays on the ledger.
     */
    override suspend fun removeMember(id: String): Unit = synchronized(lock) {
        val old = memberRow(id) ?: throw notFound()
        val kameti = requireEditable(old.kametiId)
        val holdsShares = shares[old.kametiId].orEmpty().any { it.memberId == id }
        val hasMoney = payments.all(old.kametiId).any { it.memberId == id } || payments.payouts(old.kametiId).any { it.memberId == id }
        if (kameti.status != KametiStatus.Draft && (holdsShares || hasMoney)) fail("member_has_history")
        members[old.kametiId] = members[old.kametiId].orEmpty().filterNot { it.id == id }
        shares[old.kametiId] = shares[old.kametiId].orEmpty().filterNot { it.memberId == id }
        log.record(old.kametiId, "member.remove", entity = "member", entityId = id, member = id, before = SampleAuditLog.member(old))
    }

    private fun requireEditable(kametiId: String): Kameti {
        val kameti = kametis.firstOrNull { it.id == kametiId } ?: throw notFound()
        if (kameti.status !in open) fail("kameti_not_editable")
        return kameti
    }

    private fun trimmed(text: String?): String? = text?.trim()?.ifEmpty { null }

    override suspend fun setSlotShares(slotId: String, shares: List<ShareInput>): List<Share> = synchronized(lock) {
        val kametiId = slots.entries.firstOrNull { entry -> entry.value.any { it.id == slotId } }?.key ?: throw notFound()
        val kameti = kametis.firstOrNull { it.id == kametiId } ?: throw notFound()
        val total = shares.fold(Money.ZERO) { sum, share -> sum + share.monthlyAmount }
        val valid = shares.isEmpty() || (
            total == kameti.slotAmountC && shares.size <= 4 &&
                shares.all { it.monthlyAmount.rupees % 1_000 == 0L && it.monthlyAmount.rupees >= 1_000 }
            )
        if (!valid) fail("invalid_shares")
        val created = shares.mapIndexed { index, input ->
            Share("$slotId-h$index", kametiId, slotId, input.memberId, input.monthlyAmount, effectiveFromMonth = 1)
        }
        this.shares[kametiId] = this.shares[kametiId].orEmpty().filterNot { it.slotId == slotId } + created
        created
    }

    /**
     * Mirrors `transfer_share` (FR-33): A's share ends the month before,
     * B gets the same amount in the same slot from `fromMonth`.
     */
    override suspend fun transferShare(shareId: String, toMemberId: String, fromMonth: Int, note: String?): Share =
        synchronized(lock) {
            val kametiId = shares.entries.firstOrNull { entry -> entry.value.any { it.id == shareId } }?.key ?: throw notFound()
            val kameti = kametis.firstOrNull { it.id == kametiId } ?: throw notFound()
            val rows = shares[kametiId].orEmpty()
            val old = rows.first { it.id == shareId }
            if (kameti.status != KametiStatus.Active) fail("kameti_not_active")
            if (old.effectiveToMonth != null) fail("share_not_active")
            if (members[kametiId].orEmpty().none { it.id == toMemberId }) fail("member_not_in_kameti")
            if (toMemberId == old.memberId) fail("same_member")
            if (fromMonth !in old.effectiveFromMonth..kameti.monthsN) fail("invalid_transfer_month")
            if (rows.any { it.slotId == old.slotId && it.memberId == toMemberId && (it.effectiveToMonth ?: Int.MAX_VALUE) >= fromMonth }) {
                fail("already_in_slot")
            }
            val held = rows.filter { it.memberId == toMemberId && it.effectiveToMonth == null }.map { it.slotId }.toSet()
            if (held.size + 1 > kameti.maxSlotsPerMember) fail("member_slot_limit_exceeded")
            if (fromMonth == old.effectiveFromMonth) {
                val moved = old.copy(memberId = toMemberId, effectiveFromMonth = fromMonth, effectiveToMonth = null)
                shares[kametiId] = rows.map { if (it.id == shareId) moved else it }
                moved
            } else {
                counter += 1
                val moved = Share("${old.id}-t$counter", kametiId, old.slotId, toMemberId, old.monthlyAmount, effectiveFromMonth = fromMonth)
                shares[kametiId] = rows.map { if (it.id == shareId) old.copy(effectiveToMonth = fromMonth - 1) else it } + moved
                moved
            }
        }

    override suspend fun reorderSlots(kametiId: String, slotIdsInOrder: List<String>): List<Slot> = synchronized(lock) {
        val reordered = slotIdsInOrder.mapIndexed { index, id -> Slot(id, kametiId, index + 1) }
        slots[kametiId] = reordered
        reordered
    }
}
