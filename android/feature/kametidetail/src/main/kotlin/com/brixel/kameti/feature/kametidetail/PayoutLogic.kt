package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.Payout
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot

/** One person receiving (part of) a month's pot (FR-51 to FR-53). */
data class PayoutRecipient(
    val slotId: String,
    val member: Member,
    val colorIndex: Int,
    /** Their share of the slot per month. */
    val monthlyShare: Money,
    /** Share × N. */
    val expected: Money,
    /** Payouts already recorded for this slot (a payout can be made in parts). */
    val alreadyPaid: Money,
    /** Their part of the month's shortfall, split by share. */
    val shortfallShare: Money,
    /** What they owe in dues right now. */
    val owes: Money,
) {
    val id: String get() = member.id

    /** What is still expected after earlier parts. */
    val outstanding: Money get() = (expected - alreadyPaid).let { if (it.isNegative) Money.ZERO else it }

    /** Pre-filled amount: what is still expected, less their part of the shortfall, never below zero. */
    val suggested: Money get() = (outstanding - shortfallShare).let { if (it.isNegative) Money.ZERO else it }
}

object PayoutLogic {
    /**
     * The recipients of month [month]'s slot, in member order. The shortfall
     * is split by share: each takes `shortfall × share ÷ C` rounded down and
     * the last takes the remainder, so the parts add up exactly.
     */
    fun recipients(
        kameti: Kameti,
        month: Int,
        members: List<Member>,
        slots: List<Slot>,
        shares: List<Share>,
        payouts: List<Payout>,
        balances: List<MemberBalanceRow>,
        shortfall: Money,
    ): List<PayoutRecipient> {
        val slot = slots.firstOrNull { it.payoutMonthIndex == month } ?: return emptyList()
        val shareByMember = mutableMapOf<String, Long>()
        for (share in shares) {
            if (share.slotId != slot.id || !DetailLogic.isActive(share, month)) continue
            shareByMember[share.memberId] = (shareByMember[share.memberId] ?: 0) + share.monthlyAmount.rupees
        }
        val ordered = members.withIndex().filter { it.value.id in shareByMember }
        val c = kameti.slotAmountC.rupees
        val short = if (shortfall.isPositive) shortfall.rupees else 0
        var assigned = 0L
        return ordered.mapIndexed { position, (index, member) ->
            val share = shareByMember[member.id] ?: 0
            val isLast = position == ordered.size - 1
            val part = if (isLast) short - assigned else if (c == 0L) 0 else short * share / c
            assigned += part
            val paid = payouts
                .filter { it.voidedAt == null && it.slotId == slot.id && it.memberId == member.id }
                .fold(Money.ZERO) { sum, payout -> sum + payout.amount }
            PayoutRecipient(
                slotId = slot.id, member = member, colorIndex = index, monthlyShare = Money(share),
                expected = Money(share * kameti.monthsN), alreadyPaid = paid, shortfallShare = Money(part),
                owes = balances.firstOrNull { it.memberId == member.id }?.owes ?: Money.ZERO,
            )
        }
    }
}

/** What the owner has entered on the payout screen. Each change returns a new draft. */
data class PayoutDraft(
    val recipients: List<PayoutRecipient>,
    val amounts: Map<String, Money> = recipients.associate { it.id to it.suggested },
    /** Dues taken from a payout (recorded as a payment, with a reduced payout). */
    val deductions: Map<String, Money> = emptyMap(),
) {
    fun amount(id: String): Money = amounts[id] ?: Money.ZERO
    fun deduction(id: String): Money? = deductions[id]

    val total: Money get() = amounts.values.fold(Money.ZERO) { sum, amount -> sum + amount }
    val hasAnything: Boolean get() = total.isPositive || deductions.isNotEmpty()

    fun set(id: String, amount: Money): PayoutDraft =
        copy(amounts = amounts + (id to if (amount.isNegative) Money.ZERO else amount))

    /**
     * "Ali owes Rs 1,00,000. Take it from his payout?": moves what they owe
     * (at most the payout) from the payout to a recorded payment.
     */
    fun setDeduction(id: String, on: Boolean): PayoutDraft {
        val recipient = recipients.firstOrNull { it.id == id } ?: return this
        val amount = amount(id)
        if (on) {
            val take = minOf(recipient.owes, amount)
            if (!take.isPositive) return this
            return copy(deductions = deductions + (id to take), amounts = amounts + (id to amount - take))
        }
        val take = deductions[id] ?: return this
        return copy(deductions = deductions - id, amounts = amounts + (id to amount + take))
    }

    /**
     * A payout (plus any deduction) that differs from what is still expected
     * needs a note saying why (E22).
     */
    fun differs(id: String): Boolean {
        val recipient = recipients.firstOrNull { it.id == id } ?: return false
        return amount(id) + (deductions[id] ?: Money.ZERO) != recipient.outstanding
    }

    val needsNote: Boolean get() = recipients.any { differs(it.id) }
}
