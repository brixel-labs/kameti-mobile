package com.brixel.kameti.feature.createkameti

import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot

/**
 * The pre-start checks of FR-12, shown on the review step. The server
 * re-checks on start (`kameti_not_ready`); these let the owner fix things first.
 */
data class PlanChecks(
    /** Slots (by payout month) with no shares. */
    val emptySlots: List<Int> = emptyList(),
    /** Slots whose shares don't add up to C, or break the Rs 1,000 / 4-sharer rules. */
    val badSlots: List<Int> = emptyList(),
    /** Members above the per-member slot limit. */
    val overLimit: List<Member> = emptyList(),
    /** Members with no share in any slot. */
    val unassigned: List<Member> = emptyList(),
) {
    val slotsFilled: Boolean get() = emptySlots.isEmpty()
    val slotsAddUp: Boolean get() = badSlots.isEmpty()
    val withinLimit: Boolean get() = overLimit.isEmpty()
    val passes: Boolean get() = slotsFilled && slotsAddUp && withinLimit

    companion object {
        private const val UNIT = 1_000L

        /** Active shares of a slot, in the order they were added. */
        fun activeShares(slotId: String, shares: List<Share>): List<Share> =
            shares.filter { it.slotId == slotId && it.effectiveToMonth == null }

        /**
         * Whether one slot's shares are valid: they sum to [slotAmount], each is
         * at least Rs 1,000 and a multiple of Rs 1,000, at most 4 people.
         */
        fun isValidSplit(amounts: List<Money>, slotAmount: Money): Boolean {
            if (amounts.isEmpty() || amounts.size > 4) return false
            val total = amounts.fold(Money.ZERO) { sum, amount -> sum + amount }
            return total == slotAmount && amounts.all { it.rupees >= UNIT && it.rupees % UNIT == 0L }
        }

        fun evaluate(
            slotAmount: Money,
            maxSlotsPerMember: Int,
            members: List<Member>,
            slots: List<Slot>,
            shares: List<Share>,
        ): PlanChecks {
            val empty = mutableListOf<Int>()
            val bad = mutableListOf<Int>()
            val slotCount = mutableMapOf<String, Int>()
            for (slot in slots.sortedBy { it.payoutMonthIndex }) {
                val active = activeShares(slot.id, shares)
                if (active.isEmpty()) {
                    empty += slot.payoutMonthIndex
                    continue
                }
                if (!isValidSplit(active.map { it.monthlyAmount }, slotAmount)) bad += slot.payoutMonthIndex
                for (memberId in active.map { it.memberId }.toSet()) slotCount[memberId] = (slotCount[memberId] ?: 0) + 1
            }
            return PlanChecks(
                emptySlots = empty,
                badSlots = bad,
                overLimit = members.filter { (slotCount[it.id] ?: 0) > maxSlotsPerMember },
                unassigned = members.filter { (slotCount[it.id] ?: 0) == 0 },
            )
        }

        /** What one slot still needs to reach [slotAmount] (negative when over). */
        fun remaining(amounts: List<Money>, slotAmount: Money): Money =
            slotAmount - amounts.fold(Money.ZERO) { sum, amount -> sum + amount }

        /**
         * Splits [slotAmount] evenly in Rs 1,000 steps between [count] people;
         * the first person takes any remainder. `null` when it can't be done.
         */
        fun evenSplit(slotAmount: Money, count: Int): List<Money>? {
            if (count < 1 || count > 4 || slotAmount.rupees % UNIT != 0L) return null
            val steps = slotAmount.rupees / UNIT
            if (steps < count) return null
            val base = steps / count
            val extra = steps % count
            return (0 until count).map { Money((base + if (it < extra) 1 else 0) * UNIT) }
        }
    }
}
