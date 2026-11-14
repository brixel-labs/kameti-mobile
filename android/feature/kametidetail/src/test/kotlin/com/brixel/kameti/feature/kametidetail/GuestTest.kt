package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.testsupport.SampleData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

private suspend fun loaded(id: String = "family") =
    KametiDetailViewModel(id, SampleData.USER_ID, SampleData.dependencies()).also { it.load() }

private val KametiDetailViewModel.data: KametiDetailData
    get() = assertIs<KametiDetailViewModel.State.Loaded>(state.value).data

/**
 * Twin of GuestTests.swift: members who don't use the app: marking them, who the Overview is still
 * waiting for, and the receipt and update texts sent to them by WhatsApp.
 */
class GuestTest {
    @Test
    fun setupProgressCountsWhoIsStillToJoin() = runTest {
        val model = loaded()
        val start = SetupProgress.of(model.data)
        assertEquals(6, start.expected)
        assertEquals(listOf("f5", "f6"), start.waiting.map { it.id })
        assertTrue(start.needsApproval) // Hira is waiting for the owner's approval
        assertFalse(start.isComplete)

        assertEquals(null, model.approveJoin("f5"))
        val approved = SetupProgress.of(model.data)
        assertEquals(listOf("f6"), approved.waiting.map { it.id })
        assertFalse(approved.needsApproval)
    }

    @Test
    fun aGuestIsNotWaitedFor() = runTest {
        val model = loaded()
        assertEquals(null, model.addMember(NewMember(name = "Zara Ahmed")))
        val zara = model.data.members.first { it.name == "Zara Ahmed" }
        assertTrue(SetupProgress.of(model.data).waiting.any { it.id == zara.id })
        assertEquals(7, SetupProgress.of(model.data).expected)

        assertEquals(null, model.setNoApp(zara.id, true))
        val marked = model.data
        assertEquals(AccessState.Guest(phone = null), AccessState.of(marked.members.first { it.id == zara.id }, marked))
        val progress = SetupProgress.of(marked)
        assertEquals(6, progress.expected)
        assertEquals(listOf("f5", "f6"), progress.waiting.map { it.id })
        // Invite all leaves them out.
        assertFalse(AccessState.invitable(marked).any { it.id == zara.id })

        assertEquals(null, model.setNoApp(zara.id, false))
        assertEquals(7, SetupProgress.of(model.data).expected)
    }

    @Test
    fun aMemberWithAnInviteCantBeAGuest() = runTest {
        val model = loaded()
        assertEquals(Failure.Server("member_already_invited"), model.setNoApp("f6", true)) // invited
        assertEquals(Failure.Server("member_already_invited"), model.setNoApp("f1", true)) // joined
    }

    @Test
    fun theOwnersOwnRowDoesNotCount() = runTest {
        val progress = SetupProgress.of(loaded("office").data)
        assertEquals(3, progress.expected)
        assertTrue(progress.isComplete)
    }

    @Test
    fun aReceiptIsOfferedOnlyToGuests() = runTest {
        val model = loaded()
        assertEquals(null, model.addMember(NewMember(name = "Zara Ahmed")))
        val zara = model.data.members.first { it.name == "Zara Ahmed" }
        assertEquals(null, model.setNoApp(zara.id, true))
        val day = DateOnly.make(2026, 11, 10)
        model.offerReceiptsNow(
            listOf(PendingReceipt("f1", Money(10_000), day), PendingReceipt(zara.id, Money(5_000), day)),
        )
        assertEquals(listOf(zara.id), model.pendingReceipts.value.map { it.memberId })
        model.clearReceipts()
        model.offerReceiptsNow(listOf(PendingReceipt("f1", Money(10_000), day)))
        assertTrue(model.pendingReceipts.value.isEmpty())
    }

    @Test
    fun theTextSaysOnlyWhatTheMemberOwesAndGets() = runTest {
        val current = loaded().data
        val osama = current.members.first { it.id == "f4" }
        val update = GuestUpdate.text(english, osama, current)
        assertTrue(update.startsWith("Hi Osama, here's your Family kameti update for November."), update)
        assertTrue("You owe Rs" in update)
        assertFalse("Naveed" in update) // nobody else's name or figures

        val day = DateOnly.make(2026, 11, 10)
        val receipt = GuestUpdate.text(english, osama, current, PendingReceipt("f4", Money(10_000), day))
        assertTrue(
            receipt.startsWith("Hi Osama, we received Rs 10,000 from you on ${DetailLogic.dayMonth(day)} for Family kameti."), receipt,
        )
        assertTrue("Your payout is in" in update) // Osama's turn

        // Whatever the balance says: owing, ahead or paid up.
        fun standing(owes: Long, credit: Long): String {
            val balance = MemberBalanceRow(
                kametiId = "family", memberId = "f2", currentMonthIndex = 2, monthlyDue = Money(250_000), dueToDate = Money(500_000),
                totalPaid = Money(500_000), balance = Money(owes - credit), owes = Money(owes), credit = Money(credit),
            )
            val changed = current.copy(balances = listOf(balance))
            return GuestUpdate.text(english, assertNotNull(current.members.firstOrNull { it.id == "f2" }), changed)
        }
        assertTrue("You're all paid up." in standing(0, 0))
        assertTrue("You're ahead by Rs 1,25,000." in standing(0, 125_000))
        assertTrue("You owe Rs 2,50,000 so far, due by the 10th." in standing(250_000, 0))
    }
}
