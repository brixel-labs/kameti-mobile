package com.brixel.kameti.feature.createkameti

import com.brixel.kameti.core.Money

/**
 * The state of the slot split editor: who is in the slot and what each pays.
 * Every person starts at Rs 0 and the owner picks each amount from options
 * that fit in what is left, so the slot can never go over. Nothing is adjusted
 * on add, remove or when an amount changes; [remaining] shows what is left and
 * the slot can only be saved once it adds up. Pure logic, so the rules can be
 * tested without a screen. Every change returns a new value.
 */
data class SlotSplit(val total: Money, val lines: List<Line> = emptyList()) {
    /** One person in the slot; [id] is the member id. */
    data class Line(val id: String, val amount: Money)

    val assigned: Money get() = lines.fold(Money.ZERO) { sum, line -> sum + line.amount }
    val remaining: Money get() = total - assigned
    val isFull: Boolean get() = lines.size >= MAX_PEOPLE
    val isValid: Boolean get() = PlanChecks.isValidSplit(lines.map { it.amount }, total)
    fun amountOf(id: String): Money? = lines.firstOrNull { it.id == id }?.amount

    /** Someone still at less than Rs 1,000 (a newly added person). */
    val hasUnset: Boolean get() = lines.any { it.amount.rupees < UNIT }

    /**
     * Someone can be added while part of the slot is unassigned and everyone
     * already in has an amount.
     */
    val canAdd: Boolean get() = !isFull && !hasUnset && (lines.isEmpty() || remaining.isPositive)

    /** A new person starts at Rs 0; the owner picks their amount. Nobody else changes. */
    fun add(id: String): SlotSplit =
        if (isFull || lines.any { it.id == id }) this else copy(lines = lines + Line(id, Money.ZERO))

    /** Nobody else is changed: what was theirs becomes "left to assign". */
    fun remove(id: String): SlotSplit = copy(lines = lines.filterNot { it.id == id })

    /** Even split in Rs 1,000 steps; the first person takes any remainder. */
    fun splitEvenly(): SlotSplit {
        if (lines.size == 1) return copy(lines = listOf(lines[0].copy(amount = total)))
        val even = PlanChecks.evenSplit(total, lines.size) ?: return this
        return copy(lines = lines.mapIndexed { index, line -> line.copy(amount = even[index]) })
    }

    /** The most this person can take: the slot minus what the others have. */
    fun ceiling(id: String): Long {
        val others = lines.filter { it.id != id }.sumOf { it.amount.rupees }
        return maxOf(total.rupees - others, UNIT)
    }

    /**
     * Sets one person's amount (Rs 1,000 steps, at least Rs 1,000, never more
     * than what is left for them). Nobody else changes, so the slot can't
     * go over.
     */
    fun set(id: String, amount: Money): SlotSplit {
        if (lines.none { it.id == id }) return this
        val value = (amount.rupees / UNIT * UNIT).coerceAtLeast(UNIT).coerceAtMost(ceiling(id))
        return copy(lines = lines.map { if (it.id == id) it.copy(amount = Money(value)) else it })
    }

    fun nudge(id: String, direction: Int): SlotSplit {
        val current = amountOf(id) ?: return this
        return set(id, Money(current.rupees + direction * step(total)))
    }

    /**
     * Amounts the owner can pick for this person: a ladder scaled to the slot
     * (25K, 50K, 1L ... up to a few lakh), only those that fit in what is left
     * for them, plus the exact amount left so the slot can be completed.
     */
    fun options(id: String): List<Money> {
        val available = ceiling(id)
        val values = LADDER.filter { it <= available && it <= total.rupees }.toMutableList()
        if (available % UNIT == 0L && available >= UNIT && available !in values) values += available
        return values.sorted().map(::Money)
    }

    companion object {
        const val MAX_PEOPLE = 3
        const val UNIT = 1_000L
        private val LADDER = listOf<Long>(
            25_000, 50_000, 100_000, 150_000, 200_000, 250_000, 300_000, 400_000, 500_000, 750_000, 1_000_000,
        )

        /** The size of a - or + tap, scaled to the slot amount. */
        fun step(total: Money): Long = when {
            total.rupees >= 200_000 -> 25_000
            total.rupees >= 50_000 -> 5_000
            else -> UNIT
        }
    }
}
