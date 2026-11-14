package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.BatchPaymentItem
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberMonthRow

/**
 * What recording an amount does for a member this month (shown under the
 * amount field before the owner confirms).
 */
sealed interface PaymentOutcome {
    data object None : PaymentOutcome

    /** The member will be fully paid for the month. */
    data object FullyPaid : PaymentOutcome

    /** Still owed for the month after this payment. */
    data class StillOwes(val amount: Money) : PaymentOutcome

    /** More than the month needs; the extra covers later months. */
    data class Credit(val amount: Money) : PaymentOutcome
}

object PaymentLogic {
    /** The member's row for the current month (what they owe and have paid). */
    fun monthRow(memberId: String, data: KametiDetailData): MemberMonthRow? {
        val month = data.current?.monthIndex ?: return null
        return data.months.firstOrNull { it.memberId == memberId && it.monthIndex == month }
    }

    fun outcome(amount: Money, row: MemberMonthRow?): PaymentOutcome {
        if (!amount.isPositive || row == null) return PaymentOutcome.None
        val remaining = row.remaining
        return when {
            amount == remaining -> PaymentOutcome.FullyPaid
            amount < remaining -> PaymentOutcome.StillOwes(remaining - amount)
            else -> PaymentOutcome.Credit(amount - remaining)
        }
    }

    /** Members the owner can record a payment for: those with a due this month. */
    fun payers(data: KametiDetailData): List<Member> {
        val month = data.current?.monthIndex
        val ids = data.months.filter { it.monthIndex == month }.map { it.memberId }.toSet()
        return data.members.filter { it.id in ids }
    }
}

/**
 * Tap-to-settle (board A v2 · Record many, option 3): the owner marks who paid
 * what for a month, then saves them together. Tapping a person marks what
 * they still owe; the amount can be edited; nothing is saved until the end.
 * Each change returns a new session.
 */
data class CollectSession(val lines: List<Line>, val marked: Map<String, Money> = emptyMap()) {
    data class Line(
        val memberId: String,
        /** What the member still owes this month. */
        val remaining: Money,
    )

    sealed interface RowState {
        data object Unmarked : RowState

        /** Marked for at least what they owe. */
        data class Settled(val amount: Money) : RowState

        /** Marked for less; this much would still be owed. */
        data class Partial(val amount: Money, val stillOwes: Money) : RowState
    }

    val total: Money get() = marked.values.fold(Money.ZERO) { sum, amount -> sum + amount }
    val count: Int get() = marked.size
    val allMarked: Boolean get() = lines.isNotEmpty() && lines.all { it.memberId in marked }

    fun state(id: String): RowState {
        val amount = marked[id] ?: return RowState.Unmarked
        val line = lines.firstOrNull { it.memberId == id } ?: return RowState.Unmarked
        return if (amount >= line.remaining) RowState.Settled(amount) else RowState.Partial(amount, line.remaining - amount)
    }

    /** Tap: marks what they owe, or undoes a mark. */
    fun toggle(id: String): CollectSession {
        if (id in marked) return copy(marked = marked - id)
        val line = lines.firstOrNull { it.memberId == id } ?: return this
        return copy(marked = marked + (id to line.remaining))
    }

    /** Edit: a custom amount (zero or less clears the mark). */
    fun set(id: String, amount: Money): CollectSession {
        if (lines.none { it.memberId == id }) return this
        return copy(marked = if (amount.isPositive) marked + (id to amount) else marked - id)
    }

    /** "Mark all paid": everyone who owes, for what they owe; a second tap clears. */
    fun markAll(): CollectSession =
        if (allMarked) copy(marked = emptyMap()) else copy(marked = lines.associate { it.memberId to it.remaining })

    /** The payments to save, one per marked member, in list order. */
    fun items(keys: Map<String, String>): List<BatchPaymentItem> = lines.mapNotNull { line ->
        marked[line.memberId]?.let { BatchPaymentItem(line.memberId, it, keys[line.memberId] ?: line.memberId) }
    }

    companion object {
        /** The members who still owe for the current month, in member order. */
        fun of(data: KametiDetailData): CollectSession {
            val monthIndex = data.current?.monthIndex
            val order = data.members.withIndex().associate { it.value.id to it.index }
            return CollectSession(
                data.months
                    .filter { it.monthIndex == monthIndex && it.remaining.isPositive }
                    .sortedBy { order[it.memberId] ?: 0 }
                    .map { Line(it.memberId, it.remaining) },
            )
        }
    }
}
