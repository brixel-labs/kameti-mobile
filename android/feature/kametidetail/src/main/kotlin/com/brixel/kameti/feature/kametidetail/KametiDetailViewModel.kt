package com.brixel.kameti.feature.kametidetail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.RecordAction
import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.attempt
import com.brixel.kameti.domain.BatchPaymentItem
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.Invite
import com.brixel.kameti.domain.InviteLink
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MemberChanges
import com.brixel.kameti.domain.MemberViewLink
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.domain.NewNote
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.NewPayout
import com.brixel.kameti.domain.Note
import com.brixel.kameti.domain.NoteVisibility
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.Payout
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.ui.KConnectivity
import java.time.Instant
import java.time.LocalDate
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** Everything the detail screens show, loaded together. */
data class KametiDetailData(
    val kameti: Kameti,
    val userId: String,
    val members: List<Member>,
    val slots: List<Slot>,
    val shares: List<Share>,
    val collections: List<MonthCollectionRow>,
    val balances: List<MemberBalanceRow>,
    /** Every member's month statuses for the owner; a member gets only their own. */
    val months: List<MemberMonthRow>,
    val payments: List<Payment>,
    val payouts: List<Payout>,
    /**
     * The owner's saved people (for "From my people" and members' email and
     * phone). Owner only: empty for a member.
     */
    val contacts: List<Contact> = emptyList(),
    /** Every invite of this kameti, newest first. Owner only. */
    val invites: List<Invite> = emptyList(),
    /**
     * Notes I can read: all of them for the owner, shared ones I'm involved
     * in for a member (FR-71). Newest first.
     */
    val notes: List<Note> = emptyList(),
    /** Today in Pakistan, for "Today" labels. */
    val today: LocalDate,
) {
    val isOwner: Boolean get() = kameti.isOwnedBy(userId)
    val me: Member? get() = DetailLogic.myMember(members, userId)
    val current: MonthCollectionRow? get() = DetailLogic.currentCollection(collections)
}

class KametiDetailViewModel(
    val kametiId: String,
    private val userId: String,
    internal val dependencies: KametiDependencies,
    /**
     * What the caller already knows (from Home), so the title and subtitle
     * show the moment the screen opens, before the details load.
     */
    val preview: Kameti? = null,
    /** An action to start once the owner's tabs are on screen (from Home). */
    var pendingAction: RecordAction? = null,
    /** Open the owner's tabs on Members instead of Overview (right after a kameti starts). */
    val opensOnMembers: Boolean = false,
) : ViewModel() {
    sealed interface State {
        data object Loading : State
        data class Loaded(val data: KametiDetailData) : State
        data class Failed(val failure: Failure) : State
    }

    private val current = MutableStateFlow<State>(State.Loading)
    val state: StateFlow<State> = current.asStateFlow()

    /** When the details last loaded, for "Showing data from …" while offline. */
    var loadedAt: Instant? = null
        private set

    private var isRefreshing = false

    fun refresh() {
        viewModelScope.launch { load() }
    }

    suspend fun load() {
        if (isRefreshing) return
        isRefreshing = true
        try {
            val data = fetch()
            current.value = State.Loaded(data)
            loadedAt = Instant.now()
            KConnectivity.record(null)
        } catch (failure: Failure) {
            KConnectivity.record(failure)
            // Keep what is on screen if a refresh fails.
            if (current.value !is State.Loaded) current.value = State.Failed(failure)
        } finally {
            isRefreshing = false
        }
    }

    /** Two waves of calls run at once, instead of thirteen in a row. Throws the first [Failure]. */
    private suspend fun fetch(): KametiDetailData = coroutineScope {
        val deps = dependencies
        val id = kametiId
        val kametiCall = async { attempt { deps.kametis.kameti(id) } }
        val membersCall = async { attempt { deps.kametis.members(id) } }
        val slotsCall = async { attempt { deps.kametis.slots(id) } }
        val sharesCall = async { attempt { deps.kametis.shares(id) } }
        val collectionsCall = async { attempt { deps.ledger.monthCollections(id) } }
        val balancesCall = async { attempt { deps.ledger.memberBalances(id) } }
        val paymentsCall = async { attempt { deps.payments.payments(id) } }
        val payoutsCall = async { attempt { deps.payments.payouts(id) } }
        // Notes are extra: if they fail to load, the rest still shows.
        val notesCall = async { attempt { deps.notes.notes(id) } }
        val kameti = kametiCall.await().get()
        val members = membersCall.await().get()
        val owner = kameti.isOwnedBy(userId)
        // Owners see every member's months; a member only their own.
        val mine = DetailLogic.myMember(members, userId)
        val monthsCall = async {
            attempt {
                when {
                    owner -> deps.ledger.memberMonths(id, memberId = null)
                    mine != null -> deps.ledger.memberMonths(id, memberId = mine.id)
                    else -> emptyList()
                }
            }
        }
        val contactsCall = async { attempt { if (owner) deps.contacts.contacts() else emptyList() } }
        val invitesCall = async { attempt { if (owner) deps.invites.invites(id) else emptyList() } }
        val linksCall = async { attempt { if (owner) deps.invites.viewLinks(id) else emptyList() } }
        // Links the owner already made: kept for guests, never created here.
        linksCall.await().getOrNull()?.let { list -> viewLinkState.value = list.associateBy { it.memberId } }
        KametiDetailData(
            kameti = kameti,
            userId = userId,
            members = members,
            slots = slotsCall.await().get(),
            shares = sharesCall.await().get(),
            collections = collectionsCall.await().get(),
            balances = balancesCall.await().get(),
            months = monthsCall.await().get(),
            payments = paymentsCall.await().get(),
            payouts = payoutsCall.await().getOrNull().orEmpty(),
            contacts = contactsCall.await().getOrNull().orEmpty(),
            invites = invitesCall.await().getOrNull().orEmpty(),
            notes = notesCall.await().getOrNull().orEmpty(),
            today = deps.clock.today(),
        )
    }

    // Recording

    /** Runs one write, then reloads. Returns the failure to show, or `null`. */
    private suspend fun write(body: suspend () -> Unit): Failure? {
        try {
            body()
        } catch (failure: Failure) {
            return failure
        }
        load()
        return null
    }

    /**
     * Records a payment the owner received, then reloads. [idempotencyKey] is
     * made once per sheet so a retry never records it twice.
     */
    suspend fun recordPayment(
        memberId: String,
        amount: Money,
        receivedOn: LocalDate,
        method: PaymentMethod,
        reference: String?,
        note: String?,
        idempotencyKey: String,
    ): Failure? = write {
        dependencies.payments.recordPayment(
            NewPayment(memberId, amount, receivedOn, idempotencyKey, method, reference, note),
        )
    }

    /** Records several payments in one go (tap-to-settle), then reloads. */
    suspend fun recordPayments(items: List<BatchPaymentItem>, receivedOn: LocalDate, method: PaymentMethod): Failure? =
        write { dependencies.payments.recordPayments(kametiId, receivedOn, items, method) }

    /** One recipient's payout, and any dues taken from it. */
    data class PayoutEntry(val slotId: String, val memberId: String, val amount: Money, val deduction: Money?)

    /**
     * Records the payouts for a month, plus a payment for each deduction
     * (dues taken from a payout), then reloads. Keys are made once per sheet so
     * a retry never records anything twice. Stops at the first failure.
     */
    suspend fun recordPayouts(
        entries: List<PayoutEntry>,
        paidOn: LocalDate,
        method: PaymentMethod,
        reference: String?,
        note: String?,
        deductionNote: String,
        payoutKeys: Map<String, String>,
        deductionKeys: Map<String, String>,
    ): Failure? {
        var failure: Failure? = null
        for (entry in entries) {
            try {
                if (entry.deduction != null && entry.deduction.isPositive) {
                    dependencies.payments.recordPayment(
                        NewPayment(
                            memberId = entry.memberId, amount = entry.deduction, receivedOn = paidOn,
                            idempotencyKey = deductionKeys[entry.memberId] ?: idempotencyKey(),
                            method = PaymentMethod.Other, note = deductionNote,
                        ),
                    )
                }
                if (entry.amount.isPositive) {
                    dependencies.payments.recordPayout(
                        NewPayout(
                            slotId = entry.slotId, memberId = entry.memberId, amount = entry.amount, paidOn = paidOn,
                            idempotencyKey = payoutKeys[entry.memberId] ?: idempotencyKey(),
                            method = method, reference = reference, note = note,
                        ),
                    )
                }
            } catch (caught: Failure) {
                failure = caught
                break
            }
        }
        load()
        return failure
    }

    /** Voids a payment with a reason (payments are never edited or deleted). */
    suspend fun voidPayment(id: String, reason: String): Failure? = write { dependencies.payments.voidPayment(id, reason) }

    /** Voids a payout with a reason. */
    suspend fun voidPayout(id: String, reason: String): Failure? = write { dependencies.payments.voidPayout(id, reason) }

    // Members

    /** The member the last [addMember] made. */
    var lastAddedMemberId: String? = null
        private set

    /** Adds a member (a saved person, or a new one by name), then reloads. */
    suspend fun addMember(new: NewMember): Failure? = write { lastAddedMemberId = dependencies.kametis.addMember(kametiId, new).id }

    /** Saves a member's name, email or phone, then reloads. */
    suspend fun updateMember(id: String, changes: MemberChanges): Failure? =
        write { dependencies.kametis.updateMember(id, changes) }

    /**
     * Marks a member as not using the app (updates reach them by WhatsApp and nobody waits for them to
     * join), or back again, then reloads.
     */
    suspend fun setNoApp(memberId: String, value: Boolean): Failure? = updateMember(memberId, MemberChanges(noApp = value))

    private val receipts = MutableStateFlow<List<PendingReceipt>>(emptyList())

    /** Payments just recorded for members who aren't on the app, to offer receipts for. */
    internal val pendingReceipts: StateFlow<List<PendingReceipt>> = receipts.asStateFlow()

    internal fun clearReceipts() {
        receipts.value = emptyList()
    }

    /**
     * After a recording sheet closes: offers a receipt for each payment made for a member who isn't on
     * the app. Runs in the view model's scope, because the sheet that called it is already gone, and
     * waits a moment so that sheet has finished closing before this one opens.
     */
    internal fun offerReceipts(list: List<PendingReceipt>) {
        viewModelScope.launch { offerReceiptsNow(list) }
    }

    internal suspend fun offerReceiptsNow(list: List<PendingReceipt>) {
        val data = (current.value as? State.Loaded)?.data ?: return
        val guests = data.members.filter { it.noApp }.map { it.id }.toSet()
        val wanted = list.filter { it.memberId in guests }
        if (wanted.isEmpty()) return
        delay(500)
        receipts.value = wanted
    }

    /** Removes a member who holds no shares and has no payments, then reloads. */
    suspend fun removeMember(id: String): Failure? = write { dependencies.kametis.removeMember(id) }

    // Invites

    /**
     * A freshly made invite. The token and code can only be read when the
     * invite is created or resent, so they're kept for this screen's life.
     */
    data class SentInvite(
        val link: InviteLink,
        /** `false` when email isn't set up: the owner shares the code or link. */
        val emailed: Boolean,
    )

    private val sent = MutableStateFlow<Map<String, SentInvite>>(emptyMap())

    /** Invites made on this screen, by member id. */
    val sentInvites: StateFlow<Map<String, SentInvite>> = sent.asStateFlow()

    private val viewLinkState = MutableStateFlow<Map<String, MemberViewLink>>(emptyMap())

    /** Guests' private view-only links the owner has opened on this screen, by member id. */
    val viewLinks: StateFlow<Map<String, MemberViewLink>> = viewLinkState.asStateFlow()

    /** The member's view-only link, created on first use. */
    suspend fun openViewLink(memberId: String): Failure? {
        try {
            val link = dependencies.invites.viewLink(memberId)
            viewLinkState.update { it + (memberId to link) }
        } catch (failure: Failure) {
            return failure
        }
        return null
    }

    /** The member's view-only link for a quick send: the one that exists, or a new one; `null` when it can't be made. */
    suspend fun ensureViewLink(memberId: String): MemberViewLink? {
        viewLinkState.value[memberId]?.let { return it }
        openViewLink(memberId)
        return viewLinkState.value[memberId]
    }

    suspend fun turnOffViewLink(memberId: String): Failure? {
        try {
            dependencies.invites.turnOffViewLink(memberId)
            viewLinkState.update { it - memberId }
        } catch (failure: Failure) {
            return failure
        }
        return null
    }

    private val invitedNow = MutableStateFlow<Set<String>>(emptySet())

    /** Members invited by the Invite all that is running now, so its sheet can tick each row. */
    val invitedThisRun: StateFlow<Set<String>> = invitedNow.asStateFlow()

    /** "Now" from the app clock, for "expires in" (fixed in the demo). */
    val now: Instant get() = dependencies.clock.now()

    /** Makes the invite and emails it. The invite exists either way; a failed email only means sharing by hand. */
    private suspend fun send(memberId: String, resend: Boolean) {
        val link = if (resend) dependencies.invites.resendInvite(memberId) else dependencies.invites.createInvite(memberId)
        val emailed = attempt { dependencies.invites.sendInviteEmail(link) }.getOrNull() ?: false
        sent.update { it + (memberId to SentInvite(link, emailed)) }
    }

    /** Creates (or with [resend], replaces) a member's invite and emails it when email is set up. */
    suspend fun invite(memberId: String, resend: Boolean = false): Failure? = write { send(memberId, resend) }

    /** What an Invite all did: how many went out, and the first failure, if any. */
    data class InviteAllResult(val invited: Int, val failure: Failure?)

    /** Invites everyone given, one by one. */
    suspend fun inviteAll(memberIds: List<String>): InviteAllResult {
        var invited = 0
        var failure: Failure? = null
        invitedNow.value = emptySet()
        for (id in memberIds) {
            try {
                send(id, resend = false)
                invitedNow.update { it + id }
                invited += 1
            } catch (caught: Failure) {
                failure = failure ?: caught
            }
        }
        load()
        return InviteAllResult(invited, failure)
    }

    suspend fun revokeInvite(memberId: String): Failure? = write {
        dependencies.invites.revokeInvite(memberId)
        sent.update { it - memberId }
    }

    suspend fun approveJoin(memberId: String): Failure? = write { dependencies.invites.approveJoin(memberId) }

    suspend fun declineJoin(memberId: String): Failure? = write { dependencies.invites.declineJoin(memberId) }

    /** Takes a joined member's app access away; their record and payments stay. */
    suspend fun unlinkMember(memberId: String): Failure? = write {
        dependencies.invites.unlinkMember(memberId)
        sent.update { it - memberId }
    }

    /** Who takes over a share: someone in the kameti, or a new person added first. */
    sealed interface TransferTarget {
        data class Existing(val memberId: String) : TransferTarget
        data class NewPerson(val name: String) : TransferTarget
    }

    /** FR-33: moves a share to [target] from [fromMonth], adding the new person first if needed. */
    suspend fun transferShare(shareId: String, target: TransferTarget, fromMonth: Int, note: String?): Failure? {
        var failure: Failure? = null
        try {
            val memberId = when (target) {
                is TransferTarget.Existing -> target.memberId
                is TransferTarget.NewPerson -> dependencies.kametis.addMember(kametiId, NewMember(name = target.name)).id
            }
            dependencies.kametis.transferShare(shareId, memberId, fromMonth, note?.trim()?.ifEmpty { null })
        } catch (caught: Failure) {
            failure = caught
        }
        // Reload either way: a new person may have been added before it failed.
        load()
        return failure
    }

    // Kameti

    /** Saves the owner's edits to a running kameti (name, description, due day, reminders), then reloads. */
    suspend fun updateKameti(changes: KametiChanges): Failure? = write { dependencies.kametis.updateKameti(kametiId, changes) }

    // Archive (§6.11)

    suspend fun archive(): Failure? = write { dependencies.kametis.archiveKameti(kametiId) }

    /** "Edit setup": back to a draft (the backend re-checks every condition). */
    suspend fun reopen(): Failure? = write { dependencies.kametis.reopenKameti(kametiId) }

    suspend fun restore(): Failure? = write { dependencies.kametis.restoreKameti(kametiId) }

    // Duplicate (FR-13)

    /**
     * Copies this kameti as a new draft named "<name> (copy)", starting the
     * month after it ends (or this month, if that's later). The owner can
     * change both in the setup steps. Returns the new draft's id.
     * [suffix] gives " (copy)" for attempt 1 and " (copy 2)" and so on after.
     */
    suspend fun duplicate(suffix: (attempt: Int) -> String): Attempt<String> {
        val data = (current.value as? State.Loaded)?.data ?: return Attempt.Failed(Failure.Server("not_found"))
        val start = DuplicateLogic.startMonth(data.kameti, dependencies.clock.currentMonth())
        var last: Failure = Failure.Server("kameti_name_taken")
        for (attempt in 1..5) {
            val name = DuplicateLogic.name(data.kameti.name, suffix(attempt))
            try {
                return Attempt.Success(dependencies.kametis.duplicateKameti(kametiId, name, start).id)
            } catch (failure: Failure) {
                last = failure
                if ((failure as? Failure.Server)?.code != "kameti_name_taken") return Attempt.Failed(failure)
            }
        }
        return Attempt.Failed(last)
    }

    // Notes

    suspend fun addNote(new: NewNote): Failure? = write { dependencies.notes.addNote(kametiId, new) }

    suspend fun updateNote(id: String, body: String?, visibility: NoteVisibility?): Failure? =
        write { dependencies.notes.updateNote(id, body, visibility) }

    suspend fun deleteNote(id: String): Failure? = write { dependencies.notes.deleteNote(id) }

    /** A fresh key for one user action (a sheet makes its keys once, when it opens). */
    fun idempotencyKey(): String = dependencies.makeIdempotencyKey()
}
