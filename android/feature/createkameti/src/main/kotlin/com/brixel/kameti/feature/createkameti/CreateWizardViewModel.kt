package com.brixel.kameti.feature.createkameti

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.attempt
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.NewKameti
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.ShareInput
import com.brixel.kameti.domain.Slot
import java.time.LocalDate
import java.util.UUID
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** The six steps of the create wizard (FR-10). */
enum class WizardStep { Basics, Dates, Members, Slots, Order, Review }

/** Shortest and longest kameti in months, and the slots-per-person ceiling (REQUIREMENTS §3.2). */
object WizardLimits {
    const val MIN_MONTHS = 2
    const val MAX_MONTHS = 60
    const val MAX_SLOTS_PER_MEMBER = 6
    val nameLength = 3..40
    val dueDays = 1..28
}

/** Everything the wizard shows. */
data class WizardState(
    val step: WizardStep = WizardStep.Basics,
    /** The slot whose split editor is open. */
    val editingSlotId: String? = null,

    // Step 1 and 2 fields, kept so Back and Next keep what was typed.
    val name: String = "",
    val amountText: String = "",
    val months: Int = 12,
    val startMonth: LocalDate,
    val dueDay: Int = 10,
    val reminderDays: List<Int> = listOf(1, 5, 8, 10),
    val maxSlotsPerMember: Int = 4,

    val kametiId: String? = null,
    val members: List<Member> = emptyList(),
    val slots: List<Slot> = emptyList(),
    val shares: List<Share> = emptyList(),
    /** Emails typed for members added here (display only), by member id. */
    val emails: Map<String, String> = emptyMap(),

    /** The owner's saved people ("My people"), for picking into the kameti. */
    val contacts: List<Contact> = emptyList(),
    val contactsLoaded: Boolean = false,
    /** The owner's first name, for the reminder preview. */
    val ownerName: String? = null,

    val isBusy: Boolean = false,
    val failure: Failure? = null,
    /** True while a saved draft is being read back in. */
    val isLoadingDraft: Boolean = false,
    /** Set when the wizard reopened a saved draft (not a new kameti). */
    val isResumed: Boolean = false,

    /** Rows added here that the server hasn't confirmed yet. */
    val pendingMemberIds: Set<String> = emptySet(),
    /** Member saves still running; "Next" waits for them. */
    val memberSavesInFlight: Int = 0,
    /**
     * Saved id → the temporary id its row was first shown with, so the row
     * keeps one identity and doesn't animate out and back in when it saves.
     */
    val rowKeys: Map<String, String> = emptyMap(),
    /** The signed-in user, to find their own member row. */
    val userId: String = "",
) {
    val slotAmount: Money? get() = Money.parse(amountText)
    val nameValid: Boolean get() = name.trim().length in WizardLimits.nameLength
    val slotAmountValid: Boolean get() = slotAmount?.let { it.rupees >= 1_000 && it.rupees % 1_000 == 0L } ?: false
    val pot: Money get() = (slotAmount ?: Money.ZERO) * months
    val selfMember: Member? get() = members.firstOrNull { it.profileId == userId }
    val checks: PlanChecks
        get() = PlanChecks.evaluate(slotAmount ?: Money.ZERO, maxSlotsPerMember, members, slots, shares)

    /** Saved people not yet in this kameti. */
    val availableContacts: List<Contact>
        get() {
            val used = members.mapNotNull { it.contactId }.toSet()
            return contacts.filter { it.id !in used }
        }

    val isSavingMembers: Boolean get() = memberSavesInFlight > 0
    fun isPending(member: Member): Boolean = member.id in pendingMemberIds
    fun rowKey(member: Member): String = rowKeys[member.id] ?: member.id

    /** Adds one month (one slot) to a draft, for a person who isn't in any slot yet. */
    val canAddSlot: Boolean get() = months < WizardLimits.MAX_MONTHS
    val isAtStart: Boolean get() = step == WizardStep.Basics && editingSlotId == null
}

/**
 * Drives the create wizard (boards AC-1 to AC-6, FR-10 to FR-12).
 *
 * Step 1 creates the draft on the server; later saves update it. Members,
 * slots and shares live on the server once the draft exists, and are
 * re-read after each write. Every write sets `failure` on error.
 */
class CreateWizardViewModel(
    private val userId: String,
    private val dependencies: KametiDependencies,
) : ViewModel() {
    private val current = MutableStateFlow(WizardState(startMonth = dependencies.clock.currentMonth(), userId = userId))
    val state: StateFlow<WizardState> = current.asStateFlow()

    /** The owner's full name, for their own row before the server confirms it. */
    private var ownerFullName: String? = null

    /** This month in Pakistan, for the first-month options. */
    val currentMonth: LocalDate get() = dependencies.clock.currentMonth()

    /** Runs a model call from the screen. */
    fun launch(work: suspend CreateWizardViewModel.() -> Unit) {
        viewModelScope.launch { work() }
    }

    suspend fun loadOwner() {
        if (current.value.ownerName != null) return
        val profile = attempt { dependencies.profiles.myProfile(userId) }.getOrNull() ?: return
        ownerFullName = profile.displayName
        current.update { it.copy(ownerName = profile.displayName.split(" ").firstOrNull { word -> word.isNotEmpty() }) }
    }

    suspend fun loadContacts() {
        if (current.value.contactsLoaded) return
        val list = attempt { dependencies.contacts.contacts() }.getOrNull()
        current.update { it.copy(contacts = list ?: it.contacts, contactsLoaded = true) }
    }

    // Local edits

    fun setName(value: String) = current.update { it.copy(name = value) }

    fun setAmountText(value: String) = current.update { it.copy(amountText = value) }

    fun setStartMonth(value: LocalDate) = current.update { it.copy(startMonth = value) }

    fun setMonths(value: Int) =
        current.update { it.copy(months = value.coerceIn(WizardLimits.MIN_MONTHS, WizardLimits.MAX_MONTHS)) }

    /** Also drops reminder days after the new due day. */
    fun setDueDay(day: Int) =
        current.update { it.copy(dueDay = day, reminderDays = it.reminderDays.filter { reminder -> reminder <= day }) }

    fun toggleReminder(day: Int) = current.update {
        it.copy(reminderDays = if (day in it.reminderDays) it.reminderDays - day else (it.reminderDays + day).sorted())
    }

    fun setMaxSlots(value: Int) =
        current.update { it.copy(maxSlotsPerMember = value.coerceIn(1, WizardLimits.MAX_SLOTS_PER_MEMBER)) }

    fun clearFailure() = current.update { it.copy(failure = null) }

    fun editSlot(slotId: String?) = current.update { it.copy(editingSlotId = slotId) }

    fun goTo(target: WizardStep) = current.update { it.copy(step = target, editingSlotId = null) }

    /** Closes the split editor first, then steps back. */
    fun back() = current.update {
        when {
            it.editingSlotId != null -> it.copy(editingSlotId = null)
            it.step.ordinal > 0 -> it.copy(step = WizardStep.entries[it.step.ordinal - 1])
            else -> it
        }
    }

    /**
     * Reopens a saved draft: fills every step from the server and continues
     * at the first unfinished one (FR-10, drafts are kept on the server).
     */
    suspend fun resume(draftId: String) {
        current.update { it.copy(isLoadingDraft = true) }
        try {
            val kameti = dependencies.kametis.kameti(draftId)
            current.update {
                it.copy(
                    kametiId = kameti.id, name = kameti.name, amountText = kameti.slotAmountC.rupees.toString(),
                    months = kameti.monthsN, startMonth = kameti.startMonth, dueDay = kameti.dueDay,
                    reminderDays = kameti.reminderDays, maxSlotsPerMember = kameti.maxSlotsPerMember,
                )
            }
            reload()
            loadContacts()
            current.update { state ->
                val emails = state.members.mapNotNull { member ->
                    val email = state.contacts.firstOrNull { it.id == member.contactId }?.email
                    if (email != null) member.id to email else null
                }
                state.copy(
                    emails = state.emails + emails, isResumed = true,
                    step = resumeStep(state.members, state.slots, state.shares),
                )
            }
        } catch (failure: Failure) {
            current.update { it.copy(failure = failure) }
        } finally {
            current.update { it.copy(isLoadingDraft = false) }
        }
    }

    // Server writes

    /** Step 1: creates the draft, or updates it when it already exists. */
    suspend fun saveBasics() {
        val state = current.value
        val amount = state.slotAmount
        if (!state.nameValid || !state.slotAmountValid || amount == null) return
        val trimmed = state.name.trim()
        write {
            val id = state.kametiId
            if (id != null) {
                dependencies.kametis.updateKameti(
                    id, KametiChanges(name = trimmed, startMonth = state.startMonth, months = state.months, slotAmount = amount),
                )
            } else {
                val created = dependencies.kametis.createKameti(
                    NewKameti(
                        name = trimmed, startMonth = state.startMonth, months = state.months, slotAmount = amount,
                        dueDay = state.dueDay, reminderDays = state.reminderDays, maxSlotsPerMember = state.maxSlotsPerMember,
                    ),
                )
                current.update { it.copy(kametiId = created.id) }
            }
            reload()
            current.update { it.copy(step = WizardStep.Dates) }
        }
    }

    /** Step 2: due day, reminder days and the slot limit. */
    suspend fun saveDates() {
        val state = current.value
        val id = state.kametiId ?: return
        write {
            dependencies.kametis.updateKameti(
                id, KametiChanges(dueDay = state.dueDay, reminderDays = state.reminderDays, maxSlotsPerMember = state.maxSlotsPerMember),
            )
            current.update { it.copy(step = WizardStep.Members) }
        }
    }

    // Member changes are optimistic: the row appears or disappears at once and
    // the server call runs behind it, so the step never freezes. A row the
    // server hasn't confirmed yet has a temporary id; a failure undoes the
    // change and shows the error.

    suspend fun addMember(name: String, email: String?, phone: String? = null) {
        val cleanName = name.trim()
        val cleanEmail = email?.trim()?.ifEmpty { null }
        val cleanPhone = phone?.trim()?.ifEmpty { null }
        addOptimistic(cleanName, cleanEmail, new = NewMember(name = cleanName, email = cleanEmail, phone = cleanPhone))
    }

    /** Adds a saved person from "My people". */
    suspend fun addMember(contact: Contact) {
        addOptimistic(contact.name, contact.email, contactId = contact.id, new = NewMember(contactId = contact.id))
    }

    /** Adds several saved people at once ("Select all"). */
    suspend fun addMembers(contacts: List<Contact>) {
        // Show every row at once, in order, then save them together.
        val staged = contacts.mapNotNull { contact ->
            stageAdd(contact.name, contact.email, contactId = contact.id)?.let { it to NewMember(contactId = contact.id) }
        }
        coroutineScope {
            for ((tempId, new) in staged) launch { commitAdd(tempId, new) }
        }
    }

    /** "I'm also a member": adds or removes the owner's own member row. */
    suspend fun setSelfMember(included: Boolean) {
        val state = current.value
        val me = state.selfMember
        if (included && me == null) {
            addOptimistic(ownerFullName ?: state.ownerName ?: "", email = null, profileId = userId, new = NewMember(isSelf = true))
        } else if (!included && me != null && !state.isPending(me)) {
            removeMember(me.id)
        }
    }

    suspend fun removeMember(memberId: String) {
        val before = current.value
        val index = before.members.indexOfFirst { it.id == memberId }
        if (memberId in before.pendingMemberIds || index < 0) return
        val removed = before.members[index]
        val removedShares = before.shares.filter { it.memberId == memberId }
        val email = before.emails[memberId]
        current.update {
            it.copy(
                members = it.members.filterNot { member -> member.id == memberId },
                shares = it.shares.filterNot { share -> share.memberId == memberId },
                emails = it.emails - memberId,
            )
        }
        saveMembers(
            body = { dependencies.kametis.removeMember(memberId) },
            undo = {
                current.update {
                    val members = it.members.toMutableList().apply { add(minOf(index, size), removed) }
                    it.copy(
                        members = members, shares = it.shares + removedShares,
                        emails = if (email != null) it.emails + (memberId to email) else it.emails,
                    )
                }
            },
        )
    }

    private suspend fun addOptimistic(
        name: String, email: String?, contactId: String? = null, profileId: String? = null, new: NewMember,
    ) {
        val tempId = stageAdd(name, email, contactId, profileId) ?: return
        commitAdd(tempId, new)
    }

    /** Shows a not-yet-saved row at once; returns its temporary id. */
    private fun stageAdd(name: String, email: String?, contactId: String? = null, profileId: String? = null): String? {
        val id = current.value.kametiId ?: return null
        val tempId = "pending-${UUID.randomUUID()}"
        current.update {
            it.copy(
                members = it.members + Member(tempId, id, name, JoinStatus.NotInvited, contactId = contactId, profileId = profileId),
                pendingMemberIds = it.pendingMemberIds + tempId,
                emails = if (email != null) it.emails + (tempId to email) else it.emails,
            )
        }
        return tempId
    }

    /** Saves a staged row and swaps in the server's member, or undoes it. */
    private suspend fun commitAdd(tempId: String, new: NewMember) {
        val id = current.value.kametiId ?: return
        saveMembers(
            body = {
                val saved = dependencies.kametis.addMember(id, new)
                current.update {
                    val email = it.emails[tempId]
                    it.copy(
                        rowKeys = it.rowKeys + (saved.id to tempId),
                        members = it.members.map { member -> if (member.id == tempId) saved else member },
                        pendingMemberIds = it.pendingMemberIds - tempId,
                        emails = (it.emails - tempId).let { emails -> if (email != null) emails + (saved.id to email) else emails },
                    )
                }
            },
            undo = {
                current.update {
                    it.copy(
                        members = it.members.filterNot { member -> member.id == tempId },
                        pendingMemberIds = it.pendingMemberIds - tempId, emails = it.emails - tempId,
                    )
                }
            },
        )
    }

    private suspend fun saveMembers(body: suspend () -> Unit, undo: () -> Unit) {
        current.update { it.copy(memberSavesInFlight = it.memberSavesInFlight + 1, failure = null) }
        try {
            body()
        } catch (failure: Failure) {
            undo()
            current.update { it.copy(failure = failure) }
        } finally {
            current.update { it.copy(memberSavesInFlight = it.memberSavesInFlight - 1) }
        }
    }

    /**
     * Adds one month (one slot) to a draft, for a person who isn't in any
     * slot yet. The slot amount stays the same; the pot grows by one slot.
     */
    suspend fun addSlot() {
        val state = current.value
        val id = state.kametiId ?: return
        if (!state.canAddSlot) return
        val next = state.months + 1
        write {
            dependencies.kametis.updateKameti(id, KametiChanges(months = next))
            current.update { it.copy(months = next) }
            reload()
        }
    }

    /** Saves one slot's split and closes the split editor. */
    suspend fun saveSlotShares(slotId: String, shares: List<ShareInput>) = write {
        dependencies.kametis.setSlotShares(slotId, shares)
        current.update { it.copy(editingSlotId = null) }
        reload()
    }

    /** Step 5: saves the payout order (only when it changed) and moves on. */
    suspend fun saveOrder(orderedSlotIds: List<String>) {
        val state = current.value
        val id = state.kametiId ?: return
        val original = state.slots.sortedBy { it.payoutMonthIndex }.map { it.id }
        if (original == orderedSlotIds) {
            goTo(WizardStep.Review)
            return
        }
        write {
            dependencies.kametis.reorderSlots(id, orderedSlotIds)
            reload()
            current.update { it.copy(step = WizardStep.Review) }
        }
    }

    /** Step 6: asks the server to start (it re-checks FR-12). Returns the id on success. */
    suspend fun start(): String? {
        val id = current.value.kametiId ?: return null
        var started: String? = null
        write { started = dependencies.kametis.startKameti(id).id }
        return started
    }

    private suspend fun reload() {
        val id = current.value.kametiId ?: return
        val members = dependencies.kametis.members(id)
        val slots = dependencies.kametis.slots(id)
        val shares = dependencies.kametis.shares(id)
        current.update { it.copy(members = members, slots = slots, shares = shares) }
    }

    private suspend fun write(body: suspend () -> Unit) {
        if (current.value.isBusy) return
        current.update { it.copy(isBusy = true, failure = null) }
        try {
            body()
        } catch (failure: Failure) {
            current.update { it.copy(failure = failure) }
        } finally {
            current.update { it.copy(isBusy = false) }
        }
    }

    companion object {
        /**
         * Where a reopened draft continues: members first, then filling every
         * slot, then the review (order is optional, so it isn't forced).
         */
        fun resumeStep(members: List<Member>, slots: List<Slot>, shares: List<Share>): WizardStep {
            if (members.isEmpty()) return WizardStep.Members
            val filled = shares.map { it.slotId }.toSet()
            if (slots.isEmpty() || slots.any { it.id !in filled }) return WizardStep.Slots
            return WizardStep.Review
        }
    }
}
