package com.brixel.kameti.feature.kametidetail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.RecordAction
import com.brixel.kameti.core.attempt
import com.brixel.kameti.domain.BatchPaymentItem
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.Invite
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.NewPayout
import com.brixel.kameti.domain.Note
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
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
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

    /** A fresh key for one user action (a sheet makes its keys once, when it opens). */
    fun idempotencyKey(): String = dependencies.makeIdempotencyKey()
}
