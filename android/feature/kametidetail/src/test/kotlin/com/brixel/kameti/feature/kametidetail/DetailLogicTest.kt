package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import java.util.Locale
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

private val kameti = Kameti(
    id = "k", ownerId = "o", name = "K", startMonth = DateOnly.make(2026, 11), monthsN = 4,
    slotAmountC = Money(100_000), dueDay = 10, reminderDays = emptyList(), maxSlotsPerMember = 4,
    status = KametiStatus.Active,
)

private fun member(id: String, profile: String? = null) =
    Member(id = id, kametiId = "k", name = id, joinStatus = JoinStatus.Joined, profileId = profile)

private fun share(id: String, slot: String, member: String, amount: Long, from: Int = 1, to: Int? = null) =
    Share(id, "k", slot, member, Money(amount), effectiveFromMonth = from, effectiveToMonth = to)

private fun row(month: Int, status: MonthStatusCode, member: String = "a") = MemberMonthRow(
    kametiId = "k", memberId = member, monthIndex = month, monthStart = DateOnly.make(2026, 10).plusMonths(month.toLong()),
    isCurrent = false, due = Money(1000), allocated = Money.ZERO, remaining = Money(1000), status = status,
)

class DetailLogicTest {
    @Test
    fun monthStartCrossesTheYear() {
        assertEquals(DateOnly.make(2026, 11), DetailLogic.monthStart(kameti, 1))
        assertEquals(DateOnly.make(2027, 1), DetailLogic.monthStart(kameti, 3))
    }

    @Test
    fun dueDateAndLabels() {
        assertEquals(DateOnly.make(2027, 1, 10), DetailLogic.dueDate(kameti, 3))
        assertEquals("10 Nov", DetailLogic.dayMonth(DateOnly.make(2026, 11, 10), Locale.UK))
        assertEquals("October 2026", DetailLogic.monthTitle(DateOnly.make(2026, 10), Locale.UK))
        assertEquals("October", DetailLogic.monthName(DateOnly.make(2026, 10), Locale.UK))
    }

    @Test
    fun shareActivityHonoursItsWindow() {
        val s = share("s", "x", "a", 1, from = 2, to = 3)
        assertFalse(DetailLogic.isActive(s, 1))
        assertTrue(DetailLogic.isActive(s, 2))
        assertTrue(DetailLogic.isActive(s, 3))
        assertFalse(DetailLogic.isActive(s, 4))
        assertTrue(DetailLogic.isActive(share("o", "x", "a", 1), 99))
    }

    @Test
    fun recipientsGetShareTimesNAndSplitSlotsShowEveryone() {
        val slots = listOf(Slot("s1", "k", 1), Slot("s2", "k", 2))
        val shares = listOf(
            share("a1", "s1", "a", 60_000),
            share("b1", "s1", "b", 40_000),
            share("a2", "s2", "a", 100_000),
        )
        val result = DetailLogic.recipients(kameti, 1, slots, shares, listOf(member("a"), member("b")))
        assertEquals(listOf("a", "b"), result.map { it.member.id })
        assertEquals(listOf(Money(240_000), Money(160_000)), result.map { it.payout })
        assertTrue(DetailLogic.recipients(kameti, 3, slots, shares, listOf(member("a"))).isEmpty())
    }

    @Test
    fun myMemberMatchesByProfile() {
        val list = listOf(member("a", "u1"), member("b", "u2"))
        assertEquals("b", DetailLogic.myMember(list, "u2")?.id)
        assertNull(DetailLogic.myMember(list, "zzz"))
        assertNull(DetailLogic.myMember(list, null))
    }

    @Test
    fun owingKeepsPartialUnpaidOverdueOfThatMonth() {
        val rows = listOf(
            row(1, MonthStatusCode.Paid), row(1, MonthStatusCode.Partial), row(1, MonthStatusCode.Unpaid),
            row(1, MonthStatusCode.Overdue), row(1, MonthStatusCode.Advance), row(2, MonthStatusCode.Unpaid),
        )
        assertEquals(
            listOf(MonthStatusCode.Partial, MonthStatusCode.Unpaid, MonthStatusCode.Overdue),
            DetailLogic.owing(rows, 1).map { it.status },
        )
    }

    @Test
    fun statusCountsGroupAdvanceWithPaidAndOverdueWithUnpaid() {
        val rows = listOf(
            row(1, MonthStatusCode.Paid), row(1, MonthStatusCode.Advance), row(1, MonthStatusCode.Partial),
            row(1, MonthStatusCode.Overdue), row(1, MonthStatusCode.Unpaid), row(1, MonthStatusCode.Upcoming),
            row(2, MonthStatusCode.Paid),
        )
        assertEquals(DetailLogic.StatusCounts(paid = 2, partial = 1, unpaid = 2), DetailLogic.statusCounts(rows, 1))
    }

    @Test
    fun nextTurnIsTheEarliestUpcomingShare() {
        val slots = listOf(Slot("s1", "k", 1), Slot("s3", "k", 3))
        val shares = listOf(share("1", "s1", "a", 100_000), share("3", "s3", "a", 50_000))
        val me = member("a")
        assertEquals(1, DetailLogic.nextTurn(me, kameti, 1, slots, shares)?.monthIndex)
        val next = DetailLogic.nextTurn(me, kameti, 2, slots, shares)
        assertEquals(3, next?.monthIndex)
        assertEquals(Money(200_000), next?.payout)
        assertNull(DetailLogic.nextTurn(me, kameti, 4, slots, shares))
    }
}
