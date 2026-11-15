package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.Payout
import com.brixel.kameti.domain.ReminderResult
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.testsupport.SampleData
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

// Twin of CollectSessionTests.swift

private fun session() = CollectSession(
    listOf(
        CollectSession.Line("a", Money(450_000)),
        CollectSession.Line("b", Money(125_000)),
        CollectSession.Line("c", Money(50_000)),
    ),
)

class CollectSessionTest {
    @Test
    fun tapMarksWhatTheyOweAndTapAgainUndoes() {
        var s = session().toggle("a")
        assertEquals(CollectSession.RowState.Settled(Money(450_000)), s.state("a"))
        assertEquals(Money(450_000), s.total)
        assertEquals(1, s.count)
        s = s.toggle("a")
        assertEquals(CollectSession.RowState.Unmarked, s.state("a"))
        assertTrue(s.total.isZero)
        assertEquals(0, s.count)
    }

    @Test
    fun editingLessLeavesThemOwingTheRest() {
        var s = session().set("a", Money(200_000))
        assertEquals(CollectSession.RowState.Partial(Money(200_000), stillOwes = Money(250_000)), s.state("a"))
        s = s.set("a", Money(450_000))
        assertEquals(CollectSession.RowState.Settled(Money(450_000)), s.state("a"))
        s = s.set("a", Money(500_000))
        assertEquals(CollectSession.RowState.Settled(Money(500_000)), s.state("a"))
        s = s.set("a", Money.ZERO)
        assertEquals(CollectSession.RowState.Unmarked, s.state("a"))
    }

    @Test
    fun markAllThenClearAll() {
        var s = session().toggle("b").markAll()
        assertTrue(s.allMarked)
        assertEquals(3, s.count)
        assertEquals(Money(625_000), s.total)
        s = s.markAll()
        assertEquals(0, s.count)
    }

    @Test
    fun itemsFollowTheListAndUseOneKeyPerMember() {
        val s = session().set("c", Money(50_000)).toggle("a")
        val items = s.items(mapOf("a" to "ka", "c" to "kc"))
        assertEquals(listOf("a", "c"), items.map { it.memberId })
        assertEquals(listOf("ka", "kc"), items.map { it.idempotencyKey })
        assertEquals(listOf(Money(450_000), Money(50_000)), items.map { it.amount })
    }

    @Test
    fun peopleNotInTheListCannotBeMarked() {
        val s = session().toggle("zzz").set("zzz", Money(1_000))
        assertEquals(0, s.count)
    }
}

// Twin of PaymentLogicTests.swift

private fun monthRow(due: Long, allocated: Long) = MemberMonthRow(
    kametiId = "k", memberId = "m", monthIndex = 2, monthStart = DateOnly.make(2026, 11), isCurrent = true,
    due = Money(due), allocated = Money(allocated), remaining = Money(due - allocated), status = MonthStatusCode.Partial,
)

class PaymentLogicTest {
    @Test
    fun outcomeForTheAmountEntered() {
        val partial = monthRow(due = 1_000_000, allocated = 550_000) // 4,50,000 left
        assertEquals(PaymentOutcome.FullyPaid, PaymentLogic.outcome(Money(450_000), partial))
        assertEquals(PaymentOutcome.StillOwes(Money(250_000)), PaymentLogic.outcome(Money(200_000), partial))
        assertEquals(PaymentOutcome.Credit(Money(50_000)), PaymentLogic.outcome(Money(500_000), partial))
        assertEquals(PaymentOutcome.None, PaymentLogic.outcome(Money.ZERO, partial))
        assertEquals(PaymentOutcome.None, PaymentLogic.outcome(Money(1_000), null))
    }

    @Test
    fun aMemberAlreadyPaidUpGetsCreditForAnyPayment() {
        assertEquals(
            PaymentOutcome.Credit(Money(10_000)),
            PaymentLogic.outcome(Money(10_000), monthRow(due = 100_000, allocated = 100_000)),
        )
    }
}

// Twin of PayoutLogicTests.swift

private val kameti = Kameti(
    id = "k", ownerId = "o", name = "K", startMonth = DateOnly.make(2026, 11), monthsN = 4,
    slotAmountC = Money(100_000), dueDay = 10, reminderDays = emptyList(), maxSlotsPerMember = 4,
    status = KametiStatus.Active,
)
private val members = listOf("a", "b", "c").map { Member(id = it, kametiId = "k", name = it.uppercase(), joinStatus = JoinStatus.Joined) }
private val slots = listOf(Slot("s1", "k", 1), Slot("s2", "k", 2))

private fun share(slot: String, member: String, amount: Long) =
    Share(id = slot + member, kametiId = "k", slotId = slot, memberId = member, monthlyAmount = Money(amount), effectiveFromMonth = 1)

private fun balance(member: String, owes: Long) = MemberBalanceRow(
    kametiId = "k", memberId = member, currentMonthIndex = 1, monthlyDue = Money(1), dueToDate = Money(1),
    totalPaid = Money.ZERO, balance = Money(owes), owes = Money(owes), credit = Money.ZERO,
)

class PayoutLogicTest {
    private fun recipients(
        shortfall: Long,
        balances: List<MemberBalanceRow> = emptyList(),
        payouts: List<Payout> = emptyList(),
    ) = PayoutLogic.recipients(
        kameti, month = 1, members = members, slots = slots,
        shares = listOf(share("s1", "a", 60_000), share("s1", "b", 40_000), share("s2", "c", 100_000)),
        payouts = payouts, balances = balances, shortfall = Money(shortfall),
    )

    @Test
    fun recipientsAreTheSlotsSharersWithShareTimesN() {
        val result = recipients(shortfall = 0)
        assertEquals(listOf("a", "b"), result.map { it.id })
        assertEquals(listOf(Money(240_000), Money(160_000)), result.map { it.expected })
        assertEquals(listOf(Money(240_000), Money(160_000)), result.map { it.suggested })
    }

    @Test
    fun theShortfallIsSplitByShareAndAddsUpExactly() {
        val result = recipients(shortfall = 30_001)
        assertEquals(listOf(Money(18_000), Money(12_001)), result.map { it.shortfallShare })
        assertEquals(30_001, result.sumOf { it.shortfallShare.rupees })
        assertEquals(Money(222_000), result[0].suggested)
    }

    @Test
    fun earlierPartsReduceWhatIsOutstanding() {
        val day = DateOnly.make(2026, 11, 5)
        val part = Payout("p", "k", "s1", "a", Money(100_000), day, PaymentMethod.Cash)
        val voided = Payout(
            "v", "k", "s1", "a", Money(50_000), day, PaymentMethod.Cash, voidedAt = Instant.EPOCH, voidReason = "x",
        )
        val result = recipients(shortfall = 0, payouts = listOf(part, voided))
        assertEquals(Money(100_000), result[0].alreadyPaid)
        assertEquals(Money(140_000), result[0].outstanding)
    }

    @Test
    fun aSlotWithNoPayoutMonthHasNoRecipients() {
        val none = PayoutLogic.recipients(kameti, 3, members, slots, emptyList(), emptyList(), emptyList(), Money.ZERO)
        assertTrue(none.isEmpty())
    }

    @Test
    fun deductingDuesMovesThemFromThePayoutToAPayment() {
        var draft = PayoutDraft(recipients(shortfall = 0, balances = listOf(balance("a", owes = 100_000))))
        assertFalse(draft.needsNote)
        draft = draft.setDeduction("a", true)
        assertEquals(Money(100_000), draft.deduction("a"))
        assertEquals(Money(140_000), draft.amount("a"))
        assertFalse(draft.differs("a")) // payout + deduction still equals what is expected
        draft = draft.setDeduction("a", false)
        assertNull(draft.deduction("a"))
        assertEquals(Money(240_000), draft.amount("a"))
    }

    @Test
    fun aDeductionIsCappedAtThePayout() {
        val draft = PayoutDraft(recipients(shortfall = 0, balances = listOf(balance("b", owes = 999_999)))).setDeduction("b", true)
        assertEquals(Money(160_000), draft.deduction("b"))
        assertEquals(Money.ZERO, draft.amount("b"))
    }

    @Test
    fun changingAnAmountNeedsANote() {
        var draft = PayoutDraft(recipients(shortfall = 0))
        assertFalse(draft.needsNote)
        draft = draft.set("a", Money(200_000))
        assertTrue(draft.differs("a") && draft.needsNote)
        assertEquals(Money(360_000), draft.total)
        draft = draft.set("a", Money(-5))
        assertEquals(Money.ZERO, draft.amount("a"))
    }
}

// Twin of ReminderTests in ArchiveKametiTests.swift: the owner's reminder (FR-82)
// and WhatsApp for members without the app (FR-84).

class ReminderTest {
    @Test
    fun whatsAppLinksUsePakistaniNumbers() {
        assertEquals("https://wa.me/923001234567?text=Hi", ReminderLogic.whatsAppUrl("0300 1234567", "Hi"))
        assertEquals(true, ReminderLogic.whatsAppUrl("+92 300 1234567", "Hi")?.startsWith("https://wa.me/923001234567"))
        assertNull(ReminderLogic.whatsAppUrl(null, "Hi"))
        assertNull(ReminderLogic.whatsAppUrl("123", "Hi"))
    }

    @Test
    fun theMessageSaysWhatAndWhen() {
        val template = "Assalam O Alaikum %1\$s, a reminder that %2\$s for %3\$s is due by the %4\$s. Thank you!"
        val text = ReminderLogic.text(template, "Hira Malik", Money(125_000), "Family kameti", 10)
        assertEquals("Assalam O Alaikum Hira, a reminder that Rs 1,25,000 for Family kameti is due by the 10th. Thank you!", text)
        assertEquals("1st", ReminderLogic.ordinal(1))
        assertEquals("22nd", ReminderLogic.ordinal(22))
        assertEquals("13th", ReminderLogic.ordinal(13))
    }

    @Test
    fun oncePerMemberPerDay() = runTest {
        val dependencies = SampleData.dependencies()
        val first = dependencies.notifications.sendReminder("family", null, listOf("f4"))
        assertEquals(ReminderResult(sent = 1), first)
        val targets = dependencies.notifications.reminderTargets("family")
        assertEquals(true, targets.members.firstOrNull { it.memberId == "f4" }?.remindedToday)
        val everyone = dependencies.notifications.sendReminder("family", null, null)
        assertEquals(ReminderResult(sent = 1, skipped = listOf("Omar Farooq")), everyone)
        val failure = assertFailsWith<Failure> { dependencies.notifications.sendReminder("family", null, null) }
        assertEquals(Failure.Server("already_reminded_today"), failure)
    }
}

// Android only: the view model's write actions reload what is on screen.

class RecordingActionsTest {
    @Test
    fun recordingAPaymentReloadsAndVoidingStrikesIt() = runTest {
        val model = KametiDetailViewModel("family", SampleData.USER_ID, SampleData.dependencies())
        model.load()
        val before = assertIs<KametiDetailViewModel.State.Loaded>(model.state.value).data
        val payer = PaymentLogic.payers(before).first()

        val failure = model.recordPayment(
            payer.id, Money(1_000), before.today, PaymentMethod.Cash, reference = null, note = null,
            idempotencyKey = model.idempotencyKey(),
        )
        assertNull(failure)
        val after = assertIs<KametiDetailViewModel.State.Loaded>(model.state.value).data
        assertEquals(before.payments.size + 1, after.payments.size)

        val added = after.payments.first { payment -> before.payments.none { it.id == payment.id } }
        assertNull(model.voidPayment(added.id, "Entered by mistake"))
        val voided = assertIs<KametiDetailViewModel.State.Loaded>(model.state.value).data
        assertTrue(voided.payments.first { it.id == added.id }.voidedAt != null)
    }
}
