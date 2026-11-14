package com.brixel.kameti.feature.home

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.testsupport.FakeAuthRepository
import com.brixel.kameti.testsupport.FakeProfileRepository
import com.brixel.kameti.testsupport.SampleData
import com.brixel.kameti.testsupport.StubKametiRepository
import com.brixel.kameti.testsupport.UnusedRepositories
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

private fun kameti(id: String, owner: String, status: KametiStatus = KametiStatus.Active) = Kameti(
    id = id, ownerId = owner, name = id, startMonth = DateOnly.make(2026, 10), monthsN = 4,
    slotAmountC = Money(100_000), dueDay = 10, reminderDays = listOf(1), maxSlotsPerMember = 4, status = status,
)

private fun summary(id: String, owner: Boolean, status: KametiStatus = KametiStatus.Active) =
    HomeKametiSummary(kameti(id, if (owner) "me" else "other", status), isOwner = owner)

private fun dependencies(kametis: List<Kameti>): KametiDependencies {
    val unused = UnusedRepositories()
    return KametiDependencies(
        kametis = StubKametiRepository(kametis), ledger = unused, payments = unused, invites = unused,
        audit = unused, profiles = FakeProfileRepository(), contacts = unused, auth = FakeAuthRepository("me"),
    )
}

class HomeGroupingTest {
    @Test
    fun splitsMineJoinedAndPastKeepingOrder() {
        val result = HomeViewModel.sections(
            listOf(
                summary("a", owner = true), summary("b", owner = false), summary("c", owner = true),
                summary("old", owner = true, status = KametiStatus.Completed),
                summary("gone", owner = false, status = KametiStatus.Cancelled),
            ),
        )
        assertEquals(listOf("a", "c"), result.mine.map { it.id })
        assertEquals(listOf("b"), result.joined.map { it.id })
        assertEquals(listOf("old", "gone"), result.past.map { it.id })
    }

    @Test
    fun draftCountsAsLive() {
        val result = HomeViewModel.sections(listOf(summary("d", owner = true, status = KametiStatus.Draft)))
        assertEquals(1, result.mine.size)
        assertTrue(result.past.isEmpty())
    }

    @Test
    fun archivedIsPast() {
        assertTrue(HomeViewModel.isPast(KametiStatus.Archived))
        assertFalse(HomeViewModel.isPast(KametiStatus.Active))
    }

    @Test
    fun archivedGetsItsOwnList() {
        val result = HomeViewModel.sections(
            listOf(
                summary("a", owner = true), summary("arch", owner = true, status = KametiStatus.Archived),
                summary("theirs", owner = false, status = KametiStatus.Archived),
                summary("old", owner = true, status = KametiStatus.Completed),
            ),
        )
        assertEquals(listOf("a"), result.mine.map { it.id })
        assertTrue(result.joined.isEmpty())
        assertEquals(listOf("old"), result.past.map { it.id })
        assertEquals(listOf("arch", "theirs"), result.archived.map { it.id })
        assertFalse(HomeSections(archived = result.archived).isEmpty)
    }

    @Test
    fun emptyWhenNothing() {
        assertTrue(HomeViewModel.sections(emptyList()).isEmpty)
    }
}

class HomeTurnOrderTest {
    private fun member(id: String) = Member(id = id, kametiId = "k", name = id, joinStatus = JoinStatus.Joined)
    private fun share(slot: String, member: String, amount: Long, from: Int = 1, to: Int? = null) =
        Share("$slot-$member", "k", slot, member, Money(amount), effectiveFromMonth = from, effectiveToMonth = to)

    private val slots = listOf(Slot("s1", "k", 1), Slot("s2", "k", 2), Slot("s3", "k", 3), Slot("s4", "k", 4))

    @Test
    fun startsAtThisMonthAndWrapsRound() {
        val shares = listOf(
            share("s1", "a", 100_000), share("s2", "b", 100_000), share("s3", "c", 100_000), share("s4", "a", 100_000),
        )
        val order = HomeViewModel.turnOrder(listOf(member("a"), member("b"), member("c"), member("idle")), slots, shares, from = 3)
        // March's recipient first, then April, then round to months 1 and 2; no share last.
        assertEquals(listOf("c", "a", "b", "idle"), order.map { it.member.id })
        // A holds two slots: one entry with both turns, in order from this month.
        assertEquals(listOf(4, 1), order[1].months)
        assertEquals(Money(200_000), order[1].monthly)
        assertTrue(order.last().months.isEmpty())
    }

    @Test
    fun aSplitSlotListsEverySharerAndATransferredShareItsNewHolder() {
        val shares = listOf(
            share("s1", "a", 60_000), share("s1", "b", 40_000),
            // Slot 2 moved from a to c from month 2 on.
            share("s2", "a", 100_000, from = 1, to = 1), share("s2", "c", 100_000, from = 2),
        )
        val order = HomeViewModel.turnOrder(listOf(member("a"), member("b"), member("c")), slots, shares, from = 1)
        assertEquals(listOf("a", "b", "c"), order.map { it.member.id })
        assertEquals(listOf(1), order[0].months)
        assertEquals(Money(60_000), order[0].monthly)
        assertEquals(listOf(2), order[2].months)
    }
}

class HomeLoadingTest {
    @Test
    fun loadsAndGroupsEvenWhenCardDetailsFail() = runTest {
        // Ledger and members are "not stubbed": cards load without their detail.
        val model = HomeViewModel(
            "me",
            dependencies(listOf(kameti("a", "me"), kameti("b", "x"), kameti("z", "me", KametiStatus.Completed))),
        )
        model.load()
        val state = model.state.value
        assertTrue(state.hasLoaded)
        assertNull(state.failure)
        assertEquals(listOf("a"), state.sections.mine.map { it.id })
        assertEquals(listOf("b"), state.sections.joined.map { it.id })
        assertEquals(listOf("z"), state.sections.past.map { it.id })
        assertNull(state.sections.mine.first().currentMonth)
        assertEquals("Hassan", state.firstName)
        assertEquals("a", model.kameti("a")?.id)
    }

    @Test
    fun noKametisIsEmptyNotFailed() = runTest {
        val model = HomeViewModel("me", dependencies(emptyList()))
        model.load()
        assertTrue(model.state.value.sections.isEmpty)
        assertNull(model.state.value.failure)
    }

    /** The demo data end to end: every running card gets its month, people and turns. */
    @Test
    fun theSampleKametisFillTheirCards() = runTest {
        val model = HomeViewModel(SampleData.USER_ID, SampleData.dependencies())
        model.load()
        val state = model.state.value
        assertNull(state.failure)
        assertFalse(state.sections.isEmpty)
        val running = state.sections.mine.filter { it.kameti.status == KametiStatus.Active }
        assertTrue(running.isNotEmpty())
        for (card in running) {
            assertTrue(card.people.isNotEmpty(), card.kameti.name)
        }
        val collecting = assertNotNull(running.firstOrNull { it.currentMonth != null })
        assertNotNull(collecting.dueDate)
        assertTrue(collecting.recipients.isNotEmpty())
        assertTrue(collecting.people.first().isThisMonth)
    }
}
