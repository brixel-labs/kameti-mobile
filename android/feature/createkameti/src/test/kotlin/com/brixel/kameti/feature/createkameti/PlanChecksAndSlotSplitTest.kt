package com.brixel.kameti.feature.createkameti

import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

private fun member(id: String) = Member(id, "k", id, JoinStatus.Joined)
private fun slot(month: Int) = Slot("s$month", "k", month)
private fun share(slot: Int, member: String, amount: Long) =
    Share("$slot$member", "k", "s$slot", member, Money(amount), effectiveFromMonth = 1)

private fun List<Money>.rupees() = map { it.rupees }
private fun SlotSplit.amounts() = lines.map { it.amount }

class PlanChecksTest {
    @Test
    fun splitMustSumToTheSlotAndUseThousands() {
        val c = Money(100_000)
        assertTrue(PlanChecks.isValidSplit(listOf(Money(100_000)), c))
        assertTrue(PlanChecks.isValidSplit(listOf(Money(60_000), Money(40_000)), c))
        assertFalse(PlanChecks.isValidSplit(listOf(Money(60_000), Money(30_000)), c))
        assertFalse(PlanChecks.isValidSplit(listOf(Money(99_500), Money(500)), c))
        assertFalse(PlanChecks.isValidSplit(emptyList(), c))
        assertFalse(PlanChecks.isValidSplit(List(5) { Money(20_000) }, c))
    }

    @Test
    fun emptyBadAndOverLimitSlotsAreFound() {
        val members = listOf(member("a"), member("b"), member("c"))
        val slots = listOf(slot(1), slot(2), slot(3))
        val shares = listOf(share(1, "a", 100_000), share(2, "a", 60_000)) // slot 2 short, slot 3 empty
        val result = PlanChecks.evaluate(Money(100_000), maxSlotsPerMember = 1, members, slots, shares)
        assertEquals(listOf(3), result.emptySlots)
        assertEquals(listOf(2), result.badSlots)
        assertEquals(listOf("a"), result.overLimit.map { it.id })
        assertEquals(listOf("b", "c"), result.unassigned.map { it.id })
        assertFalse(result.passes)
    }

    @Test
    fun aCompleteValidPlanPasses() {
        val result = PlanChecks.evaluate(
            Money(100_000), maxSlotsPerMember = 4, listOf(member("a"), member("b")),
            listOf(slot(1), slot(2)), listOf(share(1, "a", 100_000), share(2, "b", 100_000)),
        )
        assertTrue(result.passes)
        assertTrue(result.unassigned.isEmpty())
    }

    @Test
    fun removedSharesDoNotCount() {
        val ended = Share("x", "k", "s1", "a", Money(100_000), effectiveFromMonth = 1, effectiveToMonth = 2)
        val result = PlanChecks.evaluate(Money(100_000), 4, listOf(member("a")), listOf(slot(1)), listOf(ended))
        assertEquals(listOf(1), result.emptySlots)
    }

    @Test
    fun evenSplitUsesThousandsAndGivesTheRemainderToTheFirst() {
        assertEquals(listOf(Money(50_000), Money(50_000)), PlanChecks.evenSplit(Money(100_000), 2))
        assertEquals(listOf(Money(34_000), Money(33_000), Money(33_000)), PlanChecks.evenSplit(Money(100_000), 3))
        assertNull(PlanChecks.evenSplit(Money(2_000), 3))
        assertNull(PlanChecks.evenSplit(Money(100_000), 5))
        assertNull(PlanChecks.evenSplit(Money(100_500), 2))
    }

    @Test
    fun remainingCanGoNegative() {
        assertEquals(Money(40_000), PlanChecks.remaining(listOf(Money(60_000)), Money(100_000)))
        assertEquals(Money(-20_000), PlanChecks.remaining(listOf(Money(70_000), Money(50_000)), Money(100_000)))
    }
}

class SlotSplitTest {
    private val total = Money(200_000)

    @Test
    fun everyoneStartsAtZeroAndNothingIsAdjustedOnAdd() {
        var split = SlotSplit(total).add("a")
        assertEquals(listOf(Money.ZERO), split.amounts())
        assertTrue(split.hasUnset && !split.isValid && !split.canAdd)
        split = split.set("a", Money(100_000)).add("b")
        assertEquals(listOf(Money(100_000), Money.ZERO), split.amounts())
    }

    @Test
    fun choosingTheWholeSlotCompletesItAndHidesAdding() {
        val split = SlotSplit(total).add("a").set("a", total)
        assertTrue(split.isValid)
        assertFalse(split.canAdd)
        assertTrue(split.remaining.isZero)
    }

    @Test
    fun aPartialAmountLeavesRoomToAddSomeoneWithOnlyWhatFits() {
        var split = SlotSplit(total).add("a").set("a", Money(100_000))
        assertTrue(split.canAdd)
        split = split.add("b")
        assertEquals(listOf<Long>(25_000, 50_000, 100_000), split.options("b").rupees())
        assertEquals(listOf<Long>(25_000, 50_000, 100_000, 150_000, 200_000), split.options("a").rupees())
    }

    @Test
    fun nothingCanGoOver() {
        var split = SlotSplit(total).add("a").set("a", Money(150_000)).add("b").set("b", Money(200_000))
        assertEquals(Money(50_000), split.amountOf("b"))
        assertEquals(total, split.assigned)
        split = split.nudge("b", 1)
        assertEquals(total, split.assigned)
        split = split.set("a", Money(9_000_000))
        assertEquals(Money(150_000), split.amountOf("a"))
    }

    @Test
    fun optionsScaleWithTheSlotAmount() {
        var big = SlotSplit(Money(500_000)).add("a")
        assertEquals(
            listOf<Long>(25_000, 50_000, 100_000, 150_000, 200_000, 250_000, 300_000, 400_000, 500_000),
            big.options("a").rupees(),
        )
        big = big.set("a", Money(300_000)).add("b")
        assertEquals(listOf<Long>(25_000, 50_000, 100_000, 150_000, 200_000), big.options("b").rupees())
        val small = SlotSplit(Money(75_000)).add("a")
        assertEquals(listOf<Long>(25_000, 50_000, 75_000), small.options("a").rupees())
    }

    @Test
    fun atMostThreePeople() {
        var split = SlotSplit(Money(300_000))
            .add("a").set("a", Money(100_000))
            .add("b").set("b", Money(100_000))
            .add("c").set("c", Money(50_000))
            .add("d")
        assertEquals(3, split.lines.size)
        assertTrue(split.isFull && !split.canAdd)
        assertFalse(split.isValid)
        assertEquals(Money(50_000), split.remaining)
        split = split.add("a")
        assertEquals(3, split.lines.size)
    }

    @Test
    fun removingChangesNobodyAndAddingIsPossibleAgain() {
        var split = SlotSplit(total).add("a").set("a", Money(100_000)).add("b").set("b", Money(100_000))
        assertTrue(split.isValid && !split.canAdd)
        split = split.remove("b")
        assertEquals(listOf(Money(100_000)), split.amounts())
        assertEquals(Money(100_000), split.remaining)
        assertTrue(split.canAdd)
    }

    @Test
    fun amountsStayInThousandsAndAtLeastOneThousand() {
        val split = SlotSplit(total).add("a")
        assertEquals(Money(12_000), split.set("a", Money(12_345)).amountOf("a"))
        assertEquals(Money(1_000), split.set("a", Money(0)).amountOf("a"))
    }

    @Test
    fun nudgeStepsByTheSlotScaledUnit() {
        val split = SlotSplit(total).add("a").set("a", Money(100_000)).nudge("a", -1)
        assertEquals(Money(75_000), split.amountOf("a"))
        assertEquals(5_000L, SlotSplit.step(Money(100_000)))
        assertEquals(1_000L, SlotSplit.step(Money(20_000)))
    }

    @Test
    fun splitEvenlyGivesTheFirstPersonTheRemainder() {
        val split = SlotSplit(Money(100_000))
            .add("a").set("a", Money(1_000)).add("b").set("b", Money(1_000)).add("c")
            .splitEvenly()
        assertEquals(listOf(Money(34_000), Money(33_000), Money(33_000)), split.amounts())
        assertTrue(split.isValid)
    }
}
