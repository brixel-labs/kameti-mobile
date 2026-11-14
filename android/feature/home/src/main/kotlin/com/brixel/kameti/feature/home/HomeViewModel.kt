package com.brixel.kameti.feature.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.brixel.kameti.core.Attempt
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.attempt
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MonthCollectionState
import com.brixel.kameti.domain.MyInvitation
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.feature.kametidetail.DetailLogic
import com.brixel.kameti.ui.KConnectivity
import java.time.Instant
import java.time.LocalDate
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * One kameti on Home with the parts that load separately. A part that fails
 * to load stays `null`; the card still opens the kameti.
 */
data class HomeKametiSummary(
    val kameti: Kameti,
    val isOwner: Boolean,
    /** This month's collection (live kametis only). */
    val currentMonth: MonthCollectionRow? = null,
    /** What I owe so far (member view only). */
    val owes: Money? = null,
    /** What I pay a month (member view); zero means I hold no share yet. */
    val monthlyDue: Money? = null,
    /** When this month's payment is due. */
    val dueDate: LocalDate? = null,
    /** Who receives the pot this month. */
    val recipients: List<Person> = emptyList(),
    /** My next payout (member view). */
    val nextTurn: NextTurn? = null,
    /** When this month's payout was made (the latest payout of its slot). */
    val payoutDate: LocalDate? = null,
    /**
     * Everyone in it, in turn order from this month (people without a share
     * last), for the avatar row.
     */
    val people: List<Person> = emptyList(),
) {
    val id: String get() = kameti.id

    /** This month's pot has been paid out, in full or short. */
    val isPaidOut: Boolean
        get() = currentMonth?.state == MonthCollectionState.PaidOut ||
            currentMonth?.state == MonthCollectionState.PaidOutShort

    data class Person(
        val name: String,
        val colorIndex: Int,
        /** The signed-in user: screens show "You" instead of the name. */
        val isMe: Boolean = false,
        /** Their payout months (one per slot they're paid in), for the members sheet. */
        val turns: List<LocalDate> = emptyList(),
        /** What they're paid across those turns (share × N each). */
        val payout: Money = Money.ZERO,
        /** They receive this month's pot. */
        val isThisMonth: Boolean = false,
    )

    data class NextTurn(val month: LocalDate, val payout: Money)
}

/** Home's three groups (FR-1 to FR-3). */
data class HomeSections(
    val mine: List<HomeKametiSummary> = emptyList(),
    val joined: List<HomeKametiSummary> = emptyList(),
    val past: List<HomeKametiSummary> = emptyList(),
    /** Archived (§6.11): off the main list, behind the "Archived (n)" row. */
    val archived: List<HomeKametiSummary> = emptyList(),
) {
    val isEmpty: Boolean get() = mine.isEmpty() && joined.isEmpty() && past.isEmpty() && archived.isEmpty()
    val all: List<HomeKametiSummary> get() = mine + joined + past + archived
}

data class HomeUiState(
    val sections: HomeSections = HomeSections(),
    val failure: Failure? = null,
    val isLoading: Boolean = false,
    val hasLoaded: Boolean = false,
    /** The signed-in user's first name, for the title. */
    val firstName: String? = null,
    /** Live invitations addressed to my email (board AI-1b). */
    val invitations: List<MyInvitation> = emptyList(),
    /** When the kametis last loaded, for "Showing data from …" while offline. */
    val loadedAt: Instant? = null,
)

class HomeViewModel(
    private val userId: String,
    private val dependencies: KametiDependencies,
) : ViewModel() {
    private val current = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = current.asStateFlow()

    /** The app clock's "now" (fixed in the demo), for "expires in". */
    val now: Instant get() = dependencies.clock.now()

    /** The current month in Pakistan, for "starts later". */
    val currentMonth: LocalDate get() = dependencies.clock.currentMonth()

    /** A kameti Home already loaded, by id. */
    fun kameti(id: String): Kameti? = current.value.sections.all.firstOrNull { it.id == id }?.kameti

    fun refresh() {
        viewModelScope.launch { load() }
    }

    suspend fun load() {
        if (current.value.isLoading) return
        current.update { it.copy(isLoading = true, failure = null) }
        try {
            loadEverything()
        } finally {
            current.update { it.copy(isLoading = false, hasLoaded = true) }
        }
    }

    private suspend fun loadEverything() = coroutineScope {
        // The name comes from the profile saved on the phone; the server only
        // the first time (it's saved then for next time).
        if (current.value.firstName == null) {
            var profile = dependencies.profileCache.load(userId).profile
            if (profile == null) {
                profile = attempt { dependencies.profiles.myProfile(userId) }.getOrNull()
                profile?.let { fetched -> dependencies.profileCache.update(userId) { it.copy(profile = fetched) } }
            }
            val first = profile?.displayName?.split(" ")?.firstOrNull { it.isNotEmpty() }
            current.update { it.copy(firstName = first) }
        }
        // Invitations and the list load together. Invitations are extra: a
        // failure there never blocks Home.
        val invitationsCall = async { attempt { dependencies.invites.myInvitations() } }
        val listCall = async { attempt { dependencies.kametis.listKametis() } }
        val invitations = invitationsCall.await().getOrNull().orEmpty()
        current.update { it.copy(invitations = invitations) }
        when (val list = listCall.await()) {
            is Attempt.Failed -> {
                current.update { it.copy(failure = list.failure) }
                KConnectivity.record(list.failure)
            }
            is Attempt.Success -> {
                val all = list.value
                // Profile's counts and Past list read this, so they stay current.
                dependencies.profileCache.update(userId) { it.copy(kametis = all) }
                // Cards already on screen keep their details while they refresh,
                // so pull to refresh never flashes a card back to "Not started yet".
                val shown = current.value.sections.all.associateBy { it.id }
                val summaries = all.map { kameti ->
                    shown[kameti.id]?.copy(kameti = kameti)
                        ?: HomeKametiSummary(kameti, isOwner = kameti.isOwnedBy(userId))
                }
                // Show the list right away, then fill in each card.
                current.update { it.copy(sections = sections(summaries)) }
                // Every card fills in at the same time, not one after another.
                val filled = summaries.map { item ->
                    if (isPast(item.kameti.status)) null else async { detail(item) }
                }.mapIndexed { index, call -> call?.await() ?: summaries[index] }
                current.update { it.copy(sections = sections(filled), loadedAt = Instant.now()) }
                KConnectivity.record(null)
            }
        }
    }

    /** Declines an invitation from Home, then reloads. */
    /** Deletes one of my drafts for good, then reloads. */
    suspend fun deleteDraft(id: String): Failure? {
        val result = attempt { dependencies.kametis.deleteKametiDraft(id) }
        if (result is Attempt.Failed) return result.failure
        load()
        return null
    }

    suspend fun decline(invitation: MyInvitation): Failure? {
        val result = attempt { dependencies.invites.declineInvite(token = null, inviteId = invitation.inviteId) }
        if (result is Attempt.Failed) return result.failure
        load()
        return null
    }

    /**
     * Fills in a card. If a request fails (offline, or a refresh that was
     * cancelled), the card keeps what it already showed.
     */
    private suspend fun detail(original: HomeKametiSummary): HomeKametiSummary = coroutineScope {
        val kameti = original.kameti
        val id = kameti.id
        // All at once; a member's balance is only needed on cards they don't run.
        val needsBalance = !original.isOwner
        val collectionsCall = async { attempt { dependencies.ledger.monthCollections(id) } }
        val membersCall = async { attempt { dependencies.kametis.members(id) } }
        val slotsCall = async { attempt { dependencies.kametis.slots(id) } }
        val sharesCall = async { attempt { dependencies.kametis.shares(id) } }
        val balancesCall = async {
            attempt { if (needsBalance) dependencies.ledger.memberBalances(id) else emptyList<MemberBalanceRow>() }
        }
        val calls = awaitAll(collectionsCall, membersCall, slotsCall, sharesCall)
        if (calls.any { it is Attempt.Failed }) {
            balancesCall.cancel()
            return@coroutineScope original
        }
        val month = collectionsCall.await().get().firstOrNull { it.isCurrent }
        val members = membersCall.await().get()
        val slots = slotsCall.await().get()
        val shares = sharesCall.await().get()
        val balances = balancesCall.await().getOrNull()
        val me = DetailLogic.myMember(members, userId)

        fun person(member: Member) = HomeKametiSummary.Person(
            name = member.name,
            colorIndex = member.color?.toIntOrNull() ?: maxOf(members.indexOf(member), 0),
            isMe = member.id == me?.id,
        )

        var item = original.copy(
            currentMonth = month,
            people = turnOrder(members, slots, shares, from = month?.monthIndex ?: 1).map { entry ->
                person(entry.member).copy(
                    turns = entry.months.map { DetailLogic.monthStart(kameti, it) },
                    payout = entry.monthly * kameti.monthsN,
                    isThisMonth = month != null && month.monthIndex in entry.months,
                )
            },
        )
        if (month != null) {
            item = item.copy(
                dueDate = DetailLogic.dueDate(kameti, month.monthIndex),
                recipients = DetailLogic.recipients(kameti, month.monthIndex, slots, shares, members)
                    .map { person(it.member) },
            )
        }
        if (month != null && item.isPaidOut) {
            attempt { dependencies.payments.payouts(id) }.getOrNull()?.let { payouts ->
                val slotIds = slots.filter { it.payoutMonthIndex == month.monthIndex }.map { it.id }.toSet()
                item = item.copy(
                    payoutDate = payouts.filter { it.voidedAt == null && it.slotId in slotIds }.maxOfOrNull { it.paidOn },
                )
            }
        }
        if (!item.isOwner && me != null) {
            if (balances != null) {
                val mine = balances.firstOrNull { it.memberId == me.id }
                item = item.copy(owes = mine?.owes, monthlyDue = mine?.monthlyDue)
            }
            DetailLogic.nextTurn(me, kameti, month?.monthIndex ?: 1, slots, shares)?.let { turn ->
                item = item.copy(
                    nextTurn = HomeKametiSummary.NextTurn(DetailLogic.monthStart(kameti, turn.monthIndex), turn.payout),
                )
            }
        }
        item
    }

    data class TurnEntry(
        val member: Member,
        /** Payout months they hold, in turn order. */
        val months: List<Int>,
        /** Their share in each of those slots, summed (× N is the payout). */
        val monthly: Money,
    )

    companion object {
        /** Past kametis are completed, archived or cancelled. */
        fun isPast(status: KametiStatus): Boolean = when (status) {
            KametiStatus.Completed, KametiStatus.Archived, KametiStatus.Cancelled -> true
            KametiStatus.Draft, KametiStatus.Active -> false
        }

        /**
         * Groups kametis: mine (owner), joined (member), past. Order is kept.
         * Archived kametis go to their own list (§6.11: hidden from the main
         * list), opened from the "Archived (n)" row at the end of Past.
         */
        fun sections(summaries: List<HomeKametiSummary>): HomeSections {
            val mine = mutableListOf<HomeKametiSummary>()
            val joined = mutableListOf<HomeKametiSummary>()
            val past = mutableListOf<HomeKametiSummary>()
            val archived = mutableListOf<HomeKametiSummary>()
            for (item in summaries) {
                when {
                    item.kameti.status == KametiStatus.Archived -> archived += item
                    isPast(item.kameti.status) -> past += item
                    item.isOwner -> mine += item
                    else -> joined += item
                }
            }
            return HomeSections(mine, joined, past, archived)
        }

        /**
         * Each member once, in payout order starting at [from] (this month's
         * recipients first, then the next turns, wrapping round to earlier
         * ones); members holding no share come last, in list order. A person
         * with two slots is one entry with both turns.
         */
        fun turnOrder(members: List<Member>, slots: List<Slot>, shares: List<Share>, from: Int): List<TurnEntry> {
            val byId = members.associateBy { it.id }
            val total = maxOf(slots.maxOfOrNull { it.payoutMonthIndex } ?: 0, 1)
            val ordered = slots.sortedBy { Math.floorMod(it.payoutMonthIndex - from, total) }
            val position = mutableMapOf<String, Int>()
            val result = mutableListOf<TurnEntry>()
            for (slot in ordered) {
                // Whoever holds the slot in its payout month (after any transfer).
                val holders = shares.filter { it.slotId == slot.id && DetailLogic.isActive(it, slot.payoutMonthIndex) }
                for (share in holders) {
                    val member = byId[share.memberId] ?: continue
                    val at = position[member.id]
                    if (at != null) {
                        val entry = result[at]
                        result[at] = entry.copy(
                            months = if (entry.months.last() != slot.payoutMonthIndex) entry.months + slot.payoutMonthIndex else entry.months,
                            monthly = entry.monthly + share.monthlyAmount,
                        )
                    } else {
                        position[member.id] = result.size
                        result += TurnEntry(member, listOf(slot.payoutMonthIndex), share.monthlyAmount)
                    }
                }
            }
            result += members.filter { it.id !in position }.map { TurnEntry(it, emptyList(), Money.ZERO) }
            return result
        }
    }
}
