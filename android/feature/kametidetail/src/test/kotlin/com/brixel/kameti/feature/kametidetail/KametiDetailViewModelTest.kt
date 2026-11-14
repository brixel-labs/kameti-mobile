package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.testsupport.FakeAuthRepository
import com.brixel.kameti.testsupport.FakeProfileRepository
import com.brixel.kameti.testsupport.SampleData
import com.brixel.kameti.testsupport.StubKametiRepository
import com.brixel.kameti.testsupport.StubLedgerRepository
import com.brixel.kameti.testsupport.StubPaymentsRepository
import com.brixel.kameti.testsupport.UnusedRepositories
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

private fun kameti(owner: String) = Kameti(
    id = "k", ownerId = owner, name = "K", startMonth = DateOnly.make(2026, 11), monthsN = 2,
    slotAmountC = Money(100_000), dueDay = 10, reminderDays = emptyList(), maxSlotsPerMember = 4,
    status = KametiStatus.Active,
)

private fun dependencies(owner: String, ledger: StubLedgerRepository): KametiDependencies {
    val unused = UnusedRepositories()
    return KametiDependencies(
        kametis = StubKametiRepository(
            listOf(kameti(owner)),
            members = listOf(Member(id = "m", kametiId = "k", name = "M", joinStatus = JoinStatus.Joined, profileId = "me")),
        ),
        ledger = ledger, payments = StubPaymentsRepository(), invites = unused, audit = unused,
        profiles = FakeProfileRepository(), contacts = unused, auth = FakeAuthRepository("me"),
    )
}

private fun row(member: String) = MemberMonthRow(
    kametiId = "k", memberId = member, monthIndex = 1, monthStart = DateOnly.make(2026, 11),
    isCurrent = true, due = Money(1), allocated = Money.ZERO, remaining = Money(1), status = MonthStatusCode.Unpaid,
)

class KametiDetailViewModelTest {
    @Test
    fun ownerLoadsEveryMembersMonths() = runTest {
        val model = KametiDetailViewModel("k", "me", dependencies("me", StubLedgerRepository(months = listOf(row("m")))))
        model.load()
        val data = assertIs<KametiDetailViewModel.State.Loaded>(model.state.value).data
        assertTrue(data.isOwner)
        assertEquals(1, data.months.size)
        assertEquals("m", data.me?.id)
    }

    @Test
    fun aMemberLoadsOnlyTheirOwnMonths() = runTest {
        val model = KametiDetailViewModel(
            "k", "me", dependencies("other", StubLedgerRepository(months = listOf(row("x"), row("m")))),
        )
        model.load()
        val data = assertIs<KametiDetailViewModel.State.Loaded>(model.state.value).data
        assertFalse(data.isOwner)
        assertEquals(listOf("m"), data.months.map { it.memberId })
    }

    @Test
    fun aFailureShowsAsFailedState() = runTest {
        val model = KametiDetailViewModel("k", "me", dependencies("me", StubLedgerRepository(failure = Failure.Network)))
        model.load()
        assertEquals(KametiDetailViewModel.State.Failed(Failure.Network), model.state.value)
    }
}

class DetailLogicPaymentsTest {
    private fun pay(id: String, day: Int, created: Long) = Payment(
        id = id, kametiId = "k", memberId = "a", amount = Money(1), receivedOn = DateOnly.make(2026, 11, day),
        method = PaymentMethod.Cash, createdAt = Instant.ofEpochSecond(created),
    )

    @Test
    fun paymentsAreNewestFirst() {
        val sorted = DetailLogic.newestFirst(listOf(pay("old", 1, 1), pay("newA", 5, 1), pay("newB", 5, 9)))
        assertEquals(listOf("newB", "newA", "old"), sorted.map { it.id })
    }

    @Test
    fun paymentSubtitleSkipsEmptyParts() {
        val full = pay("p", 1, 1).copy(method = PaymentMethod.BankTransfer, reference = "88213", paidByName = "Hassan")
        assertEquals("Bank · 88213 · paid by Hassan", DetailLogic.paymentSubtitle(full, "Bank") { "paid by $it" })
        assertEquals("Cash", DetailLogic.paymentSubtitle(pay("p", 1, 1).copy(reference = ""), "Cash") { it })
    }

    @Test
    fun aDateFallsInItsKametiMonth() {
        val k = kameti("o")
        assertEquals(1, DetailLogic.monthIndex(DateOnly.make(2026, 11, 30), k))
        assertEquals(2, DetailLogic.monthIndex(DateOnly.make(2026, 12, 1), k))
        assertNull(DetailLogic.monthIndex(DateOnly.make(2027, 1, 1), k))
        assertNull(DetailLogic.monthIndex(DateOnly.make(2026, 10, 31), k))
    }
}

/** A kameti whose months are all over shows totals, not "Not started yet". */
class FinishedOverviewTest {
    @Test
    fun finishedKametiHasASummary() = runTest {
        val model = KametiDetailViewModel("past-2025", SampleData.USER_ID, SampleData.dependencies())
        model.load()
        val data = assertIs<KametiDetailViewModel.State.Loaded>(model.state.value).data
        assertNull(data.current)
        val summary = assertNotNull(DetailLogic.finalSummary(data))
        assertEquals(data.kameti.monthsN, summary.months)
        assertTrue(summary.collected.isPositive)
    }

    @Test
    fun runningKametiHasNone() = runTest {
        val model = KametiDetailViewModel("family", SampleData.USER_ID, SampleData.dependencies())
        model.load()
        val data = assertIs<KametiDetailViewModel.State.Loaded>(model.state.value).data
        assertNull(DetailLogic.finalSummary(data))
    }
}
