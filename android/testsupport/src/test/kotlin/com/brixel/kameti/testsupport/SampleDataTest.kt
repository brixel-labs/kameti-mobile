package com.brixel.kameti.testsupport

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.MonthCollectionState
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.NewKameti
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.ShareInput
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest

/** The demo backend behaves like the real one where the screens rely on it. */
class SampleDataTest {
    private val deps = SampleData.dependencies()

    @Test
    fun demoIsSignedInAndListsOnlyMyKametis() = runTest {
        assertEquals(SampleData.USER_ID, deps.auth.userIdChanges().first())
        // Cousins is someone else's and I'm only invited, so it isn't listed.
        assertEquals(
            listOf("neighbours", "family", "friends", "office", "past-2025"),
            deps.kametis.listKametis().map { it.id },
        )
        assertEquals(2, deps.clock.monthIndex(SampleData.family.startMonth, SampleData.family.monthsN))
    }

    @Test
    fun ledgerFollowsThePaymentsOldestDueFirst() = runTest {
        val balances = deps.ledger.memberBalances("family").associateBy { it.memberId }
        // Naveed paid an extra 1,25,000: credit, and an advance in the current month.
        assertEquals(Money(125_000), balances.getValue("f3").credit)
        assertEquals(Money(250_000), balances.getValue("f4").owes)
        val months = deps.ledger.memberMonths("family", null)
        assertEquals(MonthStatusCode.Advance, months.first { it.memberId == "f3" && it.monthIndex == 2 }.status)
        assertEquals(MonthStatusCode.Partial, months.first { it.memberId == "f5" && it.monthIndex == 2 }.status)

        val november = deps.ledger.monthCollections("family")[1]
        // Received is the cash in November; covered is what the allocation covers.
        assertEquals(Money(1_000_000), november.received)
        // Ali owes 3,75,000 a month (a whole slot plus half of month 2's), so his
        // 5,00,000 covers only 1,25,000 of November.
        assertEquals(Money(625_000), november.covered)
        assertEquals(MonthCollectionState.Collecting, november.state)
        assertEquals(2, november.paidCount)
    }

    @Test
    fun recordingAndVoidingAPaymentMovesTheBalance() = runTest {
        val paid = deps.payments.recordPayment(
            NewPayment("f4", Money(250_000), DateOnly.make(2026, 11, 10), deps.makeIdempotencyKey())
        )
        assertEquals(Money.ZERO, deps.ledger.memberBalances("family").first { it.memberId == "f4" }.owes)
        assertTrue(deps.payments.voidPayment(paid.id, "typo").isVoided)
        assertEquals(Money(250_000), deps.ledger.memberBalances("family").first { it.memberId == "f4" }.owes)
        assertEquals("payment.void", deps.audit.audit("family", 1).first().action)
        assertFailsWith<Failure.Server> { deps.payments.recordPayment(NewPayment("f4", Money.ZERO, DateOnly.make(2026, 11, 10), "k")) }
    }

    @Test
    fun createFlowFromDraftToStart() = runTest {
        val draft = deps.kametis.createKameti(NewKameti("Test kameti", DateOnly.make(2026, 12), 2, Money(100_000)))
        assertEquals(Failure.Server("kameti_not_ready"), assertFailsWith<Failure.Server> { deps.kametis.startKameti(draft.id) })
        val a = deps.kametis.addMember(draft.id, NewMember(name = "Person A"))
        val me = deps.kametis.addMember(draft.id, NewMember(isSelf = true))
        assertEquals(JoinStatus.Joined, me.joinStatus)
        val slots = deps.kametis.slots(draft.id)
        // A slot's shares must add up to exactly C.
        assertFailsWith<Failure.Server> { deps.kametis.setSlotShares(slots[0].id, listOf(ShareInput(a.id, Money(60_000)))) }
        deps.kametis.setSlotShares(slots[0].id, listOf(ShareInput(a.id, Money(60_000)), ShareInput(me.id, Money(40_000))))
        deps.kametis.setSlotShares(slots[1].id, listOf(ShareInput(me.id, Money(100_000))))
        assertEquals(KametiStatus.Active, deps.kametis.startKameti(draft.id).status)
    }

    @Test
    fun invitationToMeCanBeAcceptedByCode() = runTest {
        assertEquals(listOf("inv-cz3"), deps.invites.myInvitations().map { it.inviteId })
        val preview = deps.invites.previewInvite("czn7qk", null)
        assertEquals("Cousins kameti", preview.kametiName)
        assertTrue(preview.canJoin)
        assertEquals(JoinStatus.Joined, deps.invites.acceptInvite(null, "inv-cz3").joinStatus)
        assertTrue(deps.kametis.listKametis().any { it.id == "cousins" })
        assertTrue(deps.invites.myInvitations().isEmpty())
    }

    @Test
    fun membersSeeOnlySharedNotesAboutThem() = runTest {
        assertEquals(listOf("o-n2", "o-n1"), deps.notes.notes("office").map { it.id })
        assertEquals(4, deps.notes.notes("family").size)
    }

    @Test
    fun deletingTheAccountIsBlockedWhileRunningAKameti() = runTest {
        val check = deps.account.deletionCheck()
        assertEquals(listOf("family", "friends"), check.blockingKametis.map { it.id })
        assertFailsWith<Failure.Server> { deps.account.deleteAccount() }
        assertEquals(SampleData.USER_ID, deps.auth.currentUserId)
    }

    @Test
    fun fakeAuthReportsCallsAndFailures() = runTest {
        val auth = FakeAuthRepository()
        assertNull(auth.currentUserId)
        assertTrue(auth.signInWithGoogle())
        assertEquals("google-user", auth.currentUserId)
        auth.setSignOut(com.brixel.kameti.core.Attempt.Failed(Failure.Network))
        assertFailsWith<Failure.Network> { auth.signOut() }
        assertEquals(listOf("google", "signOut"), auth.calls)
    }
}
